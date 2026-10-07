<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One dated club run. Named ClubSession (table `sessions`) to avoid clashing
 * with PHP/Lumen sessions.
 */
final class ClubSession extends Model
{
    use HasUuids;
    use SoftDeletes;

    protected $table = 'sessions';

    const STATUS_SCHEDULED = 'scheduled';
    const STATUS_CANCELLED = 'cancelled';

    protected $attributes = [
        'status' => 'scheduled',
        'is_detached' => false,
    ];

    protected $fillable = [
        'id',
        'club_id',
        'series_id',
        'occurrence_date',
        'starts_at',
        'ends_at',
        'local_date',
        'local_start_time',
        'local_end_time',
        'venue_id',
        'title',
        'notes',
        'group_mode',
        'coordinator_member_id',
        'status',
        'cancel_reason',
        'is_detached',
    ];

    protected $casts = [
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
        'is_detached' => 'boolean',
    ];

    public function localDateYmd(): string
    {
        return substr((string) $this->attributes['local_date'], 0, 10);
    }

    public function occurrenceYmd(): ?string
    {
        $value = $this->attributes['occurrence_date'] ?? null;

        return $value ? substr((string) $value, 0, 10) : null;
    }

    public function series()
    {
        return $this->belongsTo(SessionSeries::class, 'series_id')->withTrashed();
    }

    public function coordinator()
    {
        return $this->belongsTo(ClubMember::class, 'coordinator_member_id')->withTrashed();
    }
}
