<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Phase 5: one inbox row per member per piece of news (dedupe_key), and when a
 * push was last queued for it (push_requested_at, used by the daily cap and
 * the re-push window).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->string('dedupe_key', 80)->nullable()->after('data');
            $table->timestamp('push_requested_at')->nullable()->after('pushed_at');

            // char(36) 144 bytes + varchar(80) 320 bytes: well under 767
            $table->index(['member_id', 'dedupe_key']);
        });
    }

    public function down(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->dropIndex(['member_id', 'dedupe_key']);
            $table->dropColumn(['dedupe_key', 'push_requested_at']);
        });
    }
};
