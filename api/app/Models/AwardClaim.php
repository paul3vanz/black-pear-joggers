<?php

# app/Models/AwardClaim.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

final class AwardClaim extends Model {

  use SoftDeletes;

  const CREATED_AT = 'createdDate';
  const UPDATED_AT = 'updatedDate';
  const DELETED_AT = 'deletedDate';

  protected $table = 'awardClaim';

	protected $fillable = [
    'athleteId',
		'gender',
    'category',
    'award',
		'firstName',
		'lastName',
    'email',
    'verified',
    'token',
  ];

  protected $hidden = [
    'email',
    'token',
  ];

  protected $casts = [
    'athleteId' => 'integer',
    'verified' => 'boolean',
  ];

  protected static function boot()
  {
    parent::boot();

    static::creating(function (AwardClaim $claim) {
      $claim->token = $claim->token ?: (string) Str::uuid();
    });
  }

	public function races() {
		return $this->hasMany('App\Models\AwardClaimRace', 'claimId', 'id');
	}

}