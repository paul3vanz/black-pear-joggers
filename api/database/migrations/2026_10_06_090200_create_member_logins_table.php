<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Maps an Auth0 login (sub) to a club member. unique(club_id, user_id) means a
 * login resolves to at most one member per club.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('member_logins', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('member_id');
            $table->string('user_id', 128); // Auth0 sub
            $table->timestamp('linked_at')->nullable();
            $table->timestamps();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('member_id')->references('id')->on('club_members');
            $table->unique(['club_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('member_logins');
    }
};
