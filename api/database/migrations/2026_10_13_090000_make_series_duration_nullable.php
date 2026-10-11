<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A run's length is optional (many club runs have no fixed end). null = no
 * end time shown; sessions still end 3 hours after the start internally.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('session_series', function (Blueprint $table) {
            $table->unsignedSmallInteger('duration_min')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('session_series', function (Blueprint $table) {
            $table->unsignedSmallInteger('duration_min')->nullable(false)->change();
        });
    }
};
