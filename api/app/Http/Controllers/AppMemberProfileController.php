<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\AppResponses;
use App\Models\ClubMember;
use App\Models\MemberPhoto;
use App\Models\MemberProfile;
use App\Services\MemberPhotoLink;
use App\Services\NotificationPresenter;
use App\Services\ThreadAccess;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\File\UploadedFile;

/**
 * Member profile card: photo, bio and goals (Phase 6.5, D59-D63).
 * Contract: ../mobile/docs/api-contract.md, "Phase 6.5".
 *
 * The photo is a small JPEG kept in member_photos (so ordinary profile reads never
 * load it) and downloaded through a signed, versioned link that needs no auth header.
 */
class AppMemberProfileController extends Controller
{
    use AppResponses;

    const BIO_MAX = 300;
    const GOALS_MAX = 1000;
    const PHOTO_MAX_BYTES = 409600; // 400 KB
    const PHOTO_MIN_SIDE = 64;
    const PHOTO_MAX_SIDE = 1024;
    const CARD_WINDOW_DAYS = 90;
    const ROLES = ['leader', 'committee', 'admin'];

    // ---- shapes ----------------------------------------------------------------------

    private function profileOf($clubId, $memberId): ?MemberProfile
    {
        return MemberProfile::where('club_id', $clubId)->where('member_id', $memberId)->first();
    }

    /** The caller's own card: the same shape with nulls when nothing was ever saved. */
    private function card(?MemberProfile $profile, $clubId, $memberId): array
    {
        return [
            'bio' => $profile ? $profile->bio : null,
            'goals' => $profile ? $profile->goals : null,
            'goalsVisible' => $profile ? (bool) $profile->goals_visible : false,
            'photoPath' => $profile ? MemberPhotoLink::path($clubId, $memberId, $profile->photo_version) : null,
            'updatedAt' => $profile ? NotificationPresenter::time($profile->updated_at) : null,
        ];
    }

    private function cardResponse($clubId, $memberId)
    {
        return response()->json($this->card($this->profileOf($clubId, $memberId), $clubId, $memberId));
    }

    private function publicRoles($roles): array
    {
        return array_values(array_intersect(self::ROLES, is_array($roles) ? $roles : []));
    }

    private function photoInvalid(string $message)
    {
        return response()->json([
            'error' => 'validation_failed',
            'message' => $message,
            'errors' => ['photo' => [$message]],
        ], 422);
    }

    // ---- my card ---------------------------------------------------------------------

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/member-profile",
     *   summary="The caller's own profile card (bio, goals, goalsVisible, photoPath). Nulls when nothing was saved; a read never creates a row.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="{ bio, goals, goalsVisible, photoPath, updatedAt }"),
     * )
     */
    public function show(Request $request)
    {
        return $this->cardResponse($request->attributes->get('club')->id, $request->attributes->get('member')->id);
    }

    /**
     * @OA\Put(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/member-profile",
     *   summary="Save bio, goals and goalsVisible. Omitted keys are left alone; null or empty after trim clears a text field.",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       @OA\Property(property="bio", type="string", nullable=true, maxLength=300),
     *       @OA\Property(property="goals", type="string", nullable=true, maxLength=1000),
     *       @OA\Property(property="goalsVisible", type="boolean"),
     *     )
     *   ),
     *   @OA\Response(response=200, description="The card"),
     *   @OA\Response(response=422, description="validation_failed"),
     * )
     */
    public function update(Request $request)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');
        $input = $request->all();

        // Trim first so the length limits count what is stored; empty becomes null.
        foreach (['bio', 'goals'] as $key) {
            if (isset($input[$key]) && is_string($input[$key])) {
                $input[$key] = trim($input[$key]);

                if ($input[$key] === '') {
                    $input[$key] = null;
                }
            }
        }

        $validator = $this->makeValidator($input, [
            'bio' => 'nullable|string|max:' . self::BIO_MAX,
            'goals' => 'nullable|string|max:' . self::GOALS_MAX,
        ]);

        // Strictly a JSON boolean: "true", 1 and null are all rejected.
        $validator->after(function ($validator) use ($input) {
            if (array_key_exists('goalsVisible', $input) && !is_bool($input['goalsVisible'])) {
                $validator->errors()->add('goalsVisible', 'goalsVisible must be true or false.');
            }
        });

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $profile = $this->profileOf($club->id, $member->id)
            ?: new MemberProfile(['club_id' => $club->id, 'member_id' => $member->id]);

        foreach (['bio', 'goals'] as $key) {
            if (array_key_exists($key, $input)) {
                $profile->{$key} = $input[$key];
            }
        }

        if (array_key_exists('goalsVisible', $input)) {
            $profile->goals_visible = $input['goalsVisible'];
        }

        $profile->updated_at = Carbon::now();
        $profile->save();

        return $this->cardResponse($club->id, $member->id);
    }

    // ---- my photo --------------------------------------------------------------------

    /**
     * @OA\Put(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/member-profile/photo",
     *   summary="Replace the caller's photo. multipart/form-data, one file field 'photo': a JPEG up to 400 KB, 64-1024 px each side. Also accepted as POST (PHP only fills its file list for POST).",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\MediaType(
     *       mediaType="multipart/form-data",
     *       @OA\Schema(@OA\Property(property="photo", type="string", format="binary"))
     *     )
     *   ),
     *   @OA\Response(response=200, description="The card, with a new photoPath"),
     *   @OA\Response(response=422, description="validation_failed on photo (wrong type, too large, too small, too big, missing)"),
     * )
     */
    public function uploadPhoto(Request $request)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        [$bytes, $problem] = $this->uploadedBytes($request);

        if ($problem === null) {
            $problem = $this->photoProblem($bytes);
        }

        if ($problem !== null) {
            return $this->photoInvalid($problem);
        }

        $now = Carbon::now();

        DB::transaction(function () use ($club, $member, $bytes, $now) {
            $profile = $this->profileOf($club->id, $member->id)
                ?: new MemberProfile(['club_id' => $club->id, 'member_id' => $member->id]);

            do {
                $version = bin2hex(random_bytes(4)); // 8 hex chars; never the same as the last one
            } while ($version === $profile->photo_version);

            MemberPhoto::where('member_id', $member->id)->delete();
            $photo = new MemberPhoto(['club_id' => $club->id, 'member_id' => $member->id, 'image' => $bytes]);
            $photo->created_at = $now;
            $photo->updated_at = $now;
            $photo->save();

            $profile->photo_version = $version;
            $profile->photo_updated_at = $now;
            $profile->updated_at = $now;
            $profile->save();
        });

        return $this->cardResponse($club->id, $member->id);
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/member-profile/photo",
     *   summary="Remove the caller's photo (idempotent). Deletes the image.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="The card"),
     * )
     */
    public function deletePhoto(Request $request)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        DB::transaction(function () use ($club, $member) {
            MemberPhoto::where('member_id', $member->id)->delete();

            if ($profile = $this->profileOf($club->id, $member->id)) {
                $profile->photo_version = null;
                $profile->photo_updated_at = null;
                $profile->updated_at = Carbon::now();
                $profile->save();
            }
        });

        return $this->cardResponse($club->id, $member->id);
    }

    /**
     * The uploaded file's bytes, or [null, message]. Reads the normal multipart file
     * field; PHP leaves $_FILES empty for a PUT, so a multipart PUT body is also parsed by hand.
     *
     * @return array{0: ?string, 1: ?string}
     */
    private function uploadedBytes(Request $request): array
    {
        $file = $request->file('photo');
        $missing = [null, 'Choose a photo to upload.'];

        if (is_array($file)) {
            return [null, 'Send one photo.'];
        }

        if ($file instanceof UploadedFile) {
            if (!$file->isValid()) {
                $tooBig = in_array($file->getError(), [UPLOAD_ERR_INI_SIZE, UPLOAD_ERR_FORM_SIZE], true);

                return [null, $tooBig ? $this->tooLargeMessage() : 'The photo did not upload. Try again.'];
            }

            if ($file->getSize() > self::PHOTO_MAX_BYTES) {
                return [null, $this->tooLargeMessage()];
            }

            $bytes = @file_get_contents($file->getPathname());

            return $bytes === false || $bytes === '' ? [null, 'The photo did not upload. Try again.'] : [$bytes, null];
        }

        $type = (string) $request->headers->get('Content-Type');

        if (stripos($type, 'multipart/form-data') === false || !preg_match('/boundary="?([^";]+)"?/i', $type, $m)) {
            return $missing;
        }

        if ((int) $request->headers->get('Content-Length') > self::PHOTO_MAX_BYTES + 65536) {
            return [null, $this->tooLargeMessage()];
        }

        foreach (explode('--' . $m[1], $request->getContent()) as $part) {
            $split = strpos($part, "\r\n\r\n");

            if ($split === false || !preg_match('/name="photo"/i', substr($part, 0, $split))) {
                continue;
            }

            $bytes = substr($part, $split + 4);

            if (substr($bytes, -2) === "\r\n") {
                $bytes = substr($bytes, 0, -2);
            }

            return $bytes === '' ? $missing : [$bytes, null];
        }

        return $missing;
    }

    private function tooLargeMessage(): string
    {
        return 'That photo is too large. Choose one under 400 KB.';
    }

    /** A readable reason the bytes are not an acceptable photo, or null when they are. */
    private function photoProblem(string $bytes): ?string
    {
        if (strlen($bytes) > self::PHOTO_MAX_BYTES) {
            return $this->tooLargeMessage();
        }

        // JPEG only, judged by content and not by the client's file name or mime type.
        if (strncmp($bytes, "\xFF\xD8\xFF", 3) !== 0) {
            return 'The photo must be a JPEG.';
        }

        $info = @getimagesizefromstring($bytes);

        if (!is_array($info) || ($info[2] ?? null) !== IMAGETYPE_JPEG || ($info[0] ?? 0) < 1 || ($info[1] ?? 0) < 1) {
            return 'The photo must be a valid JPEG.';
        }

        if ($info[0] < self::PHOTO_MIN_SIDE || $info[1] < self::PHOTO_MIN_SIDE) {
            return 'That photo is too small. It must be at least ' . self::PHOTO_MIN_SIDE . ' pixels on each side.';
        }

        if ($info[0] > self::PHOTO_MAX_SIDE || $info[1] > self::PHOTO_MAX_SIDE) {
            return 'That photo is too big. It must be at most ' . self::PHOTO_MAX_SIDE . ' pixels on each side.';
        }

        return null;
    }

    // ---- signed download -------------------------------------------------------------

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/members/{memberId}/photo",
     *   summary="Download a member's photo through a signed link (no bearer token). Rate limited to 120/min per IP.",
     *   @OA\Parameter(name="v", in="query", required=true, @OA\Schema(type="string")),
     *   @OA\Parameter(name="sig", in="query", required=true, @OA\Schema(type="string")),
     *   @OA\Response(response=200, description="image/jpeg, Cache-Control: private, max-age=31536000, immutable"),
     *   @OA\Response(response=404, description="Bad signature, stale version or no photo (never says which)"),
     *   @OA\Response(response=429, description="too_many_requests"),
     * )
     */
    public function photo(Request $request, $clubId, $memberId)
    {
        $version = $request->query('v');
        $sig = $request->query('sig');

        // The signature is checked before anything touches the database.
        if (!ctype_digit((string) $clubId) || !MemberPhotoLink::valid((int) $clubId, $memberId, $version, $sig)) {
            return $this->notFound();
        }

        $profile = MemberProfile::where('club_id', (int) $clubId)->where('member_id', $memberId)->first();

        if (!$profile || $profile->photo_version === null || !hash_equals((string) $profile->photo_version, $version)) {
            return $this->notFound();
        }

        $bytes = MemberPhoto::where('club_id', (int) $clubId)->where('member_id', $memberId)->value('image');

        if (is_resource($bytes)) {
            $bytes = stream_get_contents($bytes);
        }

        if (!is_string($bytes) || $bytes === '') {
            return $this->notFound();
        }

        return response($bytes, 200, [
            'Content-Type' => 'image/jpeg',
            'Content-Length' => (string) strlen($bytes),
            'Cache-Control' => 'private, max-age=31536000, immutable',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    // ---- other members ---------------------------------------------------------------

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/members/{memberId}/profile",
     *   summary="Another active member's profile card: name (first name + surname initial), roles, photoPath, bio, goals (only if shared, or your own).",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="{ memberId, displayName, roles, photoPath, bio, goals, isYou }"),
     *   @OA\Response(response=404, description="Not an active member of this club"),
     * )
     */
    public function memberProfile(Request $request, $clubId, $memberId)
    {
        $club = $request->attributes->get('club');
        $caller = $request->attributes->get('member');

        $target = ClubMember::where('club_id', $club->id)->where('status', 'active')->find($memberId);

        if (!$target) {
            return $this->notFound('No such member.');
        }

        $athlete = $target->athlete_id !== null
            ? DB::table('athletes')->where('id', $target->athlete_id)->first(['first_name', 'last_name'])
            : null;
        $profile = $this->profileOf($club->id, $target->id);
        $isYou = $target->id === $caller->id;

        return response()->json([
            'memberId' => $target->id,
            'displayName' => ThreadAccess::shortName($athlete->first_name ?? null, $athlete->last_name ?? null),
            'roles' => $this->publicRoles($target->roles),
            'photoPath' => $profile ? MemberPhotoLink::path($club->id, $target->id, $profile->photo_version) : null,
            'bio' => $profile ? $profile->bio : null,
            'goals' => $profile && ($isYou || $profile->goals_visible) ? $profile->goals : null,
            'isYou' => $isYou,
        ]);
    }

    /**
     * @OA\Delete(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/members/{memberId}/profile",
     *   summary="Moderation (committee/admin): delete a member's photo and clear their bio and goals. Idempotent.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=204, description="Cleared"),
     *   @OA\Response(response=403, description="Not committee or admin"),
     *   @OA\Response(response=404, description="No such member in this club"),
     * )
     */
    public function clearProfile(Request $request, $clubId, $memberId)
    {
        $club = $request->attributes->get('club');

        if (!$request->attributes->get('member')->hasRole('committee', 'admin')) {
            return $this->forbidden('Only the committee can remove a member\'s photo and bio.');
        }

        $target = ClubMember::where('club_id', $club->id)->find($memberId);

        if (!$target) {
            return $this->notFound('No such member.');
        }

        DB::transaction(function () use ($club, $target) {
            MemberPhoto::where('member_id', $target->id)->delete();

            if ($profile = $this->profileOf($club->id, $target->id)) {
                $profile->bio = null;
                $profile->goals = null;
                $profile->goals_visible = false;
                $profile->photo_version = null;
                $profile->photo_updated_at = null;
                $profile->updated_at = Carbon::now();
                $profile->save();
            }
        });

        return response('', 204);
    }

    // ---- member cards ----------------------------------------------------------------

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/member-cards",
     *   summary="Every active member who is shown by name or has a photo/bio: leaders, committee, admins, recent or upcoming group leaders and coordinators, and anyone with a photo or bio. Full list, no since.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="{ items: [{ memberId, displayName, photoPath, roles, hasBio }], serverTime }"),
     * )
     */
    public function cards(Request $request)
    {
        $club = $request->attributes->get('club');
        $cutoff = Carbon::now()->utc()->subDays(self::CARD_WINDOW_DAYS)->format('Y-m-d H:i:s');

        $leaders = DB::table('session_group_leaders as l')
            ->join('session_groups as g', 'g.id', '=', 'l.group_id')
            ->join('sessions as s', 's.id', '=', 'g.session_id')
            ->where('l.club_id', $club->id)
            ->where('l.status', 'confirmed')
            ->whereNull('g.deleted_at')
            ->whereNull('s.deleted_at')
            ->where('s.starts_at', '>=', $cutoff)
            ->select('l.member_id');

        $coordinators = DB::table('sessions as s')
            ->where('s.club_id', $club->id)
            ->whereNull('s.deleted_at')
            ->whereNotNull('s.coordinator_member_id')
            ->where('s.starts_at', '>=', $cutoff)
            ->select('s.coordinator_member_id');

        // One query for everyone eligible (the two lists above are sub-selects of it).
        $rows = DB::table('club_members as m')
            ->leftJoin('athletes as a', 'a.id', '=', 'm.athlete_id')
            ->leftJoin('member_profiles as p', function ($join) {
                $join->on('p.member_id', '=', 'm.id')->on('p.club_id', '=', 'm.club_id');
            })
            ->where('m.club_id', $club->id)
            ->where('m.status', 'active')
            ->whereNull('m.deleted_at')
            ->where(function ($q) use ($leaders, $coordinators) {
                $q->whereNotNull('p.photo_version')
                    ->orWhere(function ($q) {
                        $q->whereNotNull('p.bio')->where('p.bio', '<>', '');
                    })
                    ->orWhere('m.roles', 'like', '%"leader"%')
                    ->orWhere('m.roles', 'like', '%"committee"%')
                    ->orWhere('m.roles', 'like', '%"admin"%')
                    ->orWhereIn('m.id', $leaders)
                    ->orWhereIn('m.id', $coordinators);
            })
            ->get(['m.id', 'm.roles', 'a.first_name', 'a.last_name', 'p.bio', 'p.photo_version']);

        $items = [];

        foreach ($rows as $row) {
            $items[] = [
                'memberId' => $row->id,
                'displayName' => ThreadAccess::shortName($row->first_name, $row->last_name),
                'photoPath' => MemberPhotoLink::path($club->id, $row->id, $row->photo_version),
                'roles' => $this->publicRoles(json_decode((string) $row->roles, true)),
                'hasBio' => $row->bio !== null && $row->bio !== '',
            ];
        }

        usort($items, function ($a, $b) {
            return strcmp(mb_strtolower($a['displayName']), mb_strtolower($b['displayName']))
                ?: strcmp($a['memberId'], $b['memberId']);
        });

        return response()->json([
            'items' => $items,
            'serverTime' => NotificationPresenter::time($this->serverTime()),
        ]);
    }
}
