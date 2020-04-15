<?php

namespace App\GraphQL\InputObject;

use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\InputType;
use Rebing\GraphQL\Support\Facades\GraphQL;

class AthleteFilterInput extends InputType
{
  protected $attributes = [
    'name' => 'AthleteFilter',
    'description' => 'Filter athletes',
  ];

  public function fields(): array
  {
    return [
      'firstName' => [
        'alias' => 'first_name',
        'type' => GraphQL::type('StringFilter'),
      ],
      'lastName' => [
        'alias' => 'last_name',
        'type' => GraphQL::type('StringFilter'),
      ],
    ];
  }
}
