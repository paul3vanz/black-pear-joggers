<?php

namespace App\Events;

use App\Models\Payment;

class PaymentUpdateReceived extends Event
{
    /**
     * Create a new event instance.
     *
     * @return void
     */
    public function __construct(
        public Payment $payment
    ) {}
}
