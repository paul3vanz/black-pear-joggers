<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class UpdateMagicMileTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('magicmile', function (Blueprint $table) {
            $table->dropColumn('predicted_time');
            $table->dropColumn('actual_time');
            $table->renameColumn('predicted_time_parsed', 'predictedTime');
            $table->renameColumn('actual_time_parsed', 'actualTime');
            $table->renameColumn('athlete_id', 'athleteId');
            $table->renameColumn('first_name', 'firstName');
            $table->renameColumn('last_name', 'lastName');
            $table->renameColumn('created_at', 'createdDate');
            $table->renameColumn('updated_at', 'updatedDate');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {

    }
}
