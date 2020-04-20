<?php

namespace App\GraphQL\Queries;

use Closure;
use App\Models\Performance;
use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\Facades\GraphQL;
use GraphQL\Type\Definition\ResolveInfo;
use Rebing\GraphQL\Support\SelectFields;
use App\GraphQL\Queries\BaseQuery;

class PerformanceQuery extends BaseQuery
{
  protected $attributes = [
    'name' => 'Performance',
  ];

  public function type(): Type
  {
    return Type::listOf(GraphQL::type('Performance'));
  }

  public function args(): array
  {
    return [
      'id' => [
        'name' => 'id',
        'type' => Type::int(),
        'rules' => [],
      ],
      'athleteId' => [
        'name' => 'athleteId',
        'type' => Type::int(),
        'rules' => [],
      ],
      'filters' => [
        'name' => 'filter',
        'type' => GraphQL::type('PerformanceFilter'),
        'rules' => [],
      ],
    ];
  }

  public function resolve($root, $args, $context, ResolveInfo $info, Closure $getSelectFields)
  {
    $query = Performance::query();

    if (isset($args['id'])) {
      $query = $query->where('id', $args['id']);
    }

    if (isset($args['athleteId'])) {
      $query = $query->where('athlete_id', $args['athleteId']);
    }

    if (isset($args['filter'])) {
      $query = PerformanceQuery::addFilters($args['filter'], $query);
    }

    // print_r($query->toSql());
    // print_r($query->getBindings());

    return $query->get();
  }
}
