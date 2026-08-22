<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Laravel\Lumen\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    /**
     * The Artisan commands provided by your application.
     *
     * @var array
     */
    protected $commands = [
        'App\Console\Commands\QueueFetchAthletes',
        'App\Console\Commands\QueueFetchPerformances',
        'App\Console\Commands\QueueFetchRankings',
        'App\Console\Commands\QueueFetchMemberships',
        'App\Console\Commands\QueueFetchPayments',
        'App\Console\Commands\QueueProcessRegistrations',
        'App\Console\Commands\QueueUpdatePersonalBests',
        'App\Console\Commands\StartDatabaseCleanup',
    ];

    /**
     * Define the application's command schedule.
     *
     * @param  \Illuminate\Console\Scheduling\Schedule  $schedule
     * @return void
     */
    protected function schedule(Schedule $schedule)
    {
        $schedule->command('queue:registrations')->dailyAt('00:00');
        $schedule->command('queue:fetch:memberships')->everySixHours();
        $schedule->command('queue:fetch:payments')->everySixHours();
        // One job per athlete covers both the performances and the handicap,
        // because both are read off the same page. queue:fetch:performances
        // and queue:fetch:rankings still work on their own, by hand.
        $schedule->command('queue:fetch:athletes')->dailyAt('01:00');
        $schedule->command('queue:work --stop-when-empty')->dailyAt('05:00');
        $schedule->command('queue:fetch:updatepersonalbests')->dailyAt('07:00');
        $schedule->command('db:cleanup')->dailyAt('23:00');
    }
}
