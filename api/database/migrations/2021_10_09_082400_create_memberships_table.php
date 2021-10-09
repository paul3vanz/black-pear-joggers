<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class CreateMembershipsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('memberships', function (Blueprint $table) {            
            $table->integer('urn');
            $table->string('firstName', 100);
            $table->string('lastName', 100);
            $table->string('dob');
            $table->string('gender');
            $table->string('foreignFlag');
            $table->string('competitiveRegStatus', 50);
            $table->integer('firstClaimClubId')->nullable();
            $table->string('firstClaimClubName')->nullable();
            $table->integer('firstClaimOtherId')->nullable();
            $table->string('firstClaimOtherName')->nullable();
            $table->integer('higherClaimClubId')->nullable();
            $table->string('higherClaimClubName')->nullable();
            $table->integer('secondClaimClubId')->nullable();
            $table->string('secondClaimClubName')->nullable();
            $table->primary('urn');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('memberships');
    }
}
