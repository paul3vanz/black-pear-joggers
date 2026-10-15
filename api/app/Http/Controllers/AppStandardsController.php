<?php

namespace App\Http\Controllers;

use App\Models\Athlete;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Phase 9: the BPJ club standards scheme for the app (read only).
 *
 * The standards, awards and events tables are the club's own scheme, shared
 * by every club (they have no club_id); the club route is for auth only.
 * Contract: ../mobile/docs/api-contract.md "Phase 9: club standards".
 */
class AppStandardsController extends Controller
{
    /** Legacy tables store 'M'/'W'; the API speaks 'male'/'female'. */
    const GENDERS = ['M' => 'male', 'W' => 'female', 'F' => 'female', 'MALE' => 'male', 'FEMALE' => 'female', 'WOMAN' => 'female', 'MAN' => 'male'];

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/standards",
     *   summary="The club standards table (awards by gender, age category and event) plus the caller's own gender and category",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="clubId", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="OK. Carries an ETag; send it back as If-None-Match"),
     *   @OA\Response(response=304, description="Not modified"),
     *   @OA\Response(response=403, description="Not linked to this club"),
     *   @OA\Response(response=404, description="Club not found"),
     * )
     */
    public function index(Request $request)
    {
        $member = $request->attributes->get('member');

        // Query 1: awards, lowest id first (Bronze ... Platinum).
        $awards = DB::table('awards')->orderBy('id')->get(['id', 'name']);

        // Query 2: every standard with its event and award.
        $rows = DB::table('standards')
            ->join('events', 'standards.event_id', '=', 'events.id')
            ->select('standards.gender', 'standards.category', 'standards.award_id', 'standards.time', 'standards.time_parsed', 'events.event', 'events.distance')
            ->get();

        $awardNames = $awards->pluck('name', 'id')->all();
        $awardOrder = array_flip($awards->pluck('id')->all());

        $items = [];
        $events = [];
        $categories = ['male' => [], 'female' => []];

        foreach ($rows as $row) {
            $gender = self::GENDERS[strtoupper(trim((string) $row->gender))] ?? null;
            $category = strtoupper(trim((string) $row->category));

            // Rows for an award that no longer exists, or an unknown gender, are not published.
            if ($gender === null || $category === '' || !isset($awardNames[$row->award_id])) {
                continue;
            }

            // events.distance is in metres (the Angular pace pipe divides it as metres: 1609.34, 21097.5, 42195).
            $distance = (float) $row->distance;
            $distanceM = $distance == floor($distance) ? (int) $distance : $distance;

            $events[$row->event] = $distanceM;
            $categories[$gender][$category] = true;

            $items[] = [
                'gender' => $gender,
                'category' => $category,
                'event' => $row->event,
                'award' => $awardNames[$row->award_id],
                'time' => trim((string) $row->time),
                'timeS' => self::seconds($row->time_parsed, $row->time),
                '_g' => $gender === 'male' ? 0 : 1,
                '_c' => self::categoryRank($category),
                '_d' => $distance,
                '_a' => $awardOrder[$row->award_id],
            ];
        }

        usort($items, fn ($a, $b) => [$a['_g'], $a['_c'], $a['_d'], $a['_a']] <=> [$b['_g'], $b['_c'], $b['_d'], $b['_a']]);
        foreach ($items as &$item) {
            unset($item['_g'], $item['_c'], $item['_d'], $item['_a']);
        }
        unset($item);

        asort($events);
        $eventList = [];
        foreach ($events as $name => $distanceM) {
            $eventList[] = ['event' => $name, 'distanceM' => $distanceM];
        }

        foreach ($categories as $gender => $set) {
            $list = array_keys($set);
            usort($list, fn ($a, $b) => self::categoryRank($a) <=> self::categoryRank($b));
            $categories[$gender] = $list;
        }

        $body = [
            'awards' => array_values($awardNames),
            'events' => $eventList,
            'categories' => $categories,
            'items' => $items,
            'mine' => $this->mine($member->athlete_id, $categories),
        ];

        // The ETag covers everything except updatedAt, so it only changes when the data or `mine` does.
        $etag = '"' . sha1(json_encode($body)) . '"';

        if ($this->etagMatches($request->header('If-None-Match'), $etag)) {
            return response('', 304, ['ETag' => $etag, 'Cache-Control' => 'private, no-cache']);
        }

        // The tables carry no timestamps, so this is when the server built the response.
        $body['updatedAt'] = Carbon::now()->utc()->format('Y-m-d\TH:i:s\Z');

        return response()->json($body, 200, ['ETag' => $etag, 'Cache-Control' => 'private, no-cache']);
    }

    /**
     * The caller's gender and category, from the same athlete derivation the
     * profile endpoint uses (Athlete::category), in the table's vocabulary.
     */
    private function mine($athleteId, array $categories): ?array
    {
        $athlete = Athlete::find($athleteId);
        if (!$athlete) {
            return null;
        }

        $gender = self::GENDERS[strtoupper(trim((string) $athlete->gender))] ?? null;
        $category = $athlete->category;
        if ($gender === null || !$category || !$categories[$gender]) {
            return null;
        }

        $available = $categories[$gender];
        if (!in_array($category, $available, true)) {
            // An age band the table stops short of (V85, V90...) falls back to the oldest band that exists.
            $vets = array_values(array_filter($available, fn ($c) => $c[0] === 'V'));
            $oldest = $vets ? end($vets) : null;

            if ($oldest === null || $category[0] !== 'V' || self::categoryRank($category) < self::categoryRank($oldest)) {
                return null;
            }

            $category = $oldest;
        }

        return ['gender' => $gender, 'category' => $category];
    }

    /** U20, U23, SEN, then V35, V40... numerically; anything else last. */
    private static function categoryRank(string $category): int
    {
        if ($category === 'U20') return 0;
        if ($category === 'U23') return 1;
        if ($category === 'SEN') return 2;
        if (preg_match('/^V(\d+)$/', $category, $m)) return 10 + (int) $m[1];

        return 1000;
    }

    /**
     * standards.time_parsed holds seconds (it is compared with performances.time_parsed);
     * fall back to parsing the `time` text (mm:ss or h:mm:ss) when it is empty.
     */
    private static function seconds($parsed, $text): ?int
    {
        if ($parsed !== null && $parsed !== '' && is_numeric($parsed) && (float) $parsed > 0) {
            return (int) round((float) $parsed);
        }

        $parts = explode(':', trim((string) $text));
        if (count($parts) < 2 || count($parts) > 3) {
            return null;
        }

        $total = 0.0;
        foreach ($parts as $part) {
            if (!is_numeric($part)) {
                return null;
            }
            $total = $total * 60 + (float) $part;
        }

        return (int) round($total);
    }

    private function etagMatches(?string $header, string $etag): bool
    {
        if ($header === null || $header === '') {
            return false;
        }

        foreach (explode(',', $header) as $candidate) {
            $candidate = trim($candidate);
            if ($candidate === '*' || preg_replace('/^W\//', '', $candidate) === $etag) {
                return true;
            }
        }

        return false;
    }
}
