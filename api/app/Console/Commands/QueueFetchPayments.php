<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Http\Controllers\FetchPaymentsController;
use Log;

class QueueFetchPayments extends Command
{
    protected $name = 'queue:fetch:payments';

    public function handle()
    {
        Log::info('QueueFetchPayments');
        $fetchPaymentsController = new FetchPaymentsController();
        $fetchPaymentsController->fetchPayments();
    }
}
