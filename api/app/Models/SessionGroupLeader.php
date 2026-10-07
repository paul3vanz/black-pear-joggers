<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

final class SessionGroupLeader extends Model
{
    use HasUuids;

    const CONFIRMED = 'confirmed';
    const WITHDRAWN = 'withdrawn';
    const ROLES = ['leader', 'co_leader', 'backmarker'];

    protected $attributes = [
        'role' => 'leader',
        'status' => 'confirmed',
    ];

    protected $fillable = [
        'id',
        'club_id',
        'group_id',
        'member_id',
        'role',
        'status',
        'withdrawn_at',
    ];

    protected $casts = [
        'withdrawn_at' => 'datetime',
    ];

    public function group()
    {
        return $this->belongsTo(SessionGroup::class, 'group_id')->withTrashed();
    }

    public function member()
    {
        return $this->belongsTo(ClubMember::class, 'member_id')->withTrashed();
    }
}
