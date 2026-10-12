<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A member's profile card for one club: short bio, private-by-default goals and the
 * version of their photo (the image itself is in member_photos). No row means nothing
 * has ever been saved.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('member_profiles', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('member_id');
            $table->string('bio', 300)->nullable();
            $table->text('goals')->nullable();
            $table->boolean('goals_visible')->default(false);
            $table->char('photo_version', 8)->nullable(); // random per upload; part of the signed link
            $table->timestamp('photo_updated_at')->nullable();
            $table->timestamps();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('member_id')->references('id')->on('club_members');
            $table->unique('member_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('member_profiles');
    }
};
