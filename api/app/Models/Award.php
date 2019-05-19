<?php

# app/Models/Award.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Award extends Model {

	public $timestamps = false;

	protected $fillable = [
		'name'
	];

	public function standards() {
		return $this->hasMany('App\Models\Standard', 'standard', 'id');
	}
}