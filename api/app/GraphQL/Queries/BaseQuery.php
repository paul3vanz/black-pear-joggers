<?php

namespace App\GraphQL\Queries;

use Rebing\GraphQL\Support\Query;

abstract class BaseQuery extends Query
{
  function addFilters($filter, $query)
  {
    foreach ($filter as $fieldName => $operatorAndValue) {
      $value = current($operatorAndValue);

      switch (key($operatorAndValue)) {
        case 'lt':
          $query = $query->where($fieldName, '<', $value);
          break;

        case 'lte':
          $query = $query->where($fieldName, '<=', $value);
          break;

        case 'gt':
          $query = $query->where($fieldName, '>', $value);
          break;

        case 'gte':
          $query = $query->where($fieldName, '>=', $value);
          break;

        case 'equals':
          $query = $query->where($fieldName, $value);
          break;

        case 'notEquals':
          $query = $query->where($fieldName, '!=', $value);
          break;

        case 'contains':
          $query = $query->where($fieldName, 'like', '%' . $value . '%');
          break;

        case 'startsWith':
          $query = $query->where($fieldName, 'like', $value . '%');
          break;
      }
    }

    return $query;
  }
}
