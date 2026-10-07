<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A pace/distance group inside one run. Pace and distance are stored as entered
 * (value + unit); the API derives canonical sec/km and metres on the fly.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('session_groups', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('session_id');
            $table->string('kind', 16)->default('run'); // run | jog_walk | efforts | route | social | other
            $table->string('label', 80)->nullable();
            $table->text('description')->nullable();
            $table->char('pace_unit', 2)->nullable(); // mi | km
            $table->unsignedSmallInteger('pace_from_s')->nullable(); // the faster end
            $table->unsignedSmallInteger('pace_to_s')->nullable(); // the slower end
            $table->decimal('distance_value', 6, 2)->nullable();
            $table->char('distance_unit', 2)->nullable(); // mi | km
            $table->string('status', 16)->default('active'); // active | needs_leader
            $table->smallInteger('sort_order')->default(0);
            $table->uuid('created_by_member_id')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('session_id')->references('id')->on('sessions');
            $table->foreign('created_by_member_id')->references('id')->on('club_members');
            $table->index('session_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('session_groups');
    }
};
