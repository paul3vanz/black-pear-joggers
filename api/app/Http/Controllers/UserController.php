<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;

class UserController extends Controller
{
    /**
     * Create a new controller instance.
     *
     * @return void
     */
    public function __construct()
    {
    }

    public function getUser(Request $request)
    {
        $authSubject = Auth::user()['sub'];

        $user = User::firstOrCreate(['authSubject' => $authSubject])->with('athlete');

        return response()->json($user);
    }

    public function setUser(Request $request)
    {
        $this->validate($request, [
            'athleteId' => 'required|integer'
        ]);

        $authSubject = Auth::user()['sub'];

        $user = User::find($authSubject);

        $user->athleteId = $request->athleteId;

        $user->save();

        return response()->json($user);
    }

    public function getToken(Request $request)
    {
        $user = Auth::user();

        return response()->json($user);
    }
}
