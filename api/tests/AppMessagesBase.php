<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\ClubMember;
use App\Models\GroupMessage;
use App\Models\SessionGroup;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;

/**
 * Shared fixtures for the Phase 6 (group messaging) tests. "Now" is Monday
 * 2026-10-12 09:00 UTC; the default run is that evening, 19:00 to 20:30 London
 * (18:00Z to 19:30Z). The queue is faked, nothing is pushed.
 *
 * $this->sess is the run, $this->g the group led by leaderA (so a "Lee" leads),
 * $this->going is a plain member going in g.
 */
abstract class AppMessagesBase extends AppGroupsBase
{
    protected $sess;
    protected $g;
    protected $going;

    protected function setUp(): void
    {
        parent::setUp();

        Queue::fake();

        $this->sess = $this->session();
        $this->g = $this->group($this->sess, [$this->leaderA], ['pace_unit' => 'mi', 'pace_from_s' => 540, 'pace_to_s' => 570]);
        $this->going = $this->member('going', 301, [], 'active', 'Gwen');
        $this->attend($this->sess, $this->going, 'going', $this->g);
    }

    protected function postMsg(?string $sub, SessionGroup $group, $body, ?string $id = null): array
    {
        $data = ['body' => $body];

        if ($id !== null) {
            $data['id'] = $id;
        }

        return $this->api('POST', "/groups/{$group->id}/messages", $sub, $data);
    }

    protected function messagesOf(?string $sub, SessionGroup $group, string $query = ''): array
    {
        return $this->api('GET', "/groups/{$group->id}/messages$query", $sub);
    }

    /** Writes a message straight to the table at an exact time. */
    protected function msg(ClubMember $member, SessionGroup $group, string $body = 'hello', ?Carbon $at = null): GroupMessage
    {
        $at = $at ?: Carbon::now();
        $message = new GroupMessage(['club_id' => 1, 'group_id' => $group->id, 'member_id' => $member->id, 'body' => $body]);
        $message->created_at = $at;
        $message->updated_at = $at;
        $message->save();

        return $message;
    }

    protected function uuid(): string
    {
        return (string) \Illuminate\Support\Str::uuid();
    }

    protected function otherClub(): void
    {
        DB::table('clubs')->insert(['id' => 2, 'name' => 'Other club', 'slug' => 'other', 'timezone' => 'Europe/London']);
    }
}
