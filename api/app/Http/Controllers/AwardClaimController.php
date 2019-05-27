<?php

namespace App\Http\Controllers;

use App\Models\AwardClaim;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Input;
use Illuminate\Http\Request;

class AwardClaimController extends Controller
{
  public function __construct() {}

  public function getAll() {
    $claims = AwardClaim::query()->with('races')->get()->all();
    return response()->json($claims);
  }

  public function getClaim($id, $uniqueToken) {
    $claim = AwardClaim::query()
      ->find($id)
      ->with('races')
      ->first();

    return response()->json($claim);
  }

  public function submitClaim(Request $request) {
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
      'gender' => Input::get('gender'),
      'category' => Input::get('category'),
      'award' => Input::get('award'),
      'firstName' => Input::get('firstName'),
      'lastName' => Input::get('lastName'),
      'email' => Input::get('email'),
    ]);

    $claim->races()->createMany(Input::get('races'));

    return response()->json($claim);
  }
}