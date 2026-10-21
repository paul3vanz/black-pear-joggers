<?php

namespace App\Services;

use App\Models\Club;
use App\Models\ClubMember;
use App\Models\Post;
use App\Models\PostComment;
use App\Models\PostThreadState;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Who can read and write the comments on a club update (D126). Everyone the
 * update is for can read and write them, a Q&A the whole audience sees; the
 * committee (committee and admin) moderates and replies. Nothing is stored apart
 * from the comments and each member's read/mute row.
 *
 * Who hears about a new comment: the committee, everyone who has commented and
 * everyone who has opened the thread, minus the author and anyone who muted it.
 */
class PostThreadAccess
{
    /** The thread id the app uses where a group id would go: `post:<postId>`. */
    const PREFIX = 'post:';

    /** Days of comments the thread list looks back over. */
    const RECENT_DAYS = 14;

    public Post $post;

    /** @var string[]|null */
    private ?array $commenterIds = null;

    /** @var string[]|null */
    private ?array $openerIds = null;

    public function __construct(Post $post)
    {
        $this->post = $post;
    }

    public static function threadId(Post $post): string
    {
        return self::PREFIX . $post->id;
    }

    /** The thread of a live post of this club, or null (404). */
    public static function find(Club $club, $postId): ?self
    {
        $post = Post::where('club_id', $club->id)->find($postId);

        return $post && !$post->trashed() ? new self($post) : null;
    }

    // ---- who ------------------------------------------------------------------------

    public function isStaff(ClubMember $member): bool
    {
        return $member->hasRole('committee', 'admin');
    }

    /** May read and write: anyone the update is for. */
    public function canAccess(ClubMember $member): bool
    {
        return in_array($this->post->audience, $member->audiences(), true);
    }

    /** May delete other people's comments and close the thread. */
    public function canModerate(ClubMember $member): bool
    {
        return $this->isStaff($member);
    }

    /** Active committee and admin members. @return string[] */
    public function staffIds(): array
    {
        return ClubMember::where('club_id', $this->post->club_id)
            ->where('status', 'active')
            ->get()
            ->filter(fn (ClubMember $m) => $m->hasRole('committee', 'admin'))
            ->pluck('id')->all();
    }

    /** Members with a comment (not deleted) here. @return string[] */
    public function commenterIds(): array
    {
        return $this->commenterIds ??= PostComment::where('post_id', $this->post->id)->pluck('member_id')->unique()->values()->all();
    }

    /** Members who opened the thread (they have a state row). @return string[] */
    public function openerIds(): array
    {
        return $this->openerIds ??= PostThreadState::where('post_id', $this->post->id)->pluck('member_id')->all();
    }

    /** Everyone who hears about new comments (before muting and the author are removed). @return string[] */
    public function participantIds(): array
    {
        return array_values(array_unique(array_merge($this->staffIds(), $this->commenterIds(), $this->openerIds())));
    }

    /** Comments are closed for everyone but the committee. */
    public function isClosedFor(ClubMember $member): bool
    {
        return $this->post->commentsClosed() && !$this->isStaff($member);
    }

    public function closedMessage(): string
    {
        return 'The committee has closed comments on this update.';
    }

    // ---- people ----------------------------------------------------------------------

    /**
     * Name and role for each member id ('committee' or 'member').
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
                'role' => array_intersect(['committee', 'admin'], $roles) ? ThreadAccess::ROLE_COMMITTEE : ThreadAccess::ROLE_MEMBER,
            ];
        }

        foreach ($memberIds as $id) {
            $people[$id] ??= ['name' => 'Member', 'role' => ThreadAccess::ROLE_MEMBER];
        }

        return $people;
    }

    // ---- listing ---------------------------------------------------------------------

    /**
     * The comment threads $member is in (committee: all; others: ones they wrote
     * in or opened) that have a recent comment, as items of `GET /threads` with
     * `kind` = `post`, `label` = the update's title, each with a sort key.
     *
     * @return array<int, array{sort: array, item: array}>
     */
    public static function listFor(Club $club, ClubMember $member): array
    {
        $since = Carbon::now()->subDays(self::RECENT_DAYS);
        $recent = PostComment::where('club_id', $club->id)->where('created_at', '>=', $since)
            ->select('post_id')->distinct()->pluck('post_id')->all();

        if (!$recent) {
            return [];
        }

        $states = PostThreadState::where('member_id', $member->id)->whereIn('post_id', $recent)->get()->keyBy('post_id');
        $wrote = PostComment::where('member_id', $member->id)->whereIn('post_id', $recent)->pluck('post_id')->all();
        $items = [];

        foreach (Post::where('club_id', $club->id)->whereIn('id', $recent)->get() as $post) {
            $thread = new self($post);

            if ($post->trashed() || !$thread->canAccess($member)) {
                continue;
            }

            $state = $states->get($post->id);

            if (!$thread->isStaff($member) && !$state && !in_array($post->id, $wrote, true)) {
                continue;
            }

            $last = PostComment::where('post_id', $post->id)->where('created_at', '>=', $since)
                ->orderByDesc('created_at')->orderByDesc('id')->first();

            if (!$last) {
                continue; // only deleted comments in the window
            }

            $items[] = [
                'sort' => [$last->created_at->getTimestamp(), $last->id],
                'item' => [
                    'kind' => 'post',
                    'groupId' => self::threadId($post),
                    'sessionId' => null,
                    'label' => $post->title,
                    'sessionTitle' => $post->title,
                    'localDate' => null,
                    'localStartTime' => null,
                    'lastMessage' => [
                        'authorName' => $thread->people([$last->member_id])[$last->member_id]['name'],
                        'body' => (string) $last->body,
                        'createdAt' => NotificationPresenter::time($last->created_at),
                    ],
                    'unreadCount' => $thread->unreadCount($member, $state),
                    'muted' => $state ? (bool) $state->muted : false,
                    'closed' => $post->commentsClosed(),
                ],
            ];
        }

        return $items;
    }

    public function unreadCount(ClubMember $member, ?PostThreadState $state): int
    {
        $query = PostComment::where('post_id', $this->post->id)->where('member_id', '!=', $member->id);

        if ($state && $state->last_read_at) {
            $query->where('created_at', '>', $state->last_read_at);
        }

        return $query->count();
    }
}
