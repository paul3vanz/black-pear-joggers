<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Meeting extends Model
{
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
        return $this->hasMany('App\Models\Performance', 'meeting', 'id');
    }
}
