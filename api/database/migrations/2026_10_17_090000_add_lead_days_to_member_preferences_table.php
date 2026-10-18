<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Days a member may be able to lead: comma-separated ISO weekdays (1 = Monday ... 7 = Sunday),
 * e.g. "2,4". null = never chosen, empty string = chose "none". Decides who is asked to lead a run
 * that needs a leader (Services/LeaderAudience).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('member_preferences', function (Blueprint $table) {
            $table->string('lead_days', 20)->nullable()->after('push_daily_cap');
        });
    }

    public function down(): void
    {
        Schema::table('member_preferences', function (Blueprint $table) {
            $table->dropColumn('lead_days');
        });
    }
};
