<?php

# app/Models/Athlete.php

namespace App\Models;

use Log;
use Awobaz\Compoships\Database\Eloquent\Model;
use Illuminate\Support\Carbon;

final class Athlete extends Model
{
    use \Awobaz\Compoships\Compoships;

    protected $fillable = [
        'id',
        'urn',
        'athlete_id',
        'first_name',
        'last_name',
        'gender',
        'dob',
    ];

    protected $hidden = [
        'urn',
        'dob',
        'age',
        'laravel_through_key',
    ];

    protected $appends = [
        'age',
        'category',
    ];

    public function getAgeAttribute()
    {
        return (new \Carbon\Carbon($this->dob))->age;
    }

    public function getCategoryAttribute()
    {
        if (!$this->age) {
            return null;
        }

        if ($this->age < 20) {
            return 'U20';
        } else if ($this->age < 23) {
            return 'U23';
        } else if ($this->age < 35) {
            return 'SEN';
        } else {
            return 'V' . (floor($this->age / 5) * 5);
        }
    }

    public function magicmiles()
    {
        return $this->hasMany('App\Models\MagicMile', 'athlete_id', 'id');
    }

    public function performances()
    {
        return $this->hasMany('App\Models\Performance', 'athlete_id', 'id');
    }

    public function rankings()
    {
        return $this->hasMany('App\Models\Ranking', 'athlete_id', 'id');
    }

    public function standards()
    {
        return $this->hasMany('App\Models\Standard', ['category', 'gender'], ['category', 'gender']);
    }

    public function latestPerformance()
    {
        return $this->hasOne('App\Models\Performance', 'athlete_id', 'id')->latest('date');
    }

    public function firstPerformance()
    {
        return $this->hasOne('App\Models\Performance', 'athlete_id', 'id')->oldest('date');
    }

    public function latestRanking()
    {
        return $this->hasOne('App\Models\Ranking', 'athlete_id', 'id')->latest('date');
    }

    public function membership()
    {
        return $this->belongsTo('App\Models\Membership', 'urn', 'urn');
    }

    public function activeMembership()
    {
        return $this->belongsTo('App\Models\Membership', 'urn', 'urn')->whereIn('competitiveRegStatus', [
            'Registered',
        ]);
    }

    public function users()
    {
        return $this->belongsTo('App\Models\User', 'athleteId', 'id');
    }
}
