<?php

namespace App\GraphQL\Types;

use App\Models\MagicMile;
use GraphQL\Type\Definition\Type;
use Rebing\GraphQL\Support\Type as GraphQLType;

class MagicMileType extends GraphQLType
{
    protected $attributes = [
        'name' => 'MagicMile',
        'description' => 'Details about a magic mile performance',
        'model' => MagicMile::class
    ];

    public function fields(): array
    {
        return [
            'id' => [
                'type' => Type::nonNull(Type::int()),
                'description' => 'Unique ID of the performance',
            ],
            'first_name' => [
                'type' => Type::nonNull(Type::string()),
                'description' => 'The athlete first name',
            ],
            'last_name' => [
                'type' => Type::nonNull(Type::string()),
                'description' => 'The athlete last name',
            ],
            'gender' => [
                'type' => Type::nonNull(Type::string()),
                'description' => 'The athlete gender',
            ],
            'category' => [
                'type' => Type::nonNull(Type::string()),
                'description' => 'The athlete age category',
            ],
            'date' => [
                'type' => Type::nonNull(Type::string()),
                'description' => 'The date of the performance',
            ],
            'location' => [
                'type' => Type::nonNull(Type::string()),
                'description' => 'The location of the performance',
            ],
            'predicted_time' => [
                'type' => Type::nonNull(Type::string()),
                'description' => 'Predicted time in user friendly string',
            ],
            'predicted_time_parsed' => [
                'type' => Type::nonNull(Type::string()),
                'description' => 'Predicted time in seconds',
            ],
            'actual_time' => [
                'type' => Type::nonNull(Type::string()),
                'description' => 'Actual time in user friendly string',
            ],
            'actual_time_parsed' => [
                'type' => Type::nonNull(Type::string()),
                'description' => 'Actual time in seconds',
            ]
        ];
    }
}
