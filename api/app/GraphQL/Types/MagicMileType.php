<?php

namespace App\GraphQL\Types;

use App\Models\MagicMile;
use Rebing\GraphQL\Support\Facades\GraphQL;
use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\Type as GraphQLType;

class MagicMileType extends GraphQLType
{
  protected $attributes = [
    'name' => 'MagicMile',
    'description' => 'Details about a magic mile performance',
    'model' => MagicMile::class
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
        'type' => Type::int(),
        'description' => 'Unique ID of the performance',
      ],
      'firstName' => [
        'alias' => 'first_name',
        'type' => Type::nonNull(Type::string()),
        'description' => 'The athlete first name',
      ],
      'lastName' => [
        'alias' => 'last_name',
        'type' => Type::nonNull(Type::string()),
        'description' => 'The athlete last name',
      ],
      'gender' => [
        'type' => Type::nonNull(GraphQL::type('GenderEnum')),
        'description' => 'The athlete gender',
      ],
      'category' => [
        'type' => Type::nonNull(GraphQL::type('CategoryEnum')),
        'description' => 'The athlete age category',
      ],
      'date' => [
        'type' => Type::nonNull(Type::string()),
        'description' => 'The date of the performance',
      ],
      'location' => [
        'type' => Type::nonNull(GraphQL::type('LocationEnum')),
        'description' => 'The location of the performance',
      ],
      'predictedTime' => [
        'alias' => 'predicted_time',
        'type' => Type::string(),
        'description' => 'Predicted time in user friendly string',
      ],
      'predictedTimeParsed' => [
        'alias' => 'predicted_time_parsed',
        'type' => Type::int(),
        'description' => 'Predicted time in seconds',
      ],
      'actualTime' => [
        'alias' => 'actual_time',
        'type' => Type::nonNull(Type::string()),
        'description' => 'Actual time in user friendly string',
      ],
      'actualTimeParsed' => [
        'alias' => 'actual_time_parsed',
        'type' => Type::nonNull(Type::int()),
        'description' => 'Actual time in seconds',
      ],
    ];
  }
}
