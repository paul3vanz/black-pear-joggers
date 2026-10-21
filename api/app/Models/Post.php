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
        'comments_closed_at',
    ];

    protected $casts = [
        'published_at' => 'datetime',
        'pinned_until' => 'datetime',
        'comments_closed_at' => 'datetime',
    ];

    /** The committee closed comments on this update (D126). */
    public function commentsClosed(): bool
    {
        return $this->comments_closed_at !== null;
    }

    public function author()
    {
        return $this->belongsTo(ClubMember::class, 'author_member_id')->withTrashed();
    }
}
