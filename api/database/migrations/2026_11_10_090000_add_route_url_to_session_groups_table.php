<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A group may link to its route (usually plotaroute.com, but any http(s) URL). The full
 * URL is stored as entered; it is not indexed, so the length is not limited by key size.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('session_groups', function (Blueprint $table) {
            $table->string('route_url', 500)->nullable()->after('description');
        });
    }

    public function down(): void
    {
        Schema::table('session_groups', function (Blueprint $table) {
            $table->dropColumn('route_url');
        });
    }
};
