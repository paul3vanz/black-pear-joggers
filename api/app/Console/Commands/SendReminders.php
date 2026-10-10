<?php

namespace App\Console\Commands;

use App\Services\RunReminderService;
use Illuminate\Console\Command;

/**
 * Morning-of run reminders and "leaders needed" alerts (Phase 5b). Idempotent
 * through notification dedupe keys; the scheduler runs it every 10 minutes.
 *
 *   php artisan app:send-reminders
 */
class SendReminders extends Command
{
    protected $signature = 'app:send-reminders';

    protected $description = 'Send run reminders and leaders-needed alerts that are due';

    public function handle(RunReminderService $service)
    {
        $stats = $service->run();

        $this->info(sprintf('%d reminders, %d leaders-needed alerts.', $stats['reminders'], $stats['leadersNeeded']));

        return 0;
    }
}
