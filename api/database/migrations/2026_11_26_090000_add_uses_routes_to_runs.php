<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Whether a run (and its series) has routes set for it. Defaults to true, so
 * every existing run keeps its Routes card; the committee turns it off for runs
 * with no set routes (the Thursday Mug Run, track night).
 */
return new class extends Migration
{
    public function up(): void
    {
        foreach (['session_series', 'sessions'] as $name) {
            Schema::table($name, function (Blueprint $table) {
                $table->boolean('uses_routes')->default(true);
            });
        }
    }

    public function down(): void
    {
        foreach (['session_series', 'sessions'] as $name) {
            Schema::table($name, function (Blueprint $table) {
                $table->dropColumn('uses_routes');
            });
        }
    }
};
