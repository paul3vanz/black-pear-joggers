<?php

namespace App\Http\Controllers;

use App\Models\AwardClaim;
use App\Models\AwardClaimRace;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;

class AwardClaimController extends Controller
{
    public function __construct()
    {
    }

    public function getAll()
    {
        $claims = AwardClaim::query()->with('races')->get()->makeVisible(['email'])->all();
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
        $claim = AwardClaim::destroy($id);

        return response()->json($claim);
    }

    public function update(Request $request)
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
