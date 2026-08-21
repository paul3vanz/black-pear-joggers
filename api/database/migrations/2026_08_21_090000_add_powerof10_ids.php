<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Power of 10 rebuilt their site and moved from integer athlete/meeting ids to
 * GUIDs. Rather than replace athlete_id (which is the primary key and is
 * referenced by performances, rankings, magicmiles and the public API), we add
 * the new identifiers alongside the old ones so the migration can run
 * incrementally and existing relationships stay intact.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('athletes', function (Blueprint $table) {
            $table->uuid('po10_guid')->nullable()->after('athlete_id');
            $table->index('po10_guid');
        });

        Schema::table('meetings', function (Blueprint $table) {
            $table->uuid('po10MeetingId')->nullable()->after('ukaMeetingId');
            $table->index('po10MeetingId');
        });
    }

    public function down(): void
    {
        Schema::table('athletes', function (Blueprint $table) {
            $table->dropIndex(['po10_guid']);
            $table->dropColumn('po10_guid');
        });

        Schema::table('meetings', function (Blueprint $table) {
            $table->dropIndex(['po10MeetingId']);
            $table->dropColumn('po10MeetingId');
        });
    }
};
