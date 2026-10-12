<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * A place the club's members run events at (a parkrun, a race, anywhere else). Phase 8.
 */
final class EventLocation extends Model
{
    use HasUuids;
    use SoftDeletes;

    const KINDS = ['parkrun', 'race', 'other'];
    const SOURCES = ['import', 'manual'];

    protected $attributes = [
        'source' => 'manual',
    ];

    protected $fillable = [
        'id',
        'club_id',
        'kind',
        'name',
        'slug',
        'country',
        'region',
        'lat',
        'lng',
        'url',
        'source',
    ];

    protected $casts = [
        'lat' => 'float',
        'lng' => 'float',
    ];
}
