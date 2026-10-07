<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The weekly pattern behind club runs ("Monday club run, 19:00"). Concrete
 * dated runs are generated from it into `sessions`.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('session_series', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('id')->primary();
            $table->unsignedInteger('club_id');
            $table->string('title');
            $table->text('description')->nullable();
            $table->uuid('venue_id')->nullable();
            $table->unsignedTinyInteger('weekday'); // ISO: 1 = Monday ... 7 = Sunday
            $table->time('start_time'); // club-local
            $table->unsignedSmallInteger('duration_min');
            $table->unsignedTinyInteger('interval_weeks')->default(1);
            $table->date('valid_from');
            $table->date('valid_until')->nullable();
            $table->string('group_mode', 16); // paced | single | open | routes
            $table->string('cms_slug', 100)->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('venue_id')->references('id')->on('venues');
            $table->index(['club_id', 'updated_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('session_series');
    }
};
