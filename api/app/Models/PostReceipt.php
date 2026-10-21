<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/**
 * One member's delivered / read times for one club update.
 */
final class PostReceipt extends Model
{
    use HasUuids;

    protected $fillable = ['club_id', 'post_id', 'member_id', 'delivered_at', 'read_at'];

    protected $casts = [
        'delivered_at' => 'datetime',
        'read_at' => 'datetime',
    ];
}
