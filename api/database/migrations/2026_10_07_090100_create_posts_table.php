<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Club updates published by the committee.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('posts', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('author_member_id');
            $table->string('title');
            $table->text('body_md');
            $table->string('priority', 16)->default('normal'); // normal | important
            $table->string('audience', 16)->default('all'); // all | leaders | committee
            $table->timestamp('published_at')->nullable();
            $table->timestamp('pinned_until')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('author_member_id')->references('id')->on('club_members');
            $table->index(['club_id', 'updated_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('posts');
    }
};
