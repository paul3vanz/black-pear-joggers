<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Account deletion (Phase 7b): a deleted member's club posts stay, with no
 * author, so the reference must be allowed to be null. The foreign key stays.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            $table->uuid('author_member_id')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            $table->uuid('author_member_id')->nullable(false)->change();
        });
    }
};
