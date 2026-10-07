<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One person in one club, keyed by their athlete record. Several logins
 * (member_logins) can resolve to the same member.
 */
final class ClubMember extends Model
{
    use HasUuids;
    use SoftDeletes;

    protected $fillable = [
        'club_id',
        'athlete_id',
        'display_name',
        'roles',
        'status',
    ];

    protected $attributes = [
        'roles' => '[]',
        'status' => 'active',
    ];

    protected $casts = [
        'roles' => 'array',
    ];

    /** True if the member holds any of the given roles. */
    public function hasRole(string ...$roles): bool
    {
        return count(array_intersect($roles, $this->roles ?? [])) > 0;
    }

    /** Post audiences this member belongs to. */
    public function audiences(): array
    {
        $audiences = ['all'];

        if ($this->hasRole('leader', 'committee', 'admin')) {
            $audiences[] = 'leaders';
        }

        if ($this->hasRole('committee', 'admin')) {
            $audiences[] = 'committee';
        }

        return $audiences;
    }

    public function club()
    {
        return $this->belongsTo(Club::class);
    }

    public function athlete()
    {
        return $this->belongsTo(Athlete::class, 'athlete_id', 'id');
    }

    public function logins()
    {
        return $this->hasMany(MemberLogin::class, 'member_id');
    }
}
