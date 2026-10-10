<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Phase 5: how many capped pushes a member accepts per rolling 24 hours.
 * null = the default (6), 0 = no limit.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('member_preferences', function (Blueprint $table) {
            $table->unsignedSmallInteger('push_daily_cap')->nullable()->after('pace_to_s');
        });
    }

    public function down(): void
    {
        Schema::table('member_preferences', function (Blueprint $table) {
            $table->dropColumn('push_daily_cap');
        });
    }
};
