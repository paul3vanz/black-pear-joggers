<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Laravel\Lumen\Console\Kernel as ConsoleKernel;
use Log;

class Kernel extends ConsoleKernel
{
    /**
     * The Artisan commands provided by your application.
     *
     * @var array
     */
    protected $commands = [
        'App\Console\Commands\QueueFetchPerformances',
        'App\Console\Commands\QueueFetchRankings',
        'App\Console\Commands\QueueProcessRegistrations'
    ];

    /**
     * Define the application's command schedule.
     *
     * @param  \Illuminate\Console\Scheduling\Schedule  $schedule
     * @return void
     */
    protected function schedule(Schedule $schedule)
    {
        Log::info('Scheduler run');
        $schedule->command('queue:fetch:performances')->dailyAt('01:00');
        $schedule->command('queue:fetch:rankings')->dailyAt('04:00');
        // $schedule->command('queue:registrations')->hourly();
        $schedule->command('queue:work --stop-when-empty')->dailyAt('05:00');
    }
}
