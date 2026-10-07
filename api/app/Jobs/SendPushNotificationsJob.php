<?php

namespace App\Jobs;

use App\Models\Device;
use App\Models\MemberLogin;
use App\Models\Notification;
use App\Services\FcmClient;
use Illuminate\Support\Carbon;

/**
 * Pushes already-written inbox notifications to the members' devices.
 *
 * member -> every member_logins.user_id -> every devices row. Runs on the
 * `notifications` queue, drained each minute by the scheduler. Sets pushed_at
 * on each notification that at least one device accepted. With FCM
 * unconfigured it does nothing (the inbox rows are already there).
 */
class SendPushNotificationsJob extends Job
{
    /** Retrying would re-send to devices that already got it. */
    public $tries = 1;

    /** @var string[] */
    protected $notificationIds;

    public function __construct(array $notificationIds)
    {
        $this->notificationIds = array_values($notificationIds);
        $this->onQueue('notifications');
    }

    public function notificationIds(): array
    {
        return $this->notificationIds;
    }

    public function handle(FcmClient $fcm)
    {
        if (!$fcm->isConfigured()) {
            return;
        }

        $notifications = Notification::whereIn('id', $this->notificationIds)
            ->whereNull('pushed_at')
            ->get();

        if ($notifications->isEmpty()) {
            return;
        }

        // member_id => user ids, then user id => devices
        $logins = MemberLogin::whereIn('member_id', $notifications->pluck('member_id')->unique())
            ->get(['member_id', 'user_id'])
            ->groupBy('member_id');

        $devices = Device::whereIn('user_id', $logins->flatten()->pluck('user_id')->unique())
            ->get()
            ->groupBy('user_id');

        $pairs = [];
        foreach ($notifications as $notification) {
            foreach ($logins->get($notification->member_id, []) as $login) {
                foreach ($devices->get($login->user_id, []) as $device) {
                    $pairs[] = [$device, $notification];
                }
            }
        }

        $delivered = $fcm->send($pairs);

        if ($delivered) {
            Notification::whereIn('id', array_keys($delivered))
                ->update(['pushed_at' => Carbon::now()]);
        }
    }
}
