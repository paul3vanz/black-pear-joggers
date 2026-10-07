<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * One row per person per club, keyed by their athlete record. Several Auth0
 * logins can point at the same member (see member_logins).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('club_members', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->integer('athlete_id'); // athletes.id (internal id, not the EA/PO10 athlete_id)
            $table->string('display_name');
            $table->json('roles'); // leader, committee, admin
            $table->string('status', 16)->default('active'); // active | lapsed
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->unique(['club_id', 'athlete_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('club_members');
    }
};
