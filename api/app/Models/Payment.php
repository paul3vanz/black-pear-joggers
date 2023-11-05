<?php

# app/Models/Payment.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Payment extends Model
{
    protected $primaryKey = 'urn';
    protected $fillable = [
        'urn',
        'firstname',
        'lastname',
        'dob',
        'amount',
        'paymentStatus',
        'email',
        'paymentType',
        'reference',
        'paymentMethod',
        'datePaid',
        'membershipType',
    ];

    const CREATED_AT = 'createdAt';
    const UPDATED_AT = 'updatedAt';

    public function athlete()
    {
        return $this->belongsTo('App\Models\Athlete', 'urn', 'urn');
    }
}
