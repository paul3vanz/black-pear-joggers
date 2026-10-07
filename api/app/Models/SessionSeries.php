<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * The weekly pattern that club run sessions are generated from.
 */
final class SessionSeries extends Model
{
    use HasUuids;
    use SoftDeletes;

    protected $table = 'session_series';

    const GROUP_MODES = ['paced', 'single', 'open', 'routes'];

    protected $attributes = [
        'interval_weeks' => 1,
    ];

    protected $fillable = [
        'id',
        'club_id',
        'title',
        'description',
        'venue_id',
        'weekday',
        'start_time',
        'duration_min',
        'interval_weeks',
        'valid_from',
        'valid_until',
        'group_mode',
        'cms_slug',
    ];

    protected $casts = [
        'weekday' => 'integer',
        'duration_min' => 'integer',
        'interval_weeks' => 'integer',
    ];

    /** start_time as HH:MM (the column is a TIME, read back as HH:MM:SS). */
    public function startHm(): string
    {
        return substr((string) $this->start_time, 0, 5);
    }

    /** valid_from as Y-m-d (the column is a DATE; some drivers return a datetime string). */
    public function validFromYmd(): string
    {
        return substr((string) $this->attributes['valid_from'], 0, 10);
    }

    public function validUntilYmd(): ?string
    {
        $value = $this->attributes['valid_until'] ?? null;

        return $value ? substr((string) $value, 0, 10) : null;
    }

    public function venue()
    {
        return $this->belongsTo(Venue::class)->withTrashed();
    }

    public function sessions()
    {
        return $this->hasMany(ClubSession::class, 'series_id');
    }
}
