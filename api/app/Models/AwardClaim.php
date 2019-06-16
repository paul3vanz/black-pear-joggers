<?php

# app/Models/AwardClaim.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

final class AwardClaim extends Model {

  use SoftDeletes;

  const CREATED_AT = 'createdDate';
  const UPDATED_AT = 'updatedDate';
  const DELETED_AT = 'deletedDate';

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