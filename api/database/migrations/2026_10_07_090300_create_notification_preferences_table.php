<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Per-member opt-ins/outs. A missing row means "use the category default".
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notification_preferences', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('member_id');
            $table->string('category', 32);
            $table->boolean('push_enabled')->default(true);
            $table->timestamps();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('member_id')->references('id')->on('club_members');
            $table->unique(['member_id', 'category']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notification_preferences');
    }
};
