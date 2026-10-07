<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Every urn + dob link attempt, so failed guesses can be rate limited per
 * login and club.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('member_link_attempts', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->increments('id');
            $table->string('user_id', 128);
            $table->unsignedInteger('club_id');
            $table->boolean('success')->default(false);
            $table->timestamp('created_at')->nullable();

            $table->index(['user_id', 'club_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('member_link_attempts');
    }
};
