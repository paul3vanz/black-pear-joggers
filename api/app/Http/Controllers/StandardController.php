<?php

namespace App\Http\Controllers;

use App\Models\Standard;
use Illuminate\Support\Facades\Artisan;

class StandardController extends Controller
{
    /**
     * Create a new controller instance.
     *
     * @return void
     */
    public function __construct() {

    }

    public function getStandards() {
        $standards = Standard::join('events', 'standards.event_id', '=', 'events.id')
            ->join('awards', 'standards.award_id', '=', 'awards.id')
            ->orderBy('gender')
            ->orderBy('category')
            ->orderBy('events.distance')
            ->orderBy('awards.id')
            ->select('standards.id', 'standards.gender', 'standards.category', 'events.event', 'awards.name', 'time', 'time_parsed')
            ->get()
            ->all();
        return response()->json($standards);
    }

    public function getStandardsByGender($gender) {
        $standards = Standard::join('events', 'standards.event_id', '=', 'events.id')
            ->join('awards', 'standards.award_id', '=', 'awards.id')
            ->where('gender', $gender)
            ->orderBy('gender')
            ->orderBy('category')
            ->orderBy('events.distance')
            ->orderBy('awards.id')
            ->select('standards.id', 'standards.gender', 'standards.category', 'events.event', 'awards.name', 'time', 'time_parsed')
            ->get()
            ->all();
        return response()->json($standards);
    }

    public function getStandardsByCategory($gender, $category) {
        $standards = Standard::join('events', 'standards.event_id', '=', 'events.id')
            ->join('awards', 'standards.award_id', '=', 'awards.id')
            ->where('gender', $gender)
            ->where('category', $category)
            ->orderBy('gender')
            ->orderBy('category')
            ->orderBy('events.distance')
            ->orderBy('awards.id')
            ->select('standards.id', 'standards.gender', 'standards.category', 'events.event', 'awards.name', 'time', 'time_parsed')
            ->get()
            ->all();
        return response()->json($standards);
    }
}
