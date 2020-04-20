<?php

namespace App\GraphQL\InputObject;

use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\InputType;
use Rebing\GraphQL\Support\Facades\GraphQL;

class PerformanceFilterInput extends InputType
{
  protected $attributes = [
    'name' => 'PerformanceFilter',
    'description' => 'Filter performances',
  ];

  public function fields(): array
  {
    return [
      'athleteId' => [
        'type' => GraphQL::type('StringFilter'),
      ],
      'race' => [
        'type' => GraphQL::type('StringFilter'),
      ],
      'date' => [
        'type' => GraphQL::type('DateFilter'),
      ],
      'isPersonalBest' => [
        'type' => Type::int(),
      ],
    ];
  }
}
