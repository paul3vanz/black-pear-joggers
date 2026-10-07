<?php

require_once __DIR__ . '/AppApiTestCase.php';

use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use App\Services\SessionGenerator;
use Illuminate\Support\Carbon;

/**
 * Shared fixtures for the Phase 4 tests. "Now" is pinned to Monday
 * 2026-10-12 09:00 UTC, so the default session (19:00 London = 18:00Z that
 * day) is in the future and a session on 2026-10-05 is past.
 */
abstract class AppGroupsBase extends AppApiTestCase
{
    protected $plain;
    protected $leaderA;
    protected $leaderB;
    protected $coord;
    protected $committee;
    protected $admin;

    protected function setUp(): void
    {
        parent::setUp();

        Carbon::setTestNow(Carbon::parse('2026-10-12 09:00:00', 'UTC'));

        $this->plain = $this->member('plain', 201, [], 'active', 'Pat');
        $this->leaderA = $this->member('leaderA', 202, [], 'active', 'Lee');
        $this->leaderB = $this->member('leaderB', 203, ['leader'], 'active', 'Lou');
        $this->coord = $this->member('coord', 204, [], 'active', 'Cory');
        $this->committee = $this->member('committee', 205, ['committee'], 'active', 'Cam');
        $this->admin = $this->member('admin', 206, ['admin'], 'active', 'Ada');
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    protected function session(array $overrides = []): ClubSession
    {
        $date = $overrides['date'] ?? '2026-10-12';
        unset($overrides['date']);

        return ClubSession::create($overrides + [
            'club_id' => 1,
            'title' => 'Monday club run',
            'group_mode' => 'paced',
            'coordinator_member_id' => $this->coord->id,
        ] + SessionGenerator::times($date, '19:00', 90, 'Europe/London'));
    }

    protected function pastSession(): ClubSession
    {
        return $this->session(['date' => '2026-10-05']);
    }

    protected function api(string $method, string $path, ?string $sub, array $data = []): array
    {
        return $this->call_($method, '/app/clubs/1' . $path, $sub, $data);
    }

    /** Creates a group directly, with optional confirmed leaders (members). */
    protected function group(ClubSession $session, array $leaders = [], array $overrides = []): SessionGroup
    {
        $group = SessionGroup::create($overrides + [
            'club_id' => 1,
            'session_id' => $session->id,
            'status' => $leaders ? 'active' : 'needs_leader',
        ]);

        foreach ($leaders as $leader) {
            SessionGroupLeader::create(['club_id' => 1, 'group_id' => $group->id, 'member_id' => $leader->id]);
        }

        return $group;
    }

    protected function attend(ClubSession $session, ClubMember $member, string $status = 'going', ?SessionGroup $group = null, array $extra = []): SessionAttendee
    {
        return SessionAttendee::create([
            'club_id' => 1,
            'session_id' => $session->id,
            'member_id' => $member->id,
            'group_id' => $group ? $group->id : null,
            'status' => $status,
        ] + $extra);
    }

    protected function sessionUpdatedAt(ClubSession $session): string
    {
        return (string) ClubSession::find($session->id)->getRawOriginal('updated_at');
    }

    /** Moves the clock on so a touch is visible at second precision. */
    protected function tick(int $seconds = 60): void
    {
        Carbon::setTestNow(Carbon::now()->addSeconds($seconds));
    }
}
