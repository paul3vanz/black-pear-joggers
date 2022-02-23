<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;
use Stripe\StripeClient;

class CheckoutController extends Controller
{
    /**
     * Create a new controller instance.
     *
     * @return void
     */
    public function __construct()
    {
    }

    public function createSession(Request $request)
    {
        $namePrinting = $request->input('namePrinting');

        $stripe = new StripeClient(env('STRIPE_API_KEY'));
        $response = $stripe->checkout->sessions->create([
            'success_url' => 'https://bpj.org.uk/kit/order-successful/',
            'cancel_url' => 'https://my.bpj.org.uk/kit/',
            'line_items' => [
                [
                    'price' => $request->input('priceId'),
                    'quantity' => $request->input('quantity'),
                ],
                $namePrinting ? [
                    'price_data' => [
                        'currency' => 'gbp',
                        'unit_amount' => 200,
                        'product_data' => [
                            'name' => 'Print: ' . $namePrinting,
                        ],
                    ],
                    'quantity' => 1,
                ] : null,
            ],
            'mode' => 'payment',
        ]);

        return response()->json($response);
    }
}
