<?php

# app/Models/Athlete.php

namespace App\Models;

use Log;
use Awobaz\Compoships\Database\Eloquent\Model;

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
    'age',
    'category',
    'active',
    'competitive_status',
    'membership_check',
    'membership_check_status',
    'club'
  ];

  protected $hidden = [
    'urn',
    'dob',
    'age',
    'membership_check',
    'membership_check_status',
    'club'
  ];

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
}
