<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * The JPEG bytes of one member's photo (Phase 6.5), keyed by member id. Never load
 * this model except to serve the image or replace/delete it: the blob can be 400 KB.
 */
final class MemberPhoto extends Model
{
    protected $primaryKey = 'member_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'club_id',
        'member_id',
        'image',
    ];
}
