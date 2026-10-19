<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * One saved choice per member and series drives both the Runs feed and run reminders (D117):
 * member_series_prefs.mode is follow | auto | hide (no row = auto). The old `reminders` value
 * (on | off) becomes nullable and is kept, unread, until the day filter is removed; rows written
 * from now on leave it null. member_preferences.follows_migrated_at marks a member whose old
 * reminder settings and run days have been turned into modes (`app:migrate-follows`).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('member_series_prefs', function (Blueprint $table) {
            $table->string('reminders', 4)->nullable()->change();
        });
        Schema::table('member_series_prefs', function (Blueprint $table) {
            $table->string('mode', 6)->nullable()->after('reminders');
        });
        Schema::table('member_preferences', function (Blueprint $table) {
            $table->timestamp('follows_migrated_at')->nullable()->after('run_days');
        });
    }

    public function down(): void
    {
        Schema::table('member_preferences', function (Blueprint $table) {
            $table->dropColumn('follows_migrated_at');
        });
        Schema::table('member_series_prefs', function (Blueprint $table) {
            $table->dropColumn('mode');
        });
    }
};
