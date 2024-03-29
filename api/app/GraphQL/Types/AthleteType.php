<?php

namespace App\GraphQL\Types;

use Log;
use App\Models\Athlete;
use Rebing\GraphQL\Support\Facades\GraphQL;
use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\Type as GraphQLType;

class AthleteType extends GraphQLType
{
  protected $attributes = [
    'name' => 'Athlete',
    'description' => 'Details about an athlete',
    'model' => Athlete::class
  ];

  public function fields(): array
  {
    return [
      'id' => [
        'type' => Type::nonNull(Type::int()),
        'description' => 'Unique identifier',
      ],
      'urn' => [
        'type' => Type::nonNull(Type::int()),
        'description' => 'England Athletics registration number',
      ],
      'athleteId' => [
        'alias' => 'athlete_id',
        'type' => Type::nonNull(Type::int()),
        'description' => 'Unique identifier on Power of 10',
      ],
      'firstName' => [
        'alias' => 'first_name',
        'type' => Type::nonNull(Type::string()),
        'description' => 'First name',
      ],
      'lastName' => [
        'alias' => 'last_name',
        'type' => Type::nonNull(Type::string()),
        'description' => 'Last name',
      ],
      'gender' => [
        'type' => Type::nonNull(Type::string()),
        'description' => 'Gender',
      ],
      'dateOfBirth' => [
        'alias' => 'dob',
        'type' => Type::string(),
        'description' => 'Date of birth',
      ],
      'age' => [
        'type' => Type::nonNull(Type::string()),
        'description' => 'Age',
      ],
      'category' => [
        'type' => Type::nonNull(GraphQL::type('CategoryEnum')),
        'description' => 'Age category',
      ],
      'magicMiles' => [
        'type' => Type::listOf(GraphQL::type('MagicMile')),
        'description' => 'The athlete\'s magic mile performances',
      ],
      'performances' => [
        'type' => Type::listOf(GraphQL::type('Performance')),
        'description' => 'The athlete\'s performances',
      ],
      'rankings' => [
        'type' => Type::listOf(GraphQL::type('Ranking')),
        'description' => 'The athlete\'s rankings',
        'args'          => [
          'blah' => [
            'type' => Type::int(),
          ],
        ],
        'resolve' => function ($root, array $args) {
          // Log::error(print_r($root, true));
          return $root->rankings()->first();
        }
      ],
      'standards' => [
        'type' => Type::listOf(GraphQL::type('Standard')),
        'description' => 'The athlete\'s standards',
      ],
      'latestPerformance' => [
        'type' => GraphQL::type('Performance'),
        'description' => 'The most recent performance recorded',
      ],
      'firstPerformance' => [
        'type' => GraphQL::type('Performance'),
        'description' => 'The most recent performance recorded',
      ],
      'latestRanking' => [
        'type' => GraphQL::type('Ranking'),
        'description' => 'The most recent handicap recorded',
      ],
    ];
  }
}
