<?php

# app/Models/Performance.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Ranking extends Model {

	protected $fillable = [
		'athlete_id',
		'date',
		'ranking'
    ];
    
	public function athlete() {
		return $this->belongsTo('App\Models\Athlete', 'athlete_id', 'id');
    }
}