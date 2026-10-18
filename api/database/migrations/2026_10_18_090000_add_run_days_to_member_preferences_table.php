<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Days a member usually runs: comma-separated ISO weekdays (1 = Monday ... 7 = Sunday), e.g. "1,3".
 * null = never chosen (every day). It hides other days in the app and keeps "you might want this"
 * run notifications to those days; lead_days stays a subset of it (D115).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('member_preferences', function (Blueprint $table) {
            $table->string('run_days', 20)->nullable()->after('lead_days');
        });
    }

    public function down(): void
    {
        Schema::table('member_preferences', function (Blueprint $table) {
            $table->dropColumn('run_days');
        });
    }
};
