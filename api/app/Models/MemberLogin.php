<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/**
 * An Auth0 login (user_id = token sub) linked to a member of one club.
 */
final class MemberLogin extends Model
{
    use HasUuids;

    protected $fillable = [
        'club_id',
        'member_id',
        'user_id',
        'linked_at',
    ];

    protected $casts = [
        'linked_at' => 'datetime',
    ];

    public function member()
    {
        return $this->belongsTo(ClubMember::class, 'member_id');
    }

    public function club()
    {
        return $this->belongsTo(Club::class);
    }
}
