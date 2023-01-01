<?php

# app/Models/Performance.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Performance extends Model
{
    protected $fillable = [
        'athlete_id',
        'category',
        'meetingId',
        'meeting_id',
        'event',
        'time',
        'time_parsed',
        'race',
        'date',
        'manual',
        'isPersonalBest',
    ];

    public function meeting()
    {
        return $this->belongsTo('App\Models\Meeting', 'id', 'meetingId');
    }

    public function athlete()
    {
        return $this->belongsTo('App\Models\Athlete', 'athlete_id', 'athlete_id');
    }

    public function event()
    {
        return $this->belongsTo('App\Models\Event', 'event_id', 'id');
    }
}
