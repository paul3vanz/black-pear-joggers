<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One message in a run's leaders thread (D125): plain chat (`message`) or a
 * committee request for someone to lead a pace range (`ask`). Soft-deleted rows
 * are tombstones.
 */
final class LeaderMessage extends Model
{
    use HasUuids;
    use SoftDeletes;

    const KIND_MESSAGE = 'message';
    const KIND_ASK = 'ask';

    protected $fillable = [
        'id',
        'club_id',
        'session_id',
        'member_id',
        'kind',
        'body',
        'ask_fast_s_per_km',
        'ask_slow_s_per_km',
        'ask_member_ids',
        'ask_kind',
        'renudged_at',
    ];

    protected $casts = [
        'renudged_at' => 'datetime',
        'ask_member_ids' => 'array',
    ];

    const ASK_JOG_WALK = 'jog_walk';

    /**
     * An ask's pace is a stretch of the axis in seconds per km (D127). These bounds also mean "open":
     * a fast edge at OPEN_FAST is "faster than the slow edge", a slow edge at OPEN_SLOW is "slower
     * than the fast edge", and both is any pace.
     */
    const OPEN_FAST = 150;
    const OPEN_SLOW = 900;

    /** True for an ask that names the people it is for (D127). */
    public function isTargeted(): bool
    {
        return $this->ask_member_ids !== null;
    }

    public function isAsk(): bool
    {
        return $this->kind === self::KIND_ASK;
    }
}
