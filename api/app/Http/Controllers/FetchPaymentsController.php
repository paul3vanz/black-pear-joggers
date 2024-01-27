<?php

namespace App\Http\Controllers;

use App\Events\PaymentUpdateReceived;
use App\Jobs\FetchRankingsJob;
use App\Models\Payment;
use GuzzleHttp\Client as GuzzleClient;
use Illuminate\Support\Facades\Artisan;
use DB;
use Log;
use DateTime;
use Illuminate\Support\Facades\Event;

class FetchPaymentsController extends Controller
{
    private $client;

    public function __construct()
    {
        $this->client = new GuzzleClient([
            'cookies' => true,
        ]);
    }

    public function fetchPayments()
    {
        Log::info('fetchPayments executed');

        $fetchUrl = env('MYATHLETICS_PORTAL_BASE_URL') . env('MYATHLETICS_PORTAL_LOGIN_URL');

        $loginPost = $this->client->post($fetchUrl, array(
            'form_params' => [
                'Username' => env('MYATHLETICS_PORTAL_USERNAME'),
                'Password' => env('MYATHLETICS_PORTAL_PASSWORD'),
            ]
        ));

        $membershipPaymentsResponse = $this->client->post(env('MYATHLETICS_PORTAL_BASE_URL') . env('MYATHLETICS_PORTAL_EXPORT_MEMBERSHIP_PAYMENTS_URL'));

        $csv = $membershipPaymentsResponse->getBody();

        // Local debug to avoid fetch each time
        // $filename = './membership-payments.csv';
        // $csv = fread(fopen($filename, 'r'), filesize($filename));

        $membershipPayments = $this->parseCsv($csv);

        if (!count($membershipPayments)) {
            Log::info('No payments found');
        } else {
            Log::info('Payments found', [ 'total' => count($membershipPayments)]);
        }

        foreach ($membershipPayments as $membershipPayment) {
            $existingPayment = Payment::where('urn', $membershipPayment['URN'])->first();

            if ($existingPayment) {
                if ($existingPayment->paymentStatus !== $membershipPayment['PaymentStatus']) {
                    Log::info('Payment status changed', [
                        'urn' => $membershipPayment['URN'],
                        'firstName' => $membershipPayment['Firstname'],
                        'lastName' => $membershipPayment['Lastname'],
                        'previousPaymentStatus' => $existingPayment->paymentStatus,
                        'newPaymentStatus' =>$membershipPayment['PaymentStatus']
                    ]);
                } else {

                }
            } else {
                Log::info('New payment record found', [
                    'urn' => $membershipPayment['URN'],
                    'firstName' => $membershipPayment['Firstname'],
                    'lastName' => $membershipPayment['Lastname'],
                    'newPaymentStatus' =>$membershipPayment['PaymentStatus']
                ]);

                // Eventually move event to fire here to trigger only when new payments are found to limit events
            }

            $payment = Payment::updateOrCreate([
                'urn' => $membershipPayment['URN'],
            ], [
                'firstname' => $membershipPayment['Firstname'],
                'lastname' => $membershipPayment['Lastname'],
                'dob' => $this->convertDate($membershipPayment['DOB']),
                'amount' => $membershipPayment['Amount'],
                'paymentStatus' => $membershipPayment['PaymentStatus'],
                'email' => $membershipPayment['Email'],
                'paymentType' => 'Membership',
                'reference' => $membershipPayment['Reference'],
                'paymentMethod' => $membershipPayment['PaymentMethod'],
                'datePaid' => $membershipPayment['DatePaid'] ? $this->convertDate($membershipPayment['DatePaid']) : null,
                'membershipType' => $membershipPayment['MembershipType'],
            ]);

            // Fire event here so we can store all currently unknown athletes in the athletes table
            Event::dispatch(new PaymentUpdateReceived($payment));
        }

        return $membershipPayments;
    }

    private function parseCsv($csv) {
        $csvRows = str_getcsv($csv, "\n");

        $csvArray = array_map('str_getcsv', $csvRows);

        $csvHeaders = $csvArray[0];

        array_walk($csvArray, function (&$row) use ($csvHeaders) {
            $row = array_combine($csvHeaders, $row);
        });

        array_shift($csvArray);

        return $csvArray;
    }

    private function convertDate($date) {
        return implode("-", array_reverse(explode("/", $date)));
    }
}
