<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * A pace/distance group within one run. Values are stored as entered; see
 * GroupPresenter for the derived canonical values.
 */
final class SessionGroup extends Model
{
    use HasUuids;
    use SoftDeletes;

    const KINDS = ['run', 'jog_walk', 'efforts', 'route', 'social', 'other'];
    const STATUS_ACTIVE = 'active';
    const STATUS_NEEDS_LEADER = 'needs_leader';

    protected $attributes = [
        'kind' => 'run',
        'status' => 'active',
        'sort_order' => 0,
    ];

    protected $fillable = [
        'id',
        'club_id',
        'session_id',
        'kind',
        'label',
        'description',
        'pace_unit',
        'pace_from_s',
        'pace_to_s',
        'distance_value',
        'distance_unit',
        'status',
        'sort_order',
        'created_by_member_id',
    ];

    public function session()
    {
        return $this->belongsTo(ClubSession::class, 'session_id')->withTrashed();
    }

    public function leaders()
    {
        return $this->hasMany(SessionGroupLeader::class, 'group_id');
    }

    public function confirmedLeaders()
    {
        return $this->leaders()->where('status', SessionGroupLeader::CONFIRMED);
    }

    public function attendees()
    {
        return $this->hasMany(SessionAttendee::class, 'group_id');
    }
}
