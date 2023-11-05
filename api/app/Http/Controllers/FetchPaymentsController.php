<?php

namespace App\Http\Controllers;

use App\Jobs\FetchRankingsJob;
use App\Models\Payment;
use GuzzleHttp\Client as GuzzleClient;
use Illuminate\Support\Facades\Artisan;
use DB;
use Log;
use DateTime;

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
        $fetchUrl = env('MYATHLETICS_PORTAL_BASE_URL') . env('MYATHLETICS_PORTAL_LOGIN_URL');

        $loginPost = $this->client->post($fetchUrl, array(
            'form_params' => [
                'Username' => env('MYATHLETICS_PORTAL_USERNAME'),
                'Password' => env('MYATHLETICS_PORTAL_PASSWORD'),
            ]
        ));

        $membershipPaymentsResponse = $this->client->post(env('MYATHLETICS_PORTAL_BASE_URL') . env('MYATHLETICS_PORTAL_EXPORT_MEMBERSHIP_PAYMENTS_URL'));

        $csv = str_getcsv(($membershipPaymentsResponse->getBody()));

        // Local debug to avoid fetch each time
        // $filename = './membership-payments.csv';
        // $csv = fread(fopen($filename, 'r'), filesize($filename));

        $membershipPayments = $this->parseCsv($csv);

        foreach ($membershipPayments as $membershipPayment) {
            $existingPayment = Payment::where('urn', $membershipPayment['URN'])->first();

            if ($existingPayment) {
                if ($existingPayment->paymentStatus !== $membershipPayment['PaymentStatus']) {
                    Log::channel('slackInfo')->info('Payment status changed ' . $membershipPayment['URN'] . ' ' . $membershipPayment['Firstname'] . ' ' . $membershipPayment['Lastname'] . ' = From ' . $existingPayment->paymentStatus . ' To ' . $membershipPayment['PaymentStatus']);
                } else {

                }
            } else {
                Log::channel('slackInfo')->info('New payment record found' . $membershipPayment['URN'] . ' ' . $membershipPayment['Firstname'] . ' ' . $membershipPayment['Lastname'] . ' = ' . $membershipPayment['PaymentStatus']);

                // Fire event so that athlete record can be added
            }

            Payment::updateOrCreate([
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
