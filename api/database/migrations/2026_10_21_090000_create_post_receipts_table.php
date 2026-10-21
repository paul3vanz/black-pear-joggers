<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * What each member has done with a club update: when it reached their device
 * (`delivered_at`) and when they opened it and read it to the end (`read_at`).
 * Reported by the app, always on (not a setting); only the committee can read
 * them back. No row means neither has happened.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('post_receipts', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('post_id');
            $table->uuid('member_id');
            $table->timestamp('delivered_at')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('post_id')->references('id')->on('posts');
            $table->foreign('member_id')->references('id')->on('club_members');
            $table->unique(['post_id', 'member_id']);
            $table->index('member_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('post_receipts');
    }
};
