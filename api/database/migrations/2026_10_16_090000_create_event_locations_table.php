<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Phase 8: the club's list of places people run events at (parkruns, races, other).
 * parkrun rows come from an import of parkrun's public events file; races are added by members.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('event_locations', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->string('kind', 16); // parkrun | race | other
            $table->string('name', 120);
            $table->string('slug', 80)->nullable(); // parkrun site code, e.g. worcester
            $table->char('country', 2)->nullable();
            $table->string('region', 80)->nullable();
            $table->decimal('lat', 9, 6)->nullable();
            $table->decimal('lng', 9, 6)->nullable();
            $table->string('url')->nullable();
            $table->string('source', 16)->default('manual'); // import | manual
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->index(['club_id', 'updated_at']);
            $table->index(['club_id', 'kind', 'slug']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('event_locations');
    }
};
