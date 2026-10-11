<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * false = the run has no stated end time. ends_at is still filled (start + 3 h)
 * so every "has it ended" rule keeps working; has_end only hides it in payloads.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sessions', function (Blueprint $table) {
            $table->boolean('has_end')->default(true)->after('local_end_time');
        });
    }

    public function down(): void
    {
        Schema::table('sessions', function (Blueprint $table) {
            $table->dropColumn('has_end');
        });
    }
};
