<?php

# app/Models/Payment.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

final class Payment extends Model
{
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

    public function athlete()
    {
        return $this->belongsTo('App\Models\Athlete', 'urn', 'urn');
    }
}
