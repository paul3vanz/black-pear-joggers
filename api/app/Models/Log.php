<?php

# app/Models/Log.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Log extends Model {

	protected $fillable = [
		'id',
        'message',
        'context',
        'level',
        'level_name',
        'channel',
        'record_datetime',
        'extra',
        'formatted',
        'remote_addr',
        'user_agent',
        'created_at',
	];

    public function getContextAttribute($context) {
        return json_decode($context, true);
    }
}