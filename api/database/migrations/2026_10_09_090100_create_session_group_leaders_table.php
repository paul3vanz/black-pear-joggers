<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Who leads a group. A withdrawn row is kept (status) and is re-confirmed if the
 * member joins again, which the unique key makes the only possible shape.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('session_group_leaders', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('group_id');
            $table->uuid('member_id');
            $table->string('role', 16)->default('leader'); // leader | co_leader | backmarker
            $table->string('status', 16)->default('confirmed'); // confirmed | withdrawn
            $table->timestamp('withdrawn_at')->nullable();
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
        Schema::dropIfExists('session_group_leaders');
    }
};
