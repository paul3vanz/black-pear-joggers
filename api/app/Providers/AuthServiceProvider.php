<?php

namespace App\Providers;

use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;
use Auth0\SDK\Configuration\SdkConfiguration;
use Auth0\SDK\Token;
use Illuminate\Auth\GenericUser;

class AuthServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        //
    }

    /**
     * Boot the authentication services for the application.
     *
     * @return void
     */
    public function boot()
    {
        // Here you may define how you wish users to be authenticated for your Lumen
        // application. The callback which receives the incoming request instance
        // should return either a User instance or null. You're free to obtain
        // the User instance via an API token or any other method necessary.

        $this->app['auth']->viaRequest('api', function ($request) {
            $bearerToken = $request->bearerToken();

            if ($bearerToken) {

                $jwksUri = env('AUTH0_DOMAIN') . '.well-known/jwks.json';

                $configuration = new SdkConfiguration([
                    'domain' => env('AUTH0_DOMAIN'),
                    'clientId' => env('AUTH0_CLIENT_ID'),
                    'audience' => [ env('AUTH0_AUDIENCE') ],
                    'clientSecret' => env('AUTH0_CLIENT_SECRET'),
                    'tokenAlgorithm' => 'HS256'
                ]);

                $tokenVerifier = new Token($configuration, $bearerToken, 2);

                $decoded = $tokenVerifier->verify()->validate()->toArray();

                return new GenericUser($decoded);
            }
        });
    }
}