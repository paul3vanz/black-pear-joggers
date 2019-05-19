<?php

# app/Models/MagicMile.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class MagicMile extends Model {

    protected $table = 'magicMile';

	protected $fillable = [
		'athlete_id',
		'first_name',
		'last_name',
		'gender',
		'category',
		'date',
		'location',
		'predicted_time',
		'predicted_time_parsed',
		'actual_time',
		'actual_time_parsed'
    ];
    
	public function athlete() {
		return $this->belongsTo('App\Models\Athlete', 'athlete_id', 'id');
	}
}