<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/**
 * One inbox entry for one member.
 */
final class Notification extends Model
{
    use HasUuids;

    protected $fillable = [
        'club_id',
        'member_id',
        'category',
        'title',
        'body',
        'data',
        'dedupe_key',
        'read_at',
        'pushed_at',
        'push_requested_at',
    ];

    protected $casts = [
        'data' => 'array',
        'read_at' => 'datetime',
        'pushed_at' => 'datetime',
        'push_requested_at' => 'datetime',
    ];
}
