<?php

# app/Models/AwardClaimRace.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class AwardClaimRace extends Model {

  const CREATED_AT = 'createdDate';
  const UPDATED_AT = 'updatedDate';

  protected $table = 'awardClaimRace';

	protected $fillable = [
		'claimId',
    'distance',
    'time',
    'timeParsed',
    'date',
    'race',
    'award',
  ];

	public function claim() {
		return $this->belongsTo('App\Models\AwardClaim', 'claimId', 'id');
	}

}