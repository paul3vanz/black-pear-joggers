<?php

# app/Models/Standard.php

namespace App\Models;

use Awobaz\Compoships\Database\Eloquent\Model;

/**
 * @OA\Schema(
 *   title="Standard",
 *   description="A specific standard for a gender, category and event",
 * )
 */
final class Standard extends Model
{

  public $timestamps = false;

  /**
   *  @OA\Property(property="gender", type="string"),
   *  @OA\Property(property="category", type="string"),
   */
  protected $fillable = [
    'gender',
    'category',
    'event_id',
    'award_id',
    'time',
    'time_parsed'
  ];

  public function award()
  {
    return $this->belongsTo('App\Models\Award', 'award_id', 'id');
  }

  public function event()
  {
    return $this->belongsTo('App\Models\Event', 'event_id', 'id');
  }
}
