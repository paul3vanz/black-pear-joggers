<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/**
 * An FCM token registered by one login (user_id = Auth0 sub).
 */
final class Device extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'token',
        'platform',
        'app_version',
        'last_seen_at',
    ];

    protected $casts = [
        'last_seen_at' => 'datetime',
    ];
}
