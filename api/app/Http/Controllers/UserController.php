<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function __construct()
    {
    }

    public function getUser()
    {
        $id = Auth::user()['sub'];

        $user = User::find($id)->with('athlete')->first();

        return response()->json($user);
    }

    public function setUser(Request $request)
    {
        $this->validate($request, [
            'athleteId' => 'required|integer'
        ]);

        $id = Auth::user()['sub'];

        $user = User::updateOrCreate(['id' => $id], ['athleteId' => $request->athleteId]);

        return response()->json($user);
    }

    public function getToken()
    {
        $user = Auth::user();

        return response()->json($user);
    }
}
