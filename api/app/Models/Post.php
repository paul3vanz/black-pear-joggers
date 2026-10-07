<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * A club update published by the committee.
 */
final class Post extends Model
{
    use HasUuids;
    use SoftDeletes;

    const PRIORITIES = ['normal', 'important'];
    const AUDIENCES = ['all', 'leaders', 'committee'];

    protected $fillable = [
        'id',
        'club_id',
        'author_member_id',
        'title',
        'body_md',
        'priority',
        'audience',
        'published_at',
        'pinned_until',
    ];

    protected $casts = [
        'published_at' => 'datetime',
        'pinned_until' => 'datetime',
    ];

    public function author()
    {
        return $this->belongsTo(ClubMember::class, 'author_member_id')->withTrashed();
    }
}
