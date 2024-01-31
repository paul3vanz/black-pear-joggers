<?php

namespace App\Listeners;

use Log;
use App\Events\PaymentUpdateReceived;
use App\Models\Athlete;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Contracts\Queue\ShouldQueue;

class PaymentUpdateReceivedHandler
{
    /**
     * Create the event listener.
     *
     * @return void
     */
    public function __construct()
    {
        //
    }

    /**
     * Handle the event.
     *
     * @param  PaymentUpdateReceived  $event
     * @return void
     */
    public function handle(PaymentUpdateReceived $event)
    {
        Log::info('handler: payment update', $event->payment);

        // Check for matching URN
        $athlete = Athlete::find($event->payment['urn']);

        if (!$athlete) {
            // If not found, insert athlete
            Athlete::create([
                // 'id' => $request->input('id'),
                'urn' => $event->payment['urn'],
                'athlete_id' => null,
                'first_name' => $event->payment['firstname'],
                'last_name' => $event->payment['lastname'],
                'gender' => null,
                'dob' => $event->payment['dob']
            ]);
        }

    }
}
