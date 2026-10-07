<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/** A member's pace/distance units and usual pace range for one club. */
final class MemberPreference extends Model
{
    use HasUuids;

    const UNITS = ['mi', 'km'];

    protected $fillable = [
        'club_id',
        'member_id',
        'pace_unit',
        'distance_unit',
        'pace_from_s',
        'pace_to_s',
    ];

    public function member()
    {
        return $this->belongsTo(ClubMember::class, 'member_id')->withTrashed();
    }
}
