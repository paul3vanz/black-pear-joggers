<?php

namespace App\Http\Controllers;

use App\Models\AwardClaim;
use App\Models\AwardClaimRace;
use App\Models\User;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use Log;
use Illuminate\Support\Facades\Gate;

class AwardClaimController extends Controller
{
    public function __construct()
    {
    }

    /**
     * @OA\Get(
     *   tags={"AwardClaims"},
     *   path="/awardclaim",
     *   summary="Get all award claims, optionally filtered to one athlete",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="athleteId", in="query", required=false, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function getAll(Request $request)
    {
        $query = AwardClaim::query()->with('races');

        if ($request->filled('athleteId')) {
            $query->where('athleteId', $request->input('athleteId'));
        }

        $claims = $query->get();

        if (Gate::allows('clubStandards:admin')) {
            $claims->makeVisible(['email', 'token']);
        } else {
            $currentAthleteId = optional(User::where('id', Auth::user()['sub'] ?? null)->first())->athleteId;

            if ($currentAthleteId) {
                $claims->each(function (AwardClaim $claim) use ($currentAthleteId) {
                    if ($claim->athleteId === $currentAthleteId) {
                        $claim->makeVisible(['token']);
                    }
                });
            }
        }

        $claims = $claims->all();

        return response()->json($claims);
    }

    /**
     * @OA\Get(
     *   tags={"AwardClaims"},
     *   path="/awardclaim/{id}/{uniqueToken}",
     *   summary="Get an award claim by ID and unique token",
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Parameter(name="uniqueToken", in="path", required=true, @OA\Schema(type="string")),
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=404, description="Not found"),
     * )
     */
    public function getClaim($id, $uniqueToken)
    {
        $claim = AwardClaim::query()
            ->where('id', '=', $id)
            ->with('races')
            ->first();

        if (!$claim || !hash_equals((string) $claim->token, (string) $uniqueToken)) {
            abort(404);
        }

        $claim->makeVisible(['token']);

        return response()->json($claim);
    }

    /**
     * @OA\Post(
     *   tags={"AwardClaims"},
     *   path="/awardclaim/toggleverified/{id}",
     *   summary="Toggle whether an award claim is verified",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden"),
     * )
     */
    public function toggleVerified($id)
    {
        if (!Gate::allows('clubStandards:admin')) {
            abort(403);
        }

        $claim = AwardClaim::query()
            ->where('id', '=', $id)
            ->with('races')
            ->first();

        $claim->verified = !$claim->verified;

        $claim->save();

        return response()->json($claim);
    }

    /**
     * @OA\Post(
     *   tags={"AwardClaims"},
     *   path="/awardclaim/archive/{id}",
     *   summary="Archive an award claim",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden"),
     * )
     */
    public function archive($id)
    {
        if (!Gate::allows('clubStandards:admin')) {
            abort(403);
        }

        $claim = AwardClaim::query()
            ->where('id', '=', $id)
            ->with('races')
            ->first();

        $claim->archived = 1;

        $claim->save();

        return response()->json($claim);
    }

    /**
     * @OA\Post(
     *   tags={"AwardClaims"},
     *   path="/awardclaim/delete/{id}",
     *   summary="Delete an award claim",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden"),
     * )
     */
    public function delete($id)
    {
        if (!Gate::allows('clubStandards:admin')) {
            abort(403);
        }

        $claim = AwardClaim::destroy($id);

        return response()->json($claim);
    }

    /**
     * @OA\Patch(
     *   tags={"AwardClaims"},
     *   path="/awardclaim/{id}",
     *   summary="Update an award claim, and optionally its races",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(type="object")
     *   ),
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=403, description="Forbidden"),
     * )
     */
    public function update($id, Request $request)
    {
        if (!Gate::allows('clubStandards:admin')) {
            abort(403);
        }

        $claim = AwardClaim::query()
            ->where('id', '=', $id)
            ->with('races')
            ->first();;

        $claim->update($request->all());

        if ($request->input('races')) {
            $races = $request->input('races');

            foreach ($races as $race) {
                $claimRace = $claim->races()->find($race['id']);

                $claimRace->update($race);
            }
        }

        return response()->json($claim);
    }

    /**
     * @OA\Post(
     *   tags={"AwardClaims"},
     *   path="/awardclaim",
     *   summary="Submit a club standards award claim as the authenticated athlete",
     *   security={{"bearerAuth":{}}},
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"gender","category","award","firstName","lastName","email","races"},
     *       @OA\Property(property="gender", type="string", enum={"M", "W"}),
     *       @OA\Property(property="category", type="string"),
     *       @OA\Property(property="award", type="string"),
     *       @OA\Property(property="firstName", type="string"),
     *       @OA\Property(property="lastName", type="string"),
     *       @OA\Property(property="email", type="string", format="email"),
     *       @OA\Property(property="races", type="array", @OA\Items(type="object")),
     *     )
     *   ),
     *   @OA\Response(response=200, description="OK"),
     *   @OA\Response(response=400, description="No athlete linked to this account"),
     * )
     */
    public function submitClaim(Request $request)
    {
        $validatedData = $this->validate($request, [
            'gender' => 'required',
            'category' => 'required',
            'award' => 'required',
            'firstName' => 'required',
            'lastName' => 'required',
            'email' => 'required',
            'races' => 'required',
        ]);

        $user = User::where('id', Auth::user()['sub'])->first();

        if (!$user || !$user->athleteId) {
            return response()->json(['message' => 'No athlete linked to this account'], 400);
        }

        $claim = AwardClaim::create([
            'athleteId' => $user->athleteId,
            'gender' => $request->input('gender'),
            'category' => $request->input('category'),
            'award' => $request->input('award'),
            'firstName' => $request->input('firstName'),
            'lastName' => $request->input('lastName'),
            'email' => $request->input('email'),
        ]);

        Log::channel('slackAwardClaims')->info("Club standards {$request->input('award')} award claim submitted by {$request->input('firstName')} {$request->input('lastName')}");

        $claim->races()->createMany($request->input('races'));

        $claim->makeVisible(['token']);

        return response()->json($claim);
    }

    /**
     * @OA\Post(
     *   tags={"AwardClaims"},
     *   path="/awardclaim/{id}/race",
     *   summary="Update a race on an award claim",
     *   @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *   @OA\RequestBody(
     *     required=true,
     *     @OA\JsonContent(
     *       required={"id","race"},
     *       @OA\Property(property="id", type="integer"),
     *       @OA\Property(property="race", type="string"),
     *     )
     *   ),
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function submitClaimRace(Request $request, $awardClaimId)
    {
        $race = AwardClaimRace::find($request->input('id'));

        $race->race = $request->input('race');

        $race->save();

        return response()->json($race);
    }
}
