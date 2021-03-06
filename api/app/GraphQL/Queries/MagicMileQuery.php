<?php

namespace App\GraphQL\Queries;

use Closure;
use App\Models\MagicMile;
use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\Facades\GraphQL;
use GraphQL\Type\Definition\ResolveInfo;
use Rebing\GraphQL\Support\SelectFields;
use Rebing\GraphQL\Support\Query;

class MagicMileQuery extends Query
{
  protected $attributes = [
    'name' => 'MagicMile',
  ];

  public function type(): Type
  {
    return Type::listOf(GraphQL::type('MagicMile'));
  }

  public function args(): array
  {
    return [
      'id' => [
        'name' => 'id',
        'type' => Type::int(),
        'rules' => [],
      ],
      'category' => [
        'name' => 'category',
        'type' => GraphQL::type('CategoryEnum'),
        'rules' => [],
      ],
      'location' => [
        'name' => 'location',
        'type' => GraphQL::type('LocationEnum'),
        'rules' => [],
      ],
      'date' => [
        'name' => 'date',
        'type' => Type::string(),
        'rules' => [],
      ],
    ];
  }

  public function resolve($root, $args, $context, ResolveInfo $info, Closure $getSelectFields)
  {
    $filtersAdded = 0;
    $query = MagicMile::query();

    foreach (MagicMileQuery::args() as $arg) {
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
