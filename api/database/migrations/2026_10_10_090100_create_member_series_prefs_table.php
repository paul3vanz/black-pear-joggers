<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A member's run-reminder override for one weekly series: on (always) or off
 * (never). No row means automatic.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('member_series_prefs', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('member_id');
            $table->uuid('series_id');
            $table->string('reminders', 4); // on | off
            $table->timestamps();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('member_id')->references('id')->on('club_members');
            $table->foreign('series_id')->references('id')->on('session_series');
            $table->unique(['member_id', 'series_id']);
            $table->index('series_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('member_series_prefs');
    }
};
