<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/** One comment on a club update (D126). Soft-deleted rows are tombstones. */
final class PostComment extends Model
{
    use HasUuids;
    use SoftDeletes;

    protected $fillable = [
        'id',
        'club_id',
        'post_id',
        'member_id',
        'body',
    ];
}
