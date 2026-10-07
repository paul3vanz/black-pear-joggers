<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/**
 * A member's explicit push on/off choice for one category.
 */
final class NotificationPreference extends Model
{
    use HasUuids;

    protected $fillable = [
        'club_id',
        'member_id',
        'category',
        'push_enabled',
    ];

    protected $casts = [
        'push_enabled' => 'boolean',
    ];
}
