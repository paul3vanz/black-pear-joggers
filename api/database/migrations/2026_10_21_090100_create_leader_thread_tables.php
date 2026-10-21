<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The leaders thread of a run (D125): one chat per session between the
 * committee and the people who lead or have been asked to lead it, so replies
 * never depend on which committee member asked.
 *
 *  - leader_messages: a chat message, or an "ask" (kind `ask`) from the
 *    committee for someone to lead a pace range (`ask_fast_s_per_km` to
 *    `ask_slow_s_per_km`, seconds per km). Soft-deleted rows are the
 *    tombstones `?since=` delivers. `renudged_at` is when an unanswered ask
 *    was repeated once.
 *  - leader_thread_states: a member's own last-read time and mute flag.
 *  - leader_thread_members: who an ask went to, so they can read and answer it.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('leader_messages', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('session_id');
            $table->uuid('member_id');
            $table->string('kind', 16)->default('message');
            $table->text('body');
            $table->unsignedInteger('ask_fast_s_per_km')->nullable();
            $table->unsignedInteger('ask_slow_s_per_km')->nullable();
            $table->timestamp('renudged_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('session_id')->references('id')->on('sessions');
            $table->foreign('member_id')->references('id')->on('club_members');
            $table->index(['session_id', 'updated_at']);
            $table->index(['member_id', 'created_at']); // the per-member rate limit
        });

        Schema::create('leader_thread_states', function (Blueprint $table) {
            $table->engine = 'InnoDB';
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('session_id');
            $table->uuid('member_id');
            $table->timestamp('last_read_at')->nullable();
            $table->boolean('muted')->default(false);
            $table->timestamps();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('session_id')->references('id')->on('sessions');
            $table->foreign('member_id')->references('id')->on('club_members');
            $table->unique(['session_id', 'member_id']);
            $table->index('member_id');
        });

        Schema::create('leader_thread_members', function (Blueprint $table) {
            $table->engine = 'InnoDB';
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('session_id');
            $table->uuid('member_id');
            $table->timestamps();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('session_id')->references('id')->on('sessions');
            $table->foreign('member_id')->references('id')->on('club_members');
            $table->unique(['session_id', 'member_id']);
            $table->index('member_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('leader_thread_members');
        Schema::dropIfExists('leader_thread_states');
        Schema::dropIfExists('leader_messages');
    }
};
