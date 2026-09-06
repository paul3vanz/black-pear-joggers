<?php

namespace App\Http\Controllers;

use Laravel\Lumen\Routing\Controller as BaseController;

/**
 * @OA\Info(
 *   title="Black Pear Joggers API",
 *   version="0.1",
 *   @OA\Contact(
 *     email="paul3vanz@gmail.com",
 *     name="Paul Evans",
 *     url="https://bpj.org.uk"
 *   )
 * )
 * @OA\SecurityScheme(
 *   securityScheme="bearerAuth",
 *   type="http",
 *   scheme="bearer",
 *   bearerFormat="JWT"
 * )
 */
class Controller extends BaseController
{
    //
}
