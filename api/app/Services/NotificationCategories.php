<?php

namespace App\Services;

use App\Models\ClubMember;

/**
 * The single source of truth for notification categories (see
 * mobile/docs/data-model.md). The preferences endpoints, the push decision
 * and the Android channel ids all read from here.
 */
class NotificationCategories
{
    const CLUB_UPDATES = 'club_updates';
    const RUN_REMINDERS = 'run_reminders';
    const GROUP_MATCHES = 'group_matches';
    const MY_GROUP_CHANGES = 'my_group_changes';
    const LEADERS_NEEDED = 'leaders_needed';
    const GROUP_MESSAGES = 'group_messages';

    /**
     * Definitions in display order.
     *
     *  default    true, false, or 'leader' (on only for members with the leader role)
     *  locked     can't be turned off
     *  visible    true, or a list of roles of which the member needs one. Every
     *             member can offer to lead (D12), so nothing is hidden today.
     */
    public static function definitions(): array
    {
        return [
            self::CLUB_UPDATES => [
                'label' => 'Club updates',
                'description' => 'News and notices from the committee. Important posts are always sent.',
                'default' => true,
                'locked' => false,
                'visible' => true,
            ],
            self::RUN_REMINDERS => [
                'label' => 'Run reminders',
                'description' => 'A nudge before a run you are going to.',
                'default' => true,
                'locked' => false,
                'visible' => true,
            ],
            self::GROUP_MATCHES => [
                'label' => 'Matching groups',
                'description' => 'A group in your pace range is added to a run you are going to.',
                'default' => true,
                'locked' => false,
                'visible' => true,
            ],
            self::MY_GROUP_CHANGES => [
                'label' => 'Changes to my runs',
                'description' => 'Your group or run is cancelled or moved, or its leader withdraws.',
                'default' => true,
                'locked' => true,
                'visible' => true,
            ],
            self::LEADERS_NEEDED => [
                'label' => 'Leaders needed',
                'description' => 'Runs that need a leader.',
                'default' => 'leader',
                'locked' => false,
                'visible' => true,
            ],
            self::GROUP_MESSAGES => [
                'label' => 'Group messages',
                'description' => 'New messages in groups you have joined.',
                'default' => true,
                'locked' => false,
                'visible' => true,
            ],
        ];
    }

    public static function keys(): array
    {
        return array_keys(self::definitions());
    }

    public static function exists(string $category): bool
    {
        return isset(self::definitions()[$category]);
    }

    public static function isLocked(string $category): bool
    {
        return self::definitions()[$category]['locked'] ?? false;
    }

    /** Categories this member sees in the preferences screen. */
    public static function visibleFor(ClubMember $member): array
    {
        return array_filter(self::definitions(), function ($def) use ($member) {
            return $def['visible'] === true
                || count(array_intersect($def['visible'], $member->roles ?? [])) > 0;
        });
    }

    public static function defaultFor(string $category, ClubMember $member): bool
    {
        $default = self::definitions()[$category]['default'] ?? false;

        if ($default === 'leader') {
            return in_array('leader', $member->roles ?? [], true);
        }

        return (bool) $default;
    }
}
