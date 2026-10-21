<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/** A member's read marker and mute switch for one update's comments. A row means they opened the thread. */
final class PostThreadState extends Model
{
    use HasUuids;

    protected $fillable = [
        'club_id',
        'post_id',
        'member_id',
        'last_read_at',
        'muted',
    ];

    protected $casts = [
        'last_read_at' => 'datetime',
        'muted' => 'boolean',
    ];
}
