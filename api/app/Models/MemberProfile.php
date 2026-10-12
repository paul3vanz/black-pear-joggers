<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/** A member's bio, goals and photo version for one club (Phase 6.5). The image is in MemberPhoto. */
final class MemberProfile extends Model
{
    use HasUuids;

    protected $fillable = [
        'club_id',
        'member_id',
        'bio',
        'goals',
        'goals_visible',
        'photo_version',
        'photo_updated_at',
    ];

    protected $casts = [
        'goals_visible' => 'boolean',
        'photo_updated_at' => 'datetime',
    ];

    public function member()
    {
        return $this->belongsTo(ClubMember::class, 'member_id')->withTrashed();
    }
}
