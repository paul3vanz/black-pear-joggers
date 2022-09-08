<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Http\Controllers\MembershipController;
use Log;

class QueueFetchMemberships extends Command
{
    protected $name = 'queue:fetch:memberships';

    public function handle()
    {
        Log::channel('slackInfo')->info('QueueFetchMemberships');
        $membershipController = new MembershipController();
        $membershipController->storeClubMembers();
    }
}
