<?php

namespace App\Http\Controllers;

use App\Models\MagicMile;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Input;
use Illuminate\Http\Request;

class MagicMileController extends Controller {

    public function __construct() {}

    public function getAll() {
        $results = MagicMile::query()->get()->all();
        return response()->json($results);
    }

    public function store(Request $request) {
        $validatedData = $this->validate($request, [
            'first_name' => 'required',
            'last_name' => 'required',
            'gender' => 'required',
            'category' => 'required',
            'date' => 'required',
            'location' => 'required',
            'predicted_time' => 'required',
            'predicted_time_parsed' => 'required',
            'actual_time' => 'required',
            'actual_time_parsed' => 'required'
        ]);

        $record = MagicMile::create([
            'athlete_id' => Input::get('athlete_id'),
            'first_name' => Input::get('first_name'),
            'last_name' => Input::get('last_name'),
            'gender' => Input::get('gender'),
            'category' => Input::get('category'),
            'date' => Input::get('date'),
            'location' => Input::get('location'),
            'predicted_time' => Input::get('predicted_time'),
            'predicted_time_parsed' => Input::get('predicted_time_parsed'),
            'actual_time' => Input::get('actual_time'),
            'actual_time_parsed' => Input::get('actual_time_parsed'),
        ]);
    }

    public function create() {
        return view('magicmile.create');
    }

    public function delete(string $id) {
        $result = MagicMile::destroy($id);
        return response()->json($id);
    }

    // Fetches all results in specific format needed for Angular application
    public function getAllLegacy() {
        $results = DB::select("
            SELECT
                id AS id,
                athlete_id AS athleteId,
                first_name AS firstName,
                last_name AS lastName,
                gender AS gender,
                category AS category,
                date AS date,
                location AS location,
                predicted_time AS predictedTime,
                predicted_time_parsed AS predictedTimeParsed,
                actual_time AS actualTime,
                actual_time_parsed AS actualTimeParsed,
                created_at AS createdAt,
                updated_at AS updatedAt
            FROM
                magicMile
            ORDER BY
                date DESC,
                actual_time_parsed ASC,
                last_name ASC
        ");

        return response()->json($results);
    }

}
