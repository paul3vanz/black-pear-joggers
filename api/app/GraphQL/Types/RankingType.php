<?php

namespace App\GraphQL\Types;

use App\Models\Ranking;
use Rebing\GraphQL\Support\Facades\GraphQL;
use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\Type as GraphQLType;

class RankingType extends GraphQLType
{
  protected $attributes = [
    'name' => 'Ranking',
    'description' => 'Details about a ranking',
    'model' => Ranking::class
  ];

  public function fields(): array
  {
    return [
      'athleteId' => [
        'alias' => 'athlete_id',
        'type' => Type::nonNull(Type::int()),
        'description' => 'The athlete ID',
      ],
      'date' => [
        'type' => Type::nonNull(Type::string()),
        'description' => 'Date the ranking was recorded',
      ],
      'handicap' => [
        'alias' => 'ranking',
        'type' => Type::nonNull(Type::float()),
        'description' => 'The handicap ranking',
      ],
    ];
  }
}
