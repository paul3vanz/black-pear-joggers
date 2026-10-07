<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * A urn + dob link attempt, kept so failures can be rate limited.
 */
final class MemberLinkAttempt extends Model
{
    const UPDATED_AT = null;

    protected $fillable = [
        'user_id',
        'club_id',
        'success',
    ];

    protected $casts = [
        'success' => 'boolean',
    ];
}
