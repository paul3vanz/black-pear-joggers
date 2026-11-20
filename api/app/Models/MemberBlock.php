<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/** A member hiding another member's messages and card from themselves. */
final class MemberBlock extends Model
{
    use HasUuids;

    protected $fillable = ['id', 'club_id', 'blocker_member_id', 'blocked_member_id'];
}
