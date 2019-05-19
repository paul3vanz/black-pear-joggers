<?php

# app/Models/Standard.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Standard extends Model {

	public $timestamps = false;

	protected $fillable = [
		'gender',
		'category',
		'event_id',
		'award_id',
		'time',
		'time_parsed'
	];

	public function award() {
		return $this->belongsTo('App\Models\Award', 'award_id', 'id');
	}

	public function event() {
		return $this->belongsTo('App\Models\Event', 'event_id', 'id');
	}

}