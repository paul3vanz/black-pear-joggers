<?php

namespace App\GraphQL\Types;

use App\Models\Award;
use Rebing\GraphQL\Support\Facades\GraphQL;
use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\Type as GraphQLType;

class AwardType extends GraphQLType
{
  protected $attributes = [
    'name' => 'Award',
    'description' => 'Details about an Award',
    'model' => Award::class
  ];

  public function fields(): array
  {
    return [
      'id' => [
        'type' => Type::nonNull(Type::int()),
        'description' => 'Unique identifier',
      ],
      'name' => [
        'type' => Type::nonNull(Type::string()),
        'description' => 'Name of the award',
      ],
      'standards' => [
        'type' => Type::listOf(GraphQL::type('Standard')),
        'description' => 'Standards for the award',
      ],
    ];
  }
}
