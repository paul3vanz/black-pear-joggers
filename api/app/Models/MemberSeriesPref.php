<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/**
 * A member's reminder override for one series: on or off. No row = automatic.
 */
final class MemberSeriesPref extends Model
{
    use HasUuids;

    const ON = 'on';
    const OFF = 'off';
    const AUTO = 'auto';

    protected $fillable = [
        'club_id',
        'member_id',
        'series_id',
        'reminders',
    ];
}
