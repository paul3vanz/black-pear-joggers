<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A committee ask can name the people it is for and what it is looking for (D127).
 *
 *  - ask_member_ids: JSON array of the member ids the ask went to. Null for an ask
 *    to the computed audience (the older form).
 *  - ask_kind: `jog_walk` when the ask is for a jog/walk group, else null. A pace
 *    stretch is still ask_fast_s_per_km to ask_slow_s_per_km.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('leader_messages', function (Blueprint $table) {
            $table->json('ask_member_ids')->nullable()->after('ask_slow_s_per_km');
            $table->string('ask_kind', 16)->nullable()->after('ask_member_ids');
        });
    }

    public function down(): void
    {
        Schema::table('leader_messages', function (Blueprint $table) {
            $table->dropColumn(['ask_member_ids', 'ask_kind']);
        });
    }
};
