<?php

namespace App\GraphQL\Queries;

use Closure;
use App\Models\Standard;
use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\Facades\GraphQL;
use GraphQL\Type\Definition\ResolveInfo;
use Rebing\GraphQL\Support\SelectFields;
use Rebing\GraphQL\Support\Query;

class StandardQuery extends Query
{
  protected $attributes = [
    'name' => 'Standard',
  ];

  public function type(): Type
  {
    return Type::listOf(GraphQL::type('Standard'));
  }

  public function args(): array
  {
    return [
      'gender' => [
        'name' => 'gender',
        'type' => GraphQL::type('GenderEnum'),
      ],
      'category' => [
        'name' => 'category',
        'type' => GraphQL::type('CategoryEnum'),
      ],
    ];
  }

  public function resolve($root, $args, $context, ResolveInfo $info, Closure $getSelectFields)
  {
    $filtersAdded = 0;
    $query = Standard::query();

    foreach (StandardQuery::args() as $arg) {
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
