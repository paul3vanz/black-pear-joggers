<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Concrete dated club runs: generated from a series, edited per occurrence, or
 * ad-hoc (no series). Times are stored as UTC instants plus the club-local
 * strings the app displays.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sessions', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('series_id')->nullable();
            $table->date('occurrence_date')->nullable(); // the series date this row stands for
            $table->timestamp('starts_at')->nullable();
            $table->timestamp('ends_at')->nullable();
            $table->date('local_date');
            $table->char('local_start_time', 5); // HH:MM, club-local
            $table->char('local_end_time', 5);
            $table->uuid('venue_id')->nullable();
            $table->string('title');
            $table->text('notes')->nullable();
            $table->string('group_mode', 16);
            $table->uuid('coordinator_member_id')->nullable();
            $table->string('status', 16)->default('scheduled'); // scheduled | cancelled
            $table->string('cancel_reason')->nullable();
            $table->boolean('is_detached')->default(false);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('series_id')->references('id')->on('session_series');
            $table->foreign('venue_id')->references('id')->on('venues');
            $table->foreign('coordinator_member_id')->references('id')->on('club_members');
            $table->unique(['series_id', 'occurrence_date']);
            $table->index(['club_id', 'local_date']);
            $table->index(['club_id', 'updated_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sessions');
    }
};
