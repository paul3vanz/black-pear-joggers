<?php

namespace App\Models;

use Log;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

final class Registration extends Model {

    use SoftDeletes;

    protected $table = 'registration';

    protected $fillable = [
        'urn',
        'firstName',
        'lastName',
        'gender',
        'dateOfBirth',
        'emailAddress',
        'notes'
    ];

    public function registrations() {
        return $this->hasMany('App\Models\Athlete', 'urn', 'urn');
    }
}