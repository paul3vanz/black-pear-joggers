<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A member's own state for one group thread: when they last read it and whether
 * they muted it. No row means never read and not muted.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('group_thread_states', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('group_id');
            $table->uuid('member_id');
            $table->timestamp('last_read_at')->nullable();
            $table->boolean('muted')->default(false);
            $table->timestamps();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('group_id')->references('id')->on('session_groups');
            $table->foreign('member_id')->references('id')->on('club_members');
            $table->unique(['group_id', 'member_id']);
            $table->index('member_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('group_thread_states');
    }
};
