<?php

namespace App\Http\Controllers;

use App\Models\Log;
use Illuminate\Support\Facades\Artisan;

class LogsController extends Controller
{
    /**
     * Create a new controller instance.
     *
     * @return void
     */
    public function __construct() {

    }

    public function getLogs() {
        $logs = Log::query()->get()->all();
        return response()->json($logs);
    }

    public function getLog($id) {
        $log = Log::query()->find($id);
        return response()->json($log);
    }
}
