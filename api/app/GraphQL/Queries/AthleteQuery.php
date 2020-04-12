<?php

namespace App\GraphQL\Queries;

use App\Models\Athlete;
use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\Facades\GraphQL;
use Rebing\GraphQL\Support\Query;

class AthleteQuery extends Query
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
      'category' => [
        'name' => 'category',
        'type' => GraphQL::type('CategoryEnum'),
        'rules' => [],
      ],
      'firstName' => [
        'name' => 'firstName',
        'type' => Type::string(),
        'rules' => [],
      ],
      'lastName' => [
        'name' => 'lastName',
        'type' => Type::string(),
        'rules' => [],
      ],
    ];
  }

  public function resolve($root, $args)
  {
    $filtersAdded = 0;
    $query = Athlete::query();

    foreach (AthleteQuery::args() as $arg) {
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
