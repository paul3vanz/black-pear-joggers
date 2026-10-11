<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * One chat message in the thread of a run group (Phase 6). Soft-deleted rows are
 * the tombstones that `?since=` delivers.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('group_messages', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('group_id');
            $table->uuid('member_id');
            $table->text('body');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('group_id')->references('id')->on('session_groups');
            $table->foreign('member_id')->references('id')->on('club_members');
            $table->index(['group_id', 'updated_at']);
            $table->index(['member_id', 'created_at']); // the per-member rate limit
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('group_messages');
    }
};
