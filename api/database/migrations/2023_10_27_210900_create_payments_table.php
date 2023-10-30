<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class CreatePaymentsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('payments', function (Blueprint $table) {

            $table->integer('urn')->unsigned();
            $table->string('firstname', 100);
            $table->string('lastname', 100);
            $table->date('dob');
            $table->float('amount', 8, 2);
            $table->string('paymentStatus', 50); // Affiliation = Paid/PaymentSent/Outstanding. Membership = Paid/Requested
            $table->string('email', 100);

            $table->string('paymentType', 50); // Affiliation or Membership

            $table->string('reference')->unique(); // Stripe reference
            $table->string('paymentMethod', 50)->nullable(); // Stripe
            $table->date('datePaid')->nullable();
            $table->string('membershipType', 100); // Basic, affiliated, etc

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
        Schema::dropIfExists('payments');
    }
}
