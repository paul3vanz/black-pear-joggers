<?php

namespace App\GraphQL\Queries;

use Log;
// use Illuminate\Support\Facades\Log;
use Rebing\GraphQL\Support\Query;

abstract class BaseQuery extends Query
{
  function addFilters($filter, $query)
  {
    foreach ($filter as $fieldName => $filterValue) {
      if (!is_array($filterValue)) {
        // echo $fieldName . '=' . $filterValue;
        return $query->where($fieldName, '=', $filterValue);
      }

      $value = current($filterValue);

      switch (key($filterValue)) {
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
