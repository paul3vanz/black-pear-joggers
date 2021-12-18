<?php

# app/Models/User.php

namespace App\Models;

use Awobaz\Compoships\Database\Eloquent\Model;
use App\Models\Athlete;

final class User extends Model
{

    const CREATED_AT = 'createdDate';
    const UPDATED_AT = 'updatedDate';

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'athleteId'
    ];

    public function athlete()
    {
        return $this->hasOne(Athlete::class, 'id', 'athleteId');
    }
}
