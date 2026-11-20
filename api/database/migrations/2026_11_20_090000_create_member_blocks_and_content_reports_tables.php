<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Report and block (Apple guideline 1.2).
 *
 *  - member_blocks: a member hides another member's messages and profile card
 *    for themselves. One row per (blocker, blocked); the app does the hiding.
 *  - content_reports: a member tells the committee about a message, comment or
 *    profile card. `excerpt` is a copy of the text at report time, because the
 *    author may delete the message afterwards.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('member_blocks', function (Blueprint $table) {
            $table->engine = 'InnoDB';
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('blocker_member_id');
            $table->uuid('blocked_member_id');
            $table->timestamps();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('blocker_member_id')->references('id')->on('club_members');
            $table->foreign('blocked_member_id')->references('id')->on('club_members');
            $table->unique(['blocker_member_id', 'blocked_member_id']);
            $table->index('blocked_member_id');
        });

        Schema::create('content_reports', function (Blueprint $table) {
            $table->engine = 'InnoDB';
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('reporter_member_id');
            $table->uuid('reported_member_id');
            $table->string('kind', 20); // message | leader_message | comment | profile
            $table->uuid('target_id')->nullable();
            $table->string('reason', 20); // spam | abusive | inappropriate | other
            $table->string('details', 500)->nullable();
            $table->text('excerpt')->nullable();
            $table->string('status', 20)->default('open');
            $table->timestamps();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('reporter_member_id')->references('id')->on('club_members');
            $table->foreign('reported_member_id')->references('id')->on('club_members');
            $table->index(['reporter_member_id', 'created_at']); // the per-member rate limit
            $table->index(['club_id', 'status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('content_reports');
        Schema::dropIfExists('member_blocks');
    }
};
