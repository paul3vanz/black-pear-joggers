<?php

namespace App\Services;

use App\Models\Club;
use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\LeaderMessage;
use App\Models\LeaderThreadMember;
use App\Models\LeaderThreadState;
use App\Models\MemberPreference;
use App\Models\SessionGroup;
use App\Models\SessionGroupLeader;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Who is in a run's leaders thread and whether it is closed (D125). Like
 * ThreadAccess for a group's chat, everything is computed live; the only stored
 * membership is `leader_thread_members`, the people a committee ask went to.
 *
 * In the thread: committee and admin (always), the confirmed leaders of any
 * group of the run, and anyone an ask was sent to.
 */
class LeaderThreadAccess
{
    /** Hours after the run ends that posting stays open (same as a group chat). */
    const CLOSES_AFTER_HOURS = 12;

    /** The thread id the app uses where a group id would go: `leaders:<sessionId>`. */
    const PREFIX = 'leaders:';

    public ClubSession $session;

    /** @var string[]|null */
    private ?array $leaderIds = null;

    /** @var string[]|null */
    private ?array $askedIds = null;

    public function __construct(ClubSession $session)
    {
        $this->session = $session;
    }

    public static function threadId(ClubSession $session): string
    {
        return self::PREFIX . $session->id;
    }

    /** The thread of a live session of this club, or null (404). */
    public static function find(Club $club, $sessionId): ?self
    {
        $session = ClubSession::where('club_id', $club->id)->find($sessionId);

        return $session && !$session->trashed() ? new self($session) : null;
    }

    // ---- who ------------------------------------------------------------------------

    /** Confirmed leaders of any group of the run. @return string[] */
    public function leaderIds(): array
    {
        return $this->leaderIds ??= SessionGroupLeader::where('status', SessionGroupLeader::CONFIRMED)
            ->whereIn('group_id', SessionGroup::where('session_id', $this->session->id)->pluck('id'))
            ->pluck('member_id')->unique()->values()->all();
    }

    /** Members an ask was sent to. @return string[] */
    public function askedIds(): array
    {
        return $this->askedIds ??= LeaderThreadMember::where('session_id', $this->session->id)->pluck('member_id')->all();
    }

    /** Active committee and admin members of the club. @return string[] */
    public function staffIds(): array
    {
        return ClubMember::where('club_id', $this->session->club_id)
            ->where('status', 'active')
            ->get()
            ->filter(fn (ClubMember $m) => $m->hasRole('committee', 'admin'))
            ->pluck('id')->all();
    }

    public function isStaff(ClubMember $member): bool
    {
        return $member->hasRole('committee', 'admin');
    }

    /** May read and post. */
    public function canAccess(ClubMember $member): bool
    {
        return $this->isStaff($member)
            || in_array($member->id, $this->leaderIds(), true)
            || in_array($member->id, $this->askedIds(), true);
    }

    /** May delete other people's messages, and ask for leaders. */
    public function canModerate(ClubMember $member): bool
    {
        return $this->isStaff($member);
    }

    /** Everyone who hears about new messages. @return string[] */
    public function participantIds(): array
    {
        return array_values(array_unique(array_merge($this->staffIds(), $this->leaderIds(), $this->askedIds())));
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
            ? 'This run has been cancelled, so the thread is closed.'
            : 'This run finished a while ago, so the thread is closed.';
    }

    // ---- people ----------------------------------------------------------------------

    /**
     * Name and role for each member id ('committee', 'leader' or 'member').
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
                'name' => ThreadAccess::shortName($row->first_name, $row->last_name),
                'role' => array_intersect(['committee', 'admin'], $roles)
                    ? ThreadAccess::ROLE_COMMITTEE
                    : (in_array($row->id, $this->leaderIds(), true) ? ThreadAccess::ROLE_LEADER : ThreadAccess::ROLE_MEMBER),
            ];
        }

        foreach ($memberIds as $id) {
            $people[$id] ??= ['name' => 'Member', 'role' => ThreadAccess::ROLE_MEMBER];
        }

        return $people;
    }

    // ---- listing ---------------------------------------------------------------------

    /** Days of messages the thread list looks back over. */
    const RECENT_DAYS = 14;

    /**
     * The leaders threads $member is in that have a recent message, as items of
     * `GET /threads` (the same shape as a group thread, `kind` = `leaders`),
     * each with a sort key for merging.
     *
     * @return array<int, array{sort: array, item: array}>
     */
    public static function listFor(Club $club, ClubMember $member): array
    {
        $since = Carbon::now()->subDays(self::RECENT_DAYS);
        $recent = LeaderMessage::where('club_id', $club->id)->where('created_at', '>=', $since)
            ->select('session_id')->distinct()->pluck('session_id')->all();

        if (!$recent) {
            return [];
        }

        $unit = MemberPreference::where('club_id', $club->id)->where('member_id', $member->id)->value('pace_unit') === 'km' ? 'km' : 'mi';
        $states = LeaderThreadState::where('member_id', $member->id)->whereIn('session_id', $recent)->get()->keyBy('session_id');
        $items = [];

        foreach (ClubSession::where('club_id', $club->id)->whereIn('id', $recent)->get() as $session) {
            $thread = new self($session);

            if ($session->trashed() || !$thread->canAccess($member)) {
                continue;
            }

            $last = LeaderMessage::where('session_id', $session->id)->where('created_at', '>=', $since)
                ->orderByDesc('created_at')->orderByDesc('id')->first();

            if (!$last) {
                continue; // only deleted messages in the window
            }

            $state = $states->get($session->id);
            $items[] = [
                'sort' => [$last->created_at->getTimestamp(), $last->id],
                'item' => [
                    'kind' => 'leaders',
                    'groupId' => self::threadId($session),
                    'sessionId' => $session->id,
                    'label' => 'Leaders',
                    'sessionTitle' => $session->title,
                    'localDate' => $session->localDateYmd(),
                    'localStartTime' => $session->local_start_time,
                    'lastMessage' => [
                        'authorName' => $thread->people([$last->member_id])[$last->member_id]['name'],
                        'body' => self::preview($last, $unit),
                        'createdAt' => NotificationPresenter::time($last->created_at),
                    ],
                    'unreadCount' => $thread->unreadCount($member, $state),
                    'muted' => $state ? (bool) $state->muted : false,
                    'closed' => $thread->isClosed(),
                ],
            ];
        }

        return $items;
    }

    public function unreadCount(ClubMember $member, ?LeaderThreadState $state): int
    {
        $query = LeaderMessage::where('session_id', $this->session->id)->where('member_id', '!=', $member->id);

        if ($state && $state->last_read_at) {
            $query->where('created_at', '>', $state->last_read_at);
        }

        return $query->count();
    }

    /** One line for lists and pushes: the text, or what an ask is for in [unit]. */
    public static function preview(LeaderMessage $message, string $unit): string
    {
        if (!$message->isAsk()) {
            return (string) $message->body;
        }

        $pace = self::paceText($message, $unit);

        return trim('Can anyone lead' . ($pace !== '' ? " $pace" : '') . '?');
    }

    /** "8:25-10:05/mi" for an ask, empty when it has no pace. */
    public static function paceText(LeaderMessage $message, string $unit): string
    {
        if ($message->ask_fast_s_per_km === null) {
            return '';
        }

        return PaceMatcher::format('km', (int) $message->ask_fast_s_per_km, $message->ask_slow_s_per_km === null ? null : (int) $message->ask_slow_s_per_km, $unit);
    }
}
