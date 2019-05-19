<?php

# app/Models/Event.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Event extends Model {

	protected $fillable = [
		'event',
		'distance',
		'alias',
		'has_standard'
	];

	public function standards() {
		return $this->hasMany('App\Models\Standard', 'event', 'id');
	}
}