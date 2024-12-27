<?php

namespace App\Http\Controllers;

use App\Models\Standard;
use Illuminate\Support\Facades\Artisan;
use OpenApi\Annotations as OA;

class StandardController extends Controller
{
    /**
     * Create a new controller instance.
     *
     * @return void
     */
    public function __construct()
    {
    }

    /**
     * @OA\Get(
     *   tags={"Standards"},
     *   path="/standards",
     *   summary="Get all standards",
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function getStandards()
    {
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

    /**
     * @OA\Get(
     *   tags={"Standards"},
     *   path="/standards/{gender}",
     *   summary="Get standards by gender",
     *   @OA\Parameter(name="gender", in="path", required=true, @OA\Schema(type="string", enum={"M", "W"})),
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function getStandardsByGender($gender)
    {
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

    /**
     * @OA\Get(
     *   tags={"Standards"},
     *   path="/standards/{gender}/{category}",
     *   summary="Get standards by category and gender",
     *   @OA\Parameter(name="gender", in="path", required=true, @OA\Schema(type="string", enum={"M", "W"})),
     *   @OA\Parameter(name="category", in="path", required=true, @OA\Schema(type="string", enum={"SEN","V35","V40","V45","V50","V55","V60","V65","V70","U20","U23"})),
     *   @OA\Response(response=200, description="OK"),
     * )
     */
    public function getStandardsByCategory($gender, $category)
    {
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
