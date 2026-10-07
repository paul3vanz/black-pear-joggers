<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The in-app inbox. Push only nudges; the message stays here to read.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('member_id');
            $table->string('category', 32);
            $table->string('title');
            $table->text('body');
            $table->json('data')->nullable(); // deep link: { route: ... }
            $table->timestamp('read_at')->nullable();
            $table->timestamp('pushed_at')->nullable();
            $table->timestamps();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('member_id')->references('id')->on('club_members');
            $table->index(['member_id', 'club_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
