<?php

namespace App\Services;

use App\Models\Club;
use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Who is in a group's chat thread, who may moderate it, and whether it has
 * closed (Phase 6, D39-D41). Everything is computed live from the group, its
 * leaders, the run's coordinator and the attendance rows; nothing is stored.
 *
 * One instance is one thread. Used by AppGroupMessageController and by the
 * notification code, so the two always agree on the audience.
 */
class ThreadAccess
{
    /** Hours after the run ends that posting stays open. */
    const CLOSES_AFTER_HOURS = 12;

    const ROLE_LEADER = 'leader';
    const ROLE_COORDINATOR = 'coordinator';
    const ROLE_COMMITTEE = 'committee';
    const ROLE_MEMBER = 'member';

    public SessionGroup $group;
    public ClubSession $session;

    /** @var string[]|null */
    private ?array $leaderIds = null;

    /** @var string[]|null */
    private ?array $attendeeIds = null;

    public function __construct(SessionGroup $group, ClubSession $session)
    {
        $this->group = $group;
        $this->session = $session;
    }

    /**
     * The thread of a live group of this club on a live session, or null (404).
     */
    public static function find(Club $club, $groupId): ?self
    {
        $group = SessionGroup::where('club_id', $club->id)->find($groupId);

        if (!$group) {
            return null;
        }

        $session = $group->session;

        return $session && !$session->trashed() ? new self($group, $session) : null;
    }

    // ---- who ------------------------------------------------------------------------

    /** Confirmed leaders of this group. @return string[] */
    public function leaderIds(): array
    {
        return $this->leaderIds ??= SessionGroupLeader::where('group_id', $this->group->id)
            ->where('status', SessionGroupLeader::CONFIRMED)
            ->pluck('member_id')->all();
    }

    /** Going or maybe attendees whose group is this one. @return string[] */
    public function attendeeIds(): array
    {
        return $this->attendeeIds ??= SessionAttendee::where('group_id', $this->group->id)
            ->whereIn('status', [SessionAttendee::GOING, SessionAttendee::MAYBE])
            ->pluck('member_id')->all();
    }

    public function coordinatorId(): ?string
    {
        return $this->session->coordinator_member_id;
    }

    public function isLeader(ClubMember $member): bool
    {
        return in_array($member->id, $this->leaderIds(), true);
    }

    public function isCoordinator(ClubMember $member): bool
    {
        return $this->coordinatorId() !== null && $this->coordinatorId() === $member->id;
    }

    /** Committee or admin: may read, post and moderate every thread. */
    public function isStaff(ClubMember $member): bool
    {
        return $member->hasRole('committee', 'admin');
    }

    /** May read and post. */
    public function canAccess(ClubMember $member): bool
    {
        return $this->isLeader($member)
            || $this->isCoordinator($member)
            || $this->isStaff($member)
            || in_array($member->id, $this->attendeeIds(), true);
    }

    /** May delete other people's messages. */
    public function canModerate(ClubMember $member): bool
    {
        return $this->isLeader($member) || $this->isCoordinator($member) || $this->isStaff($member);
    }

    /**
     * The members who hear about new messages: leaders, going/maybe attendees and the
     * coordinator. Committee and admin are left out unless they are also one of those.
     *
     * @return string[]
     */
    public function participantIds(): array
    {
        $ids = array_merge($this->leaderIds(), $this->attendeeIds(), $this->coordinatorId() !== null ? [$this->coordinatorId()] : []);

        return array_values(array_unique($ids));
    }

    // ---- closed ----------------------------------------------------------------------

    /** Posting is closed while the run is cancelled and from 12 hours after it ends. */
    public function isClosed(?Carbon $now = null): bool
    {
        if ($this->session->isCancelled()) {
            return true;
        }

        $end = $this->session->ends_at ?: $this->session->starts_at;

        return $end !== null && ($now ?: Carbon::now())->gte($end->copy()->addHours(self::CLOSES_AFTER_HOURS));
    }

    public function closedMessage(): string
    {
        return $this->session->isCancelled()
            ? 'This run has been cancelled, so the chat is closed.'
            : 'This run finished a while ago, so the chat is closed.';
    }

    // ---- people ----------------------------------------------------------------------

    /**
     * Name and role in this thread for each member id (also for people who have since
     * left the group or the club).
     *
     * @param  string[] $memberIds
     * @return array<string, array{name: string, role: string}>
     */
    public function people(array $memberIds): array
    {
        $memberIds = array_values(array_unique($memberIds));

        if (!$memberIds) {
            return [];
        }

        $rows = DB::table('club_members')
            ->leftJoin('athletes', 'athletes.id', '=', 'club_members.athlete_id')
            ->whereIn('club_members.id', $memberIds)
            ->get(['club_members.id', 'club_members.roles', 'athletes.first_name', 'athletes.last_name']);

        $people = [];

        foreach ($rows as $row) {
            $roles = json_decode((string) $row->roles, true) ?: [];
            $people[$row->id] = [
                'name' => self::shortName($row->first_name, $row->last_name),
                'role' => $this->roleFor($row->id, $roles),
            ];
        }

        foreach ($memberIds as $id) {
            $people[$id] ??= ['name' => 'Member', 'role' => self::ROLE_MEMBER];
        }

        return $people;
    }

    /** Leader of this group beats coordinator beats committee/admin beats member. */
    private function roleFor(string $memberId, array $roles): string
    {
        if (in_array($memberId, $this->leaderIds(), true)) {
            return self::ROLE_LEADER;
        }

        if ($this->coordinatorId() === $memberId) {
            return self::ROLE_COORDINATOR;
        }

        if (array_intersect(['committee', 'admin'], $roles)) {
            return self::ROLE_COMMITTEE;
        }

        return self::ROLE_MEMBER;
    }

    /** "Sam B." from the athlete record; "Member" when there is no usable name. */
    public static function shortName($first, $last): string
    {
        $first = trim((string) $first);
        $last = trim((string) $last);

        if ($first === '') {
            return 'Member';
        }

        return $last === '' ? $first : $first . ' ' . mb_strtoupper(mb_substr($last, 0, 1)) . '.';
    }

    /** The group as a short label in the viewer's units: "Jog/walk 9:00-9:30/mi", never empty. */
    public function label(?string $unit): string
    {
        return RunText::groupName($this->group, $unit) ?: 'Group';
    }
}
