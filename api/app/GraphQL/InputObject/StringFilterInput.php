<?php

namespace App\GraphQL\InputObject;

use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\InputType;

class StringFilterInput extends InputType
{
  protected $attributes = [
    'name' => 'StringFilter',
    'description' => 'Filter string values',
  ];

  public function fields(): array
  {
    return [
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
