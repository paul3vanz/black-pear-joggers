<?php

namespace App\Http\Controllers;

use App\Models\Event;
use Illuminate\Support\Facades\Artisan;

class EventController extends Controller
{
    /**
     * Create a new controller instance.
     *
     * @return void
     */
    public function __construct() {

    }

    /**
     * @OA\Get(
     *   tags={"Events"},
     *   path="/events",
     *   summary="Get all events",
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function getEvents() {
        $events = Event::query()->get()->all();
        return response()->json($events);
    }

    public function getEvent($id) {
        $event = Event::query()->find($id);
        return response()->json($event);
    }

    public function deleteEvent($id) {
        $event = Event::query()->find($id);
        return response()->json($event);
    }
}
