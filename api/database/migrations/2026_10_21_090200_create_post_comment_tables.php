<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Comments on a club update (D126): a thread per post where members ask
 * questions and the committee replies.
 *
 *  - post_comments: one message. Soft-deleted rows are the tombstones `?since=`
 *    delivers.
 *  - post_thread_states: a member's own last-read time and mute flag. A row also
 *    means they have opened the thread, so they hear about replies.
 *  - posts.comments_closed_at: the committee closed comments on this update.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('post_comments', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('post_id');
            $table->uuid('member_id');
            $table->text('body');
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('post_id')->references('id')->on('posts');
            $table->foreign('member_id')->references('id')->on('club_members');
            $table->index(['post_id', 'updated_at']);
            $table->index(['member_id', 'created_at']); // the per-member rate limit
        });

        Schema::create('post_thread_states', function (Blueprint $table) {
            $table->engine = 'InnoDB';
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('post_id');
            $table->uuid('member_id');
            $table->timestamp('last_read_at')->nullable();
            $table->boolean('muted')->default(false);
            $table->timestamps();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('post_id')->references('id')->on('posts');
            $table->foreign('member_id')->references('id')->on('club_members');
            $table->unique(['post_id', 'member_id']);
            $table->index('member_id');
        });

        Schema::table('posts', function (Blueprint $table) {
            $table->timestamp('comments_closed_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            $table->dropColumn('comments_closed_at');
        });
        Schema::dropIfExists('post_thread_states');
        Schema::dropIfExists('post_comments');
    }
};
