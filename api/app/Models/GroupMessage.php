<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/** One chat message in a run group's thread. Soft-deleted rows are tombstones. */
final class GroupMessage extends Model
{
    use HasUuids;
    use SoftDeletes;

    protected $fillable = [
        'id',
        'club_id',
        'group_id',
        'member_id',
        'body',
    ];

    public function member()
    {
        return $this->belongsTo(ClubMember::class, 'member_id')->withTrashed();
    }
}
