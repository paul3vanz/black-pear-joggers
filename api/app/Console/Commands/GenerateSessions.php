<?php

namespace App\Console\Commands;

use App\Models\SessionSeries;
use App\Services\SessionGenerator;
use Illuminate\Console\Command;

/**
 * Materialises club run sessions from their series, 8 weeks ahead. Idempotent;
 * the scheduler runs it hourly and every series write runs it for that series.
 *
 *   php artisan app:generate-sessions
 *   php artisan app:generate-sessions --series=<uuid>
 */
class GenerateSessions extends Command
{
    protected $signature = 'app:generate-sessions {--series= : only this series id}';

    protected $description = 'Generate club run sessions from their weekly series';

    public function handle(SessionGenerator $generator)
    {
        $id = $this->option('series');

        if ($id) {
            $series = SessionSeries::withTrashed()->find($id);

            if (!$series) {
                $this->error("No such series: $id");

                return 1;
            }

            $stats = $generator->generateForSeries($series);
            $stats['series'] = 1;
        } else {
            $stats = $generator->generateAll();
        }

        $this->info(sprintf(
            'Series %d: %d created, %d updated, %d restored, %d deleted.',
            $stats['series'],
            $stats['created'],
            $stats['updated'],
            $stats['restored'],
            $stats['deleted']
        ));

        return 0;
    }
}
