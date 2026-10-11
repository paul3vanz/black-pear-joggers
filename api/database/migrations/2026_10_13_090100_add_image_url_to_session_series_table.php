<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * An optional picture for a series, shown above each run card. A URL, not an
 * upload. Not indexed (varchar 500 would break the host's key length limit).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('session_series', function (Blueprint $table) {
            $table->string('image_url', 500)->nullable()->after('cms_slug');
        });
    }

    public function down(): void
    {
        Schema::table('session_series', function (Blueprint $table) {
            $table->dropColumn('image_url');
        });
    }
};
