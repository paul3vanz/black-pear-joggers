<?php

namespace App\GraphQL\Queries;

use App\Models\MagicMile;
use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\Facades\GraphQL;
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
    ];
  }

  public function resolve($root, $args)
  {
    $query = MagicMile::query();

    foreach (MagicMileQuery::args() as $arg) {

      $fieldName = $arg['name'];
      if (isset($args[$fieldName])) {
        $query = $query->where($fieldName, $args[$fieldName]);
      }
    }

    return $query->get();
  }
}
