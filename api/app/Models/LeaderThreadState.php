<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/** A member's read marker and mute switch for one run's leaders thread. */
final class LeaderThreadState extends Model
{
    use HasUuids;

    protected $fillable = [
        'club_id',
        'session_id',
        'member_id',
        'last_read_at',
        'muted',
    ];

    protected $casts = [
        'last_read_at' => 'datetime',
        'muted' => 'boolean',
    ];
}
