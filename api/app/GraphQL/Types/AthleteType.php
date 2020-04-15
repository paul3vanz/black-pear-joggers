<?php

namespace App\GraphQL\Types;

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
      'active' => [
        'type' => Type::nonNull(Type::int()),
        'description' => '',
      ],
      'membershipCheck' => [
        'alias' => 'membership_check',
        'type' => Type::nonNull(Type::string()),
        'description' => '',
      ],
      'membershipCheckStatus' => [
        'alias' => 'membership_check_status',
        'type' => Type::nonNull(Type::string()),
        'description' => '',
      ],
      'club' => [
        'type' => Type::nonNull(Type::string()),
        'description' => '',
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
        'args' => [
          'date' => [
            'type' => GraphQL::type('DateFilter'),
          ],

        ],
        'query' => function (array $args, $query, $ctx) {
          print_r('test');
          die('test');
          return $query->where('date', '>', $args['date']);
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
