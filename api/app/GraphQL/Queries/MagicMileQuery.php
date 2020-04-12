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

    public function resolve($root, $args)
    {
        return MagicMile::all();
    }
}
