<?php

use Illuminate\Support\Carbon;
use App\Models\Athlete;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

/**
 * People who already linked on the website (users.athleteId) are linked in the
 * app automatically: one BPJ club_members row per athlete, one member_logins
 * row per user. Safe to run more than once.
 */
return new class extends Migration
{
    private const BPJ_CLUB_ID = 1;

    public function up(): void
    {
        if (!Schema::hasTable('users') || !Schema::hasTable('athletes') || !Schema::hasTable('club_members')) {
            return;
        }

        $now = Carbon::now();

        DB::table('users')->whereNotNull('athleteId')->orderBy('id')->each(function ($user) use ($now) {
            $athlete = Athlete::with(['membership', 'payments'])->find($user->athleteId);

            if (!$athlete) {
                return;
            }

            $member = DB::table('club_members')
                ->where('club_id', self::BPJ_CLUB_ID)
                ->where('athlete_id', $athlete->id)
                ->first();

            if ($member) {
                $memberId = $member->id;
            } else {
                $memberId = (string) Str::orderedUuid();

                DB::table('club_members')->insert([
                    'id' => $memberId,
                    'club_id' => self::BPJ_CLUB_ID,
                    'athlete_id' => $athlete->id,
                    'display_name' => trim($athlete->first_name . ' ' . $athlete->last_name),
                    'roles' => '[]',
                    'status' => $athlete->active ? 'active' : 'lapsed',
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }

            $exists = DB::table('member_logins')
                ->where('club_id', self::BPJ_CLUB_ID)
                ->where('user_id', $user->id)
                ->exists();

            if (!$exists) {
                DB::table('member_logins')->insert([
                    'id' => (string) Str::orderedUuid(),
                    'club_id' => self::BPJ_CLUB_ID,
                    'member_id' => $memberId,
                    'user_id' => $user->id,
                    'linked_at' => $now,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }
        }, 200);
    }

    public function down(): void
    {
        // Backfilled rows cannot be told apart from rows created through the app.
    }
};
