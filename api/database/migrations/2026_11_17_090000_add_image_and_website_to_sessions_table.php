<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A single run may have its own picture (overrides the series image; ad-hoc runs have no series)
 * and a website link (races: where to read about and enter). Both http(s) URLs stored as
 * entered, not indexed, so the length is not limited by key size.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sessions', function (Blueprint $table) {
            $table->string('image_url', 500)->nullable();
            $table->string('website_url', 500)->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('sessions', function (Blueprint $table) {
            $table->dropColumn(['image_url', 'website_url']);
        });
    }
};
