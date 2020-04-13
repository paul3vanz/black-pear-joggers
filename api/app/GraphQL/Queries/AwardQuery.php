<?php

namespace App\GraphQL\Queries;

use Closure;
use App\Models\Award;
use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\Facades\GraphQL;
use GraphQL\Type\Definition\ResolveInfo;
use Rebing\GraphQL\Support\SelectFields;
use Rebing\GraphQL\Support\Query;

class AwardQuery extends Query
{
  protected $attributes = [
    'name' => 'Award',
  ];

  public function type(): Type
  {
    return Type::listOf(GraphQL::type('Award'));
  }

  public function args(): array
  {
    return [];
  }

  public function resolve($root, $args, $context, ResolveInfo $info, Closure $getSelectFields)
  {
    $filtersAdded = 0;
    $query = Award::query();

    foreach (AwardQuery::args() as $arg) {
      $fieldName = $arg['name'];

      if (isset($args[$fieldName])) {
        $query = $query->where($fieldName, $args[$fieldName]);
        $filtersAdded++;
      }
    }

    if ($filtersAdded) {
      return $query->get();
    } else {
      return $query->get()->all();
    }
  }
}
