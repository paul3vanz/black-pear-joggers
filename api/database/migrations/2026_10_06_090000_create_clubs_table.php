<?php

use Illuminate\Support\Carbon;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Clubs for the members' app. Every new app table is scoped to a club; BPJ is
 * club 1 and is the only one for now.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('clubs', function (Blueprint $table) {
            $table->engine = 'InnoDB'; // MyISAM (some hosts default) ignores FKs and transactions
            $table->increments('id');
            $table->string('name');
            $table->string('slug', 64)->unique();
            $table->integer('ea_club_id')->nullable();
            $table->string('timezone', 64)->default('Europe/London');
            $table->string('join_url')->nullable();
            $table->json('settings')->nullable();
            $table->timestamps();
        });

        DB::table('clubs')->insert([
            'id' => 1,
            'name' => 'Black Pear Joggers',
            'slug' => 'bpj',
            'ea_club_id' => 1606,
            'timezone' => 'Europe/London',
            'join_url' => 'https://bpj.org.uk/membership',
            'created_at' => Carbon::now(),
            'updated_at' => Carbon::now(),
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('clubs');
    }
};
