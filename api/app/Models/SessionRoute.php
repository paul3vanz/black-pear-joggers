<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/** A route set for one run; groups of that run may pick it. */
final class SessionRoute extends Model
{
    use HasUuids;
    use SoftDeletes;

    protected $attributes = ['sort_order' => 0];

    protected $fillable = [
        'id', 'club_id', 'session_id', 'label', 'url', 'distance_value', 'distance_unit', 'sort_order',
    ];

    public function session()
    {
        return $this->belongsTo(ClubSession::class, 'session_id')->withTrashed();
    }
}
