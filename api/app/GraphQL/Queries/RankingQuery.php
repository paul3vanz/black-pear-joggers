<?php

namespace App\GraphQL\Queries;

use Closure;
use App\Models\Ranking;
use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\Facades\GraphQL;
use GraphQL\Type\Definition\ResolveInfo;
use Rebing\GraphQL\Support\SelectFields;
use Rebing\GraphQL\Support\Query;

class RankingQuery extends Query
{
  protected $attributes = [
    'name' => 'Ranking',
  ];

  public function type(): Type
  {
    return Type::listOf(GraphQL::type('Ranking'));
  }

  public function args(): array
  {
    return [
      'date' => [
        'name' => 'date',
        'type' => GraphQL::type('DateFilter'),
      ],
    ];
  }

  public function resolve($root, $args, $context, ResolveInfo $info, Closure $getSelectFields)
  {
    $filtersAdded = 0;
    $query = Ranking::query();

    foreach (RankingQuery::args() as $arg) {
      $fieldName = $arg['name'];

      if (isset($args[$fieldName])) {
        $query = $query->where($fieldName, $args[$fieldName]);
        $filtersAdded++;
      }
    }

    $fields = $getSelectFields();
    $select = $fields->getSelect();
    $with = $fields->getRelations();

    $query = $query->with($with);

    if ($filtersAdded) {
      return $query->get();
    } else {
      return $query->get()->all();
    }
  }
}
