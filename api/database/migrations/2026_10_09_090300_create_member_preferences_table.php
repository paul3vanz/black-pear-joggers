<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A member's units and usual pace range, per club. A missing row means the
 * defaults (mi / mi, no range).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('member_preferences', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('member_id');
            $table->char('pace_unit', 2)->default('mi');
            $table->char('distance_unit', 2)->default('mi');
            $table->unsignedSmallInteger('pace_from_s')->nullable();
            $table->unsignedSmallInteger('pace_to_s')->nullable();
            $table->timestamps();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('member_id')->references('id')->on('club_members');
            $table->unique(['club_id', 'member_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('member_preferences');
    }
};
