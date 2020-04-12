<?php

namespace App\GraphQL\Enums;

use Rebing\GraphQL\Support\EnumType;

class GenderEnum extends EnumType
{
  protected $attributes = [
    'name' => 'Gender',
    'description' => 'The gender of an athlete',
    'values' => [
      'M' => 'M',
      'W' => 'W',
    ],
  ];
}
