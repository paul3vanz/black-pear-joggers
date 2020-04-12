<?php

namespace App\GraphQL\Enums;

use Rebing\GraphQL\Support\EnumType;

class CategoryEnum extends EnumType
{
  protected $attributes = [
    'name' => 'Category',
    'description' => 'The age category of an athlete',
    'values' => [
      'U20' => 'U20',
      'U23' => 'U23',
      'SEN' => 'SEN',
      'V35' => 'V35',
      'V40' => 'V40',
      'V45' => 'V45',
      'V50' => 'V50',
      'V55' => 'V55',
      'V60' => 'V60',
      'V65' => 'V65',
      'V70' => 'V70',
    ],
  ];
}
