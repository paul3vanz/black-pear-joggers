<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

/**
 * Manual award claims are being reinstated in claim-award, submitted by a
 * logged-in athlete instead of anonymously. We need to know which athlete a
 * claim belongs to, and a real per-claim secret so a certificate link
 * (GET /awardclaim/{id}/{token}) can be shared/viewed without every claim
 * being readable by guessing sequential ids.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('awardClaim', function (Blueprint $table) {
            $table->unsignedBigInteger('athleteId')->nullable()->after('id');
            $table->uuid('token')->nullable()->after('athleteId');
            $table->index('athleteId');
        });

        DB::table('awardClaim')->whereNull('token')->orderBy('id')->pluck('id')
            ->each(function ($id) {
                DB::table('awardClaim')->where('id', $id)->update(['token' => (string) Str::uuid()]);
            });

        Schema::table('awardClaim', function (Blueprint $table) {
            $table->unique('token');
        });
    }

    public function down(): void
    {
        Schema::table('awardClaim', function (Blueprint $table) {
            $table->dropUnique(['token']);
            $table->dropIndex(['athleteId']);
            $table->dropColumn(['token', 'athleteId']);
        });
    }
};
