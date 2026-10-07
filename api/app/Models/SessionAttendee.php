<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

final class SessionAttendee extends Model
{
    use HasUuids;

    const GOING = 'going';
    const MAYBE = 'maybe';
    const NOT_GOING = 'not_going';
    const STATUSES = ['going', 'maybe', 'not_going'];

    protected $fillable = [
        'club_id',
        'session_id',
        'member_id',
        'group_id',
        'status',
        'pace_unit',
        'pace_from_s',
        'pace_to_s',
    ];

    public function session()
    {
        return $this->belongsTo(ClubSession::class, 'session_id')->withTrashed();
    }

    public function member()
    {
        return $this->belongsTo(ClubMember::class, 'member_id')->withTrashed();
    }
}
