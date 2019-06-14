<?php

# app/Models/AwardClaim.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class AwardClaim extends Model {

  const CREATED_AT = 'createdDate';
  const UPDATED_AT = 'updatedDate';

  protected $table = 'awardClaim';

	protected $fillable = [
		'gender',
    'category',
    'award',
		'firstName',
		'lastName',
    'email',
    'verified',
  ];

  protected $hidden = [
    'email'
];

	public function races() {
		return $this->hasMany('App\Models\AwardClaimRace', 'claimId', 'id');
	}

}