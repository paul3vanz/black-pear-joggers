<?php

namespace App\GraphQL\Types;

use App\Models\Standard;
use Rebing\GraphQL\Support\Facades\GraphQL;
use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\Type as GraphQLType;

class StandardType extends GraphQLType
{
  protected $attributes = [
    'name' => 'Standard',
    'description' => 'Details about a club standard',
    'model' => Standard::class
  ];

  public function fields(): array
  {
    return [
      'gender' => [
        'type' => Type::string(),
        'description' => '',
      ],
      'category' => [
        'type' => Type::string(),
        'description' => '',
      ],
      'eventId' => [
        'alias' => 'event_id',
        'type' => Type::int(),
        'description' => '',
      ],
      'awardId' => [
        'alias' => 'award_id',
        'type' => Type::int(),
        'description' => '',
      ],
      'time' => [
        'type' => Type::string(),
        'description' => '',
      ],
      'timeParsed' => [
        'alias' => 'time_parsed',
        'type' => Type::int(),
        'description' => '',
      ],
      'award' => [
        'type' => GraphQL::type('Award'),
        'description' => '',
      ],
      'event' => [
        'type' => GraphQL::type('Event'),
        'description' => '',
      ],
    ];
  }
}
