<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * One member's photo (a small JPEG), in its own table so that ordinary profile reads
 * never load the blob. The row is deleted when the photo is removed.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('member_photos', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->uuid('member_id')->primary();
            $table->unsignedInteger('club_id');
            $table->binary('image'); // widened to MEDIUMBLOB below (this Laravel has no mediumBinary)
            $table->timestamps();

            $table->foreign('club_id')->references('id')->on('clubs');
            $table->foreign('member_id')->references('id')->on('club_members');
        });

        // A plain BLOB holds only 64 KB and photos can be 400 KB. (SQLite's BLOB has no such limit.)
        if (DB::connection()->getDriverName() === 'mysql') {
            DB::statement('alter table `member_photos` modify `image` mediumblob not null');
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('member_photos');
    }
};
