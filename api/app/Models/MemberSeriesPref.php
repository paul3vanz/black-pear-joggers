<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/**
 * A member's choice for one series (D117): `mode` is follow | auto | hide, and no row means auto.
 * It decides both whether the series' runs show in My runs and whether they are reminded
 * (`Services/FollowResolver`, storage in `Services/SeriesFollows`).
 *
 * `reminders` (on | off) is the old reminder-only override (D35). It is only read for a member who
 * has not been migrated yet (`member_preferences.follows_migrated_at` null) and is kept until the
 * old day filter is removed; new rows leave it null.
 */
final class MemberSeriesPref extends Model
{
    use HasUuids;

    // Old `reminders` values.
    const ON = 'on';
    const OFF = 'off';
    const AUTO = 'auto';

    // `mode` values.
    const FOLLOW = 'follow';
    const HIDE = 'hide';
    const MODES = [self::FOLLOW, self::AUTO, self::HIDE];

    protected $fillable = [
        'club_id',
        'member_id',
        'series_id',
        'reminders',
        'mode',
    ];
}
