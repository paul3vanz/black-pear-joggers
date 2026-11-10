<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Routes set for one run (e.g. a 10 mile and a 14 mile route for a long run). A group
 * picks one with session_groups.route_id instead of giving its own route_url.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('session_routes', function (Blueprint $table) {
            $table->engine = 'InnoDB';
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->uuid('session_id');
            $table->string('label', 80);
            $table->string('url', 500);
            $table->decimal('distance_value', 6, 2)->nullable();
            $table->char('distance_unit', 2)->nullable(); // mi | km
            $table->smallInteger('sort_order')->default(0);
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('session_id')->references('id')->on('sessions');
            $table->index('session_id');
        });

        Schema::table('session_groups', function (Blueprint $table) {
            $table->char('route_id', 36)->nullable()->after('route_url');
            $table->foreign('route_id')->references('id')->on('session_routes');
            $table->index('route_id');
        });
    }

    public function down(): void
    {
        Schema::table('session_groups', function (Blueprint $table) {
            $table->dropForeign(['route_id']);
            $table->dropIndex(['route_id']);
            $table->dropColumn('route_id');
        });

        Schema::dropIfExists('session_routes');
    }
};
