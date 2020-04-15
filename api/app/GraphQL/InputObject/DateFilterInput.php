<?php

namespace App\GraphQL\InputObject;

use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\InputType;

class DateFilterInput extends InputType
{
  protected $attributes = [
    'name' => 'DateFilter',
    'description' => 'Filter date values',
  ];

  public function fields(): array
  {
    return [
      'lt' => [
        'type' => Type::string(),
      ],
      'lte' => [
        'type' => Type::string(),
      ],
      'gt' => [
        'type' => Type::string(),
      ],
      'gte' => [
        'type' => Type::string(),
      ],
      'equals' => [
        'type' => Type::string(),
      ],
      'notEquals' => [
        'type' => Type::string(),
      ],
      'contains' => [
        'type' => Type::string(),
      ],
      'startsWith' => [
        'type' => Type::string(),
      ],
    ];
  }
}
