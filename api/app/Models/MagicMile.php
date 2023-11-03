<?php

# app/Models/MagicMile.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class MagicMile extends Model {

    const CREATED_AT = 'createdDate';
    const UPDATED_AT = 'updatedDate';

    protected $table = 'magicMile';

	protected $fillable = [
		'athleteId',
		'firstName',
		'lastName',
		'gender',
		'category',
		'date',
		'location',
		'predictedTime',
		'actualTime',
    ];

    protected $appends = [
		'predictedTimeFormatted',
		'actualTimeFormatted',
    ];

    public function getPredictedTimeFormattedAttribute() {
        return $this->predictedTime ? $this->formattedTime($this->predictedTime) : null;
    }

    public function getActualTimeFormattedAttribute() {
        return $this->formattedTime($this->actualTime);
    }

	public function athlete() {
		return $this->belongsTo('App\Models\Athlete', 'athleteId', 'id');
	}

    private function formattedTime($timeInSeconds) {
        if ($timeInSeconds < 60) {
            $formattedTime = gmdate('s', $timeInSeconds);
        } else if ($timeInSeconds < 3600) {
            $formattedTime = ltrim(gmdate('i:s', $timeInSeconds), 0);
        } else {
            $formattedTime = gmdate('g:i:s', $timeInSeconds);
        }

        return $formattedTime;
    }
}