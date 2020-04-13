<?php

namespace App\GraphQL\Types;

use App\Models\Event;
use Rebing\GraphQL\Support\Facades\GraphQL;
use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\Type as GraphQLType;

class EventType extends GraphQLType
{
  protected $attributes = [
    'name' => 'Event',
    'description' => 'Details about an event',
    'model' => Event::class
  ];

  public function fields(): array
  {
    return [
      'id' => [
        'type' => Type::nonNull(Type::int()),
        'description' => 'Unique identifier',
      ],
      'event' => [
        'type' => Type::nonNull(Type::string()),
        'description' => 'Name of the event',
      ],
      'distance' => [
        'type' => Type::nonNull(Type::float()),
        'description' => 'Distance in metres',
      ],
      'alias' => [
        'type' => Type::nonNull(Type::string()),
        'description' => 'Alternative names',
      ],
      'hasStandard' => [
        'alias' => 'has_standard',
        'type' => Type::nonNull(Type::boolean()),
        'description' => 'Whether the event is included in club standards awards',
      ],
      'standards' => [
        'type' => Type::listOf(GraphQL::type('Standard')),
        'description' => 'Standards for the event',
      ],
    ];
  }
}
