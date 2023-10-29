<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use Illuminate\Support\Facades\Artisan;

class PaymentsController extends Controller
{
    /**
     * Create a new controller instance.
     *
     * @return void
     */
    public function __construct() {

    }

    public function getPayments() {
        $payments = Payment::query()->get()->all();
        return response()->json($payments);
    }

    public function getPayment($id) {
        $payment = Payment::query()->find($id);
        return response()->json($payment);
    }

    public function deletePayment($id) {
        $payment = Payment::query()->find($id);
        return response()->json($payment);
    }
}
