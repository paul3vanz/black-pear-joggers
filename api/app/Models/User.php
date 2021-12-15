<?php

# app/Models/User.php

namespace App\Models;

use Awobaz\Compoships\Database\Eloquent\Model;

final class User extends Model
{

    const CREATED_AT = 'createdDate';
    const UPDATED_AT = 'updatedDate';

    protected $fillable = [
        'authSubject',
        'athleteId'
    ];

    public function athlete()
    {
        return $this->hasOne('App\Models\Athlete', 'athleteId', 'id');
    }
}
