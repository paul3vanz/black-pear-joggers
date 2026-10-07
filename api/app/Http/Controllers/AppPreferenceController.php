<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ManagesGroups;
use App\Models\MemberPreference;
use App\Services\NotificationPresenter;
use Illuminate\Http\Request;

/**
 * The caller's units and usual pace range, per club (Phase 4).
 */
class AppPreferenceController extends Controller
{
    use ManagesGroups;

    private function body(?MemberPreference $pref): array
    {
        return [
            'paceUnit' => $pref ? $pref->pace_unit : 'mi',
            'distanceUnit' => $pref ? $pref->distance_unit : 'mi',
            'paceFromS' => $pref && $pref->pace_from_s !== null ? (int) $pref->pace_from_s : null,
            'paceToS' => $pref && $pref->pace_to_s !== null ? (int) $pref->pace_to_s : null,
            'updatedAt' => $pref ? NotificationPresenter::time($pref->updated_at) : null,
        ];
    }

    /**
     * @OA\Get(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/preferences",
     *   summary="The caller's pace/distance units and pace range (defaults mi/mi, no range).",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="Preferences"),
     * )
     */
    public function show(Request $request)
    {
        $pref = MemberPreference::where('club_id', $request->attributes->get('club')->id)
            ->where('member_id', $request->attributes->get('member')->id)
            ->first();

        return response()->json($this->body($pref));
    }

    /**
     * @OA\Put(
     *   tags={"App"},
     *   path="/app/clubs/{clubId}/preferences",
     *   summary="Save the caller's preferences. null clears the range; changing paceUnit without a range clears it.",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(response=200, description="Saved preferences"),
     *   @OA\Response(response=422, description="Validation error"),
     * )
     */
    public function update(Request $request)
    {
        $club = $request->attributes->get('club');
        $member = $request->attributes->get('member');

        $validator = $this->makeValidator($request->all(), [
            'paceUnit' => 'sometimes|required|in:mi,km',
            'distanceUnit' => 'sometimes|required|in:mi,km',
            'paceFromS' => 'nullable|integer|between:180,1800',
            'paceToS' => 'nullable|integer|between:180,1800',
        ]);

        if ($validator->fails()) {
            return $this->validationFailed($validator);
        }

        $pref = MemberPreference::firstOrNew(['club_id' => $club->id, 'member_id' => $member->id]);
        $pref->pace_unit = $pref->pace_unit ?: 'mi';
        $pref->distance_unit = $pref->distance_unit ?: 'mi';

        $unit = $request->input('paceUnit', $pref->pace_unit);
        $hasFrom = $request->has('paceFromS');
        $hasTo = $request->has('paceToS');
        $from = $hasFrom ? $request->input('paceFromS') : $pref->pace_from_s;
        $to = $hasTo ? $request->input('paceToS') : $pref->pace_to_s;

        if ($unit !== $pref->pace_unit && !$hasFrom && !$hasTo) {
            $from = $to = null; // a range in the old unit means nothing in the new one
        } elseif ($hasFrom && $from === null && !$hasTo) {
            $to = null; // clearing the faster end clears the range
        }

        if ($bad = $this->checkPaceRange($unit, $from, $to)) {
            return $bad;
        }

        $pref->pace_unit = $unit;
        $pref->distance_unit = $request->input('distanceUnit', $pref->distance_unit);
        $pref->pace_from_s = $from !== null ? (int) $from : null;
        $pref->pace_to_s = $to !== null ? (int) $to : null;
        $pref->updated_at = \Illuminate\Support\Carbon::now();
        $pref->save();

        return response()->json($this->body($pref->fresh()));
    }
}
