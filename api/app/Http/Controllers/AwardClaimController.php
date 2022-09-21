<?php

namespace App\Http\Controllers;

use App\Models\AwardClaim;
use App\Models\AwardClaimRace;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use Log;
use Illuminate\Support\Facades\Gate;

class AwardClaimController extends Controller
{
    public function __construct()
    {
    }

    public function getAll()
    {
        $claims = AwardClaim::query()->with('races')->get();

        if (Gate::allows('clubStandards:admin')) {
            $claims->makeVisible(['email']);
        }

        $claims = $claims->all();

        return response()->json($claims);
    }

    public function getClaim($id, $uniqueToken)
    {
        $claim = AwardClaim::query()
            ->where('id', '=', $id)
            ->with('races')
            ->first();

        return response()->json($claim);
    }

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

    public function delete($id)
    {
        if (!Gate::allows('clubStandards:admin')) {
            abort(403);
        }

        $claim = AwardClaim::destroy($id);

        return response()->json($claim);
    }

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

        $claim = AwardClaim::create([
            'gender' => $request->input('gender'),
            'category' => $request->input('category'),
            'award' => $request->input('award'),
            'firstName' => $request->input('firstName'),
            'lastName' => $request->input('lastName'),
            'email' => $request->input('email'),
        ]);

        Log::channel('slackAwardClaims')->info("Club standards {$request->input('award')} award claim submitted by {$request->input('firstName')} {$request->input('lastName')}");

        $claim->races()->createMany($request->input('races'));

        return response()->json($claim);
    }

    public function submitClaimRace(Request $request, $awardClaimId)
    {
        $race = AwardClaimRace::find($request->input('id'));

        $race->race = $request->input('race');

        $race->save();

        return response()->json($race);
    }
}
