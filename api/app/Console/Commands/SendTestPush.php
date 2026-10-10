<?php

namespace App\Console\Commands;

use App\Jobs\SendPushNotificationsJob;
use App\Models\Club;
use App\Models\ClubMember;
use App\Models\ClubSession;
use App\Models\Device;
use App\Models\MemberLogin;
use App\Models\Notification;
use App\Services\FcmClient;
use App\Services\NotificationCategories;
use App\Services\NotificationService;
use Illuminate\Console\Command;

/**
 * Sends one real push to one member from the host console, synchronously, so
 * the first FCM send (D37) can be checked without waiting for the queue.
 *
 *   php artisan app:send-test-push 1 123
 *   php artisan app:send-test-push 1 123 --actions --session=<session uuid>
 *
 * The athlete is identified by athletes.id, like app:member-role. The inbox
 * row is written through NotificationService (forced, so the member's
 * settings and daily cap don't block it); the push job is then run inline.
 * The same job is also queued by the service: it skips rows already pushed.
 */
class SendTestPush extends Command
{
    protected $signature = 'app:send-test-push {clubId : clubs.id} {athleteId : athletes.id} {--actions : send a run reminder with going/not_going buttons (needs --session)} {--session= : sessions.id for --actions}';

    protected $description = 'Send a test push to a club member and report whether it reached FCM';

    public function handle()
    {
        $club = Club::find((int) $this->argument('clubId'));
        if (!$club) {
            $this->error('No such club.');

            return 1;
        }

        $member = ClubMember::where('club_id', $club->id)->where('athlete_id', (int) $this->argument('athleteId'))->first();
        if (!$member) {
            $this->error('No such club member. They must have linked their membership in the app first.');

            return 1;
        }

        $category = NotificationCategories::CLUB_UPDATES;
        $title = 'Test push';
        $body = 'If you can see this on your phone, push notifications are working.';
        $data = ['route' => '/updates'];

        if ($this->option('actions')) {
            $session = $this->option('session')
                ? ClubSession::where('club_id', $club->id)->find($this->option('session'))
                : null;

            if (!$session) {
                $this->error('--actions needs --session=<sessions.id> of a run in this club.');

                return 1;
            }

            $category = NotificationCategories::RUN_REMINDERS;
            $title = 'Test reminder: ' . $session->title;
            $body = 'Are you coming?';
            $data = [
                'route' => '/runs/' . $session->id,
                'sessionId' => $session->id,
                'actions' => ['going', 'not_going'],
                'actionToken' => NotificationService::newActionToken(),
            ];
        }

        $userIds = MemberLogin::where('member_id', $member->id)->pluck('user_id');
        $devices = Device::whereIn('user_id', $userIds)->count();
        $fcm = app(FcmClient::class);

        $this->info($member->display_name . ': ' . $devices . ' device(s) registered.');
        $this->info('FCM configured: ' . ($fcm->isConfigured() ? 'yes' : 'no (set FCM_SERVICE_ACCOUNT_PATH in .env)'));

        $rows = app(NotificationService::class)->notifyMembers($club, [$member->id], $category, $title, $body, $data, true);
        $ids = array_map(function ($row) {
            return $row->id;
        }, $rows);

        (new SendPushNotificationsJob($ids))->handle($fcm);

        $allPushed = true;
        foreach (Notification::whereIn('id', $ids)->get() as $row) {
            $pushed = $row->pushed_at !== null;
            $allPushed = $allPushed && $pushed;
            $this->line($row->category . ' ' . $row->id . ' pushed_at: ' . ($pushed ? $row->pushed_at->toDateTimeString() : 'not set'));
        }

        if (!$allPushed) {
            $this->warn('Nothing was accepted by FCM. Check the device count and FCM setting above, then storage/logs.');

            return 1;
        }

        return 0;
    }
}
