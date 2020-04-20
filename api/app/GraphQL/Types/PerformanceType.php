<?php

namespace App\GraphQL\Types;

use App\Models\Performance;
use Rebing\GraphQL\Support\Facades\GraphQL;
use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\Type as GraphQLType;

class PerformanceType extends GraphQLType
{
  protected $attributes = [
    'name' => 'Performance',
    'description' => 'Details about a performance',
    'model' => Performance::class
  ];

  public function fields(): array
  {
    return [
      'id' => [
        'type' => Type::nonNull(Type::int()),
        'description' => 'Unique ID of the performance',
      ],
      'athleteId' => [
        'alias' => 'athlete_id',
        'type' => Type::nonNull(Type::int()),
        'description' => 'The athlete unique ID',
      ],
      'category' => [
        'alias' => 'category',
        'type' => Type::nonNull(GraphQL::type('CategoryEnum')),
        'description' => 'The age category of the performance',
      ],
      'meetingId' => [
        'alias' => 'meeting_id',
        'type' => Type::nonNull(Type::int()),
        'description' => 'Unique ID of the event',
      ],
      'event' => [
        'alias' => 'event',
        'type' => Type::nonNull(Type::string()),
        'description' => 'The type of event',
      ],
      'time' => [
        'alias' => 'time',
        'type' => Type::nonNull(Type::string()),
        'description' => 'The formatted finish time',
      ],
      'timeParsed' => [
        'alias' => 'time_parsed',
        'type' => Type::nonNull(Type::int()),
        'description' => 'The finish time in seconds',
      ],
      'race' => [
        'type' => Type::nonNull(Type::string()),
        'description' => 'The name of the race or event',
      ],
      'date' => [
        'type' => Type::nonNull(Type::string()),
        'description' => 'The date the performance took place',
      ],
      'manual' => [
        'type' => Type::nonNull(Type::boolean()),
        'description' => 'Whether the performance was manually added',
      ],
      'isPersonalBest' => [
        'type' => Type::nonNull(Type::boolean()),
        'description' => 'Was this performance a personal best at the time',
      ],
      'athlete' => [
        'type' => GraphQL::type('Athlete'),
        'description' => 'Details of the athlete',
      ],
      'eventDetails' => [
        'type' => GraphQL::type('Event'),
        'description' => 'Details of the event type',
      ]
    ];
  }
}
