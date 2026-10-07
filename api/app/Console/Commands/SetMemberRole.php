<?php

namespace App\Console\Commands;

use App\Models\ClubMember;
use Illuminate\Console\Command;

/**
 * Grants or revokes a role on a club member. Roles live on club_members.roles
 * (per club), not in Auth0.
 *
 *   php artisan app:member-role 1 123 committee
 *   php artisan app:member-role 1 123 committee --remove
 *
 * The athlete is identified by athletes.id (the club's internal athlete id,
 * the same value as club_members.athlete_id and `athlete.id` in the API).
 */
class SetMemberRole extends Command
{
    const ROLES = ['leader', 'committee', 'admin'];

    protected $signature = 'app:member-role {clubId : clubs.id} {athleteId : athletes.id (not the EA athlete_id or urn)} {role : leader|committee|admin} {--remove : revoke instead of grant}';

    protected $description = 'Grant or revoke a leader/committee/admin role on a club member';

    public function handle()
    {
        $role = $this->argument('role');

        if (!in_array($role, self::ROLES, true)) {
            $this->error('Role must be one of: ' . implode(', ', self::ROLES));

            return 1;
        }

        $member = ClubMember::where('club_id', (int) $this->argument('clubId'))
            ->where('athlete_id', (int) $this->argument('athleteId'))
            ->first();

        if (!$member) {
            $this->error('No such club member. They must have linked their membership in the app first.');

            return 1;
        }

        $roles = $member->roles ?? [];

        $roles = $this->option('remove')
            ? array_values(array_diff($roles, [$role]))
            : array_values(array_unique(array_merge($roles, [$role])));

        $member->roles = $roles;
        $member->save();

        $this->info($member->display_name . ' roles: ' . ($roles ? implode(', ', $roles) : '(none)'));

        return 0;
    }
}
