<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Meeting extends Model
{
    const CREATED_AT = 'createdDate';
    const UPDATED_AT = 'updatedDate';

    protected $fillable = [
        'id',
        'ukaMeetingId',
        'event',
        'name',
        'date',
    ];

    public $incrementing = false;

    public function performances()
    {
        return $this->hasMany('App\Models\Performance', 'meetingId', 'id');
    }

    public function firstPerformance()
    {
        return $this->hasMany('App\Models\Performance', 'meetingId', 'id');
    }
}
