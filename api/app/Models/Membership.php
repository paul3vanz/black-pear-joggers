<?php

# app/Models/Member.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Membership extends Model {
 
	protected $fillable = [
        'urn',
        'firstName',
        'lastName',
        'dob',
        'gender',
        'foreignFlag',
        'competitiveRegStatus',
        'firstClaimClubId',
        'firstClaimClubName',
        'firstClaimOtherId',
        'firstClaimOtherName',
        'higherClaimClubId',
        'higherClaimClubName',
        'secondClaimClubId',
        'secondClaimClubName',
	];

    protected $hidden = [
        'urn',
        'dob',
      ];

    protected $appends = [
        'isActive',
    ];

    public function getIsActiveAttribute() {
        return in_array($this->competitiveRegStatus, [
            'Registered',
            'Registration Being Processed',
            'Registration Being Processed By Club',
            'Awaiting Registration with Club',
        ]);
    }

    protected $primaryKey = 'urn';
    
	public function athlete() {
		return $this->belongsTo('App\Models\Athlete', 'urn', 'urn');
	}
}