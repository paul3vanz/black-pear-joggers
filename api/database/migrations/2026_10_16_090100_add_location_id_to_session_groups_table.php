<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Phase 8: an event group points at the event location it was made from (optional;
 * the group keeps its own label even if the location is later removed).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('session_groups', function (Blueprint $table) {
            $table->char('location_id', 36)->nullable()->after('created_by_member_id');
            $table->foreign('location_id')->references('id')->on('event_locations');
            $table->index('location_id');
        });
    }

    public function down(): void
    {
        Schema::table('session_groups', function (Blueprint $table) {
            $table->dropForeign(['location_id']);
            $table->dropIndex(['location_id']);
            $table->dropColumn('location_id');
        });
    }
};
