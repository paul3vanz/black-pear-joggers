<?php

namespace App\Jobs;

use App\Services\RunNotifier;

/**
 * "A group at your pace was added to a run" (group_matches). Queued with a short
 * delay when a group is created with a pace, or its pace changes, so a leader can
 * fix a typo before anyone is told. It re-checks everything when it runs: a group
 * that was deleted or lost its pace, or a run that is cancelled or over, sends nothing.
 */
class NotifyMatchingGroupJob extends Job
{
    /** Running it twice would only hit the dedupe key, but there is nothing to retry. */
    public $tries = 1;

    /** @var string */
    protected $groupId;

    /** @var string|null the member who made the change, who is never notified */
    protected $actorId;

    public function __construct(string $groupId, ?string $actorId = null)
    {
        $this->groupId = $groupId;
        $this->actorId = $actorId;
        $this->onQueue('notifications');
    }

    public function groupId(): string
    {
        return $this->groupId;
    }

    public function handle(RunNotifier $notifier)
    {
        $notifier->matchGroup($this->groupId, $this->actorId);
    }
}
