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
        'renudged_at',
    ];

    protected $casts = [
        'renudged_at' => 'datetime',
    ];

    public function isAsk(): bool
    {
        return $this->kind === self::KIND_ASK;
    }
}
