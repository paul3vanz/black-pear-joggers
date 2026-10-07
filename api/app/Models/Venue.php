<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * A place the club runs from.
 */
final class Venue extends Model
{
    use HasUuids;
    use SoftDeletes;

    protected $fillable = [
        'id',
        'club_id',
        'name',
        'address',
        'lat',
        'lng',
        'notes',
    ];

    protected $casts = [
        'lat' => 'float',
        'lng' => 'float',
    ];
}
