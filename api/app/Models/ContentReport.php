<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

/** A member's report of a message, comment or profile card, for the committee. */
final class ContentReport extends Model
{
    use HasUuids;

    const KINDS = ['message', 'leader_message', 'comment', 'profile'];
    const REASONS = ['spam', 'abusive', 'inappropriate', 'other'];

    protected $fillable = [
        'id',
        'club_id',
        'reporter_member_id',
        'reported_member_id',
        'kind',
        'target_id',
        'reason',
        'details',
        'excerpt',
        'status',
    ];
}
