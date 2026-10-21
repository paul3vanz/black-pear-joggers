<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/** Someone a committee ask went to: they can read and answer that run's leaders thread. */
final class LeaderThreadMember extends Model
{
    use HasUuids;

    protected $fillable = [
        'club_id',
        'session_id',
        'member_id',
    ];
}
