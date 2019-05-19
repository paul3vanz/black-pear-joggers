<?php

# app/Models/Member.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Member extends Model {
 
	protected $fillable = [
		'urn',
		'first_name',
		'last_name',
		'dob',
		'paid_amount',
		'paid_status',
		'paid_method',
		'paid_date',
		'paid_reference',
		'email',
		'membership_type'
	];

    protected $primaryKey = 'urn';
    
	public function athlete() {
		return $this->belongsTo('App\Models\Athlete', 'urn', 'urn');
	}
}