<?php

namespace App\GraphQL\Queries;

use Closure;
use App\Models\Athlete;
use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\Facades\GraphQL;
use GraphQL\Type\Definition\ResolveInfo;
use Rebing\GraphQL\Support\SelectFields;
use App\GraphQL\Queries\BaseQuery;

class AthleteQuery extends BaseQuery
{
  protected $attributes = [
    'name' => 'Athlete',
  ];

  public function type(): Type
  {
    return Type::listOf(GraphQL::type('Athlete'));
  }

  public function args(): array
  {
    return [
      'id' => [
        'name' => 'id',
        'type' => Type::int(),
        'rules' => [],
      ],
      'filter' => [
        'name' => 'filter',
        'type' => GraphQL::type('AthleteFilter'),
        'rules' => [],
      ],
    ];
  }

  public function resolve($root, $args, $context, ResolveInfo $info, Closure $getSelectFields)
  {
    $query = Athlete::query();

    if (isset($args['id'])) {
      $query = $query->where('id', $args['id']);
    }

    if (isset($args['filter'])) {
      $query = AthleteQuery::addFilters($args['filter'], $query);
    }

    return $query->get();
  }
}
