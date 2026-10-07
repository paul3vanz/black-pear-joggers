<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Club extends Model
{
    protected $fillable = [
        'name',
        'slug',
        'ea_club_id',
        'timezone',
        'join_url',
        'settings',
    ];

    protected $casts = [
        'settings' => 'array',
    ];

    public function members()
    {
        return $this->hasMany(ClubMember::class);
    }
}
