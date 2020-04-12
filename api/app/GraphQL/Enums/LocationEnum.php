<?php

namespace App\GraphQL\Enums;

use Rebing\GraphQL\Support\EnumType;

class LocationEnum extends EnumType
{
  protected $attributes = [
    'name' => 'Location',
    'description' => 'The location of the performance',
    'values' => [
      'Magic Mile (Diglis Bridge)' => 'Magic Mile (Diglis Bridge)',
      'Magic Mile (Grandstand, Pitchcroft)' => 'Magic Mile (Grandstand, Pitchcroft)',
      'Magic Mile (Grandstand)' => 'Magic Mile (Grandstand)',
      'Magic Mile (Pitchcroft Reverse)' => 'Magic Mile (Pitchcroft Reverse)',
      'Magic Mile (Wainwright Road)' => 'Magic Mile (Wainwright Road)',
    ],
  ];
}
