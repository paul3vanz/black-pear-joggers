<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * One row per member per run: going / maybe / not_going, optionally in a group,
 * with an optional pace for this run only (otherwise the member's preference).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('session_attendees', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('session_id');
            $table->uuid('member_id');
            $table->uuid('group_id')->nullable();
            $table->string('status', 16); // going | maybe | not_going
            $table->char('pace_unit', 2)->nullable(); // mi | km
            $table->unsignedSmallInteger('pace_from_s')->nullable();
            $table->unsignedSmallInteger('pace_to_s')->nullable();
            $table->timestamps();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('session_id')->references('id')->on('sessions');
            $table->foreign('member_id')->references('id')->on('club_members');
            $table->foreign('group_id')->references('id')->on('session_groups');
            $table->unique(['session_id', 'member_id']);
            $table->index('group_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('session_attendees');
    }
};
