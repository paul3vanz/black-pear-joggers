<?php

namespace App\Http\Controllers;

use Goutte\Client;
use App\Jobs\FetchRankingsJob;
use App\Models\Athlete;
use App\Models\Ranking;
use Illuminate\Support\Facades\Artisan;
use DB;
use Log;
use DateTime;

class FetchRankingsController extends Controller
{
    public function __construct() {}

    public function queueAllFetchRankings() {
        $athleteIds = array();

        $athletes = Athlete::whereNotNull('urn')
            ->where('active', '=', '1')
            ->where('club', 'like', 'Black Pear%')
            ->where('urn', '=', '3127917')
            ->get();

        foreach($athletes as $athlete) {
            dispatch(new FetchRankingsJob($athlete));

            $athleteIds[] = $athlete->id;
        }

        return response()->json($athleteIds);
    }

    public function fetchRankings($athleteId) {
        Log::info("fetchRankings($athleteId)");
        $addedRankings = array();

        $athletes = Athlete::where('athlete_id', '=', $athleteId)->get();

        foreach($athletes as $athlete) {
            $html = $this->fetchRunBritainRankingsAthleteProfile($athlete->urn);

            $addedRankings = $this->parseRankingHistory($athlete, $html);

            Log::info('Added ' . sizeof($addedRankings));
        }

        return response()->json($addedRankings);
    }

    private function fetchRunBritainRankingsAthleteProfile($athleteUrn) {
        Log::info("fetchRunBritainRankingsProfile($athleteUrn)");

        $fetchUrl = 'https://www.runbritainrankings.com/runners/profile.aspx?ukaurn=' . $athleteUrn;
        $httpClient = new Client();
        $html = $httpClient->request('GET', $fetchUrl);

        return $html;
    }

    private function createRanking($ranking) {
        return Ranking::firstOrCreate([
            'athlete_id' => $ranking['athlete_id'],
            'date' => $ranking['date'],
            'ranking' => $ranking['ranking']
        ]);
    }

    private function parseRankingHistory(Athlete $athlete, $html) {

        $addedRankings = array();

        $rankingScriptData = $html->filter('div[id=cphBody_progressgraph_pnlMain] script')->eq(0)->text();

        preg_match('/data: (.*]])/', $rankingScriptData, $rankingDataPoints);

        $rankingDataPoints = json_decode($rankingDataPoints[1]);

        // TODO: We want to keep all old data, just mark as old, not remove
        $staleRankings = Ranking::where('athlete_id', $athlete->id)->delete();

        if (!$rankingDataPoints) {
            return;
        }

        foreach($rankingDataPoints as $rankingDataPoint) {
            $date = date('Y-m-d', substr($rankingDataPoint[0], 0, 10));
            $ranking = $rankingDataPoint[1];

            $addedRankings[] = $this->createRanking([
                'athlete_id' => $athlete->id,
                'date' => $date,
                'ranking' => $ranking
            ]);
        }

        return $addedRankings;
    }
}