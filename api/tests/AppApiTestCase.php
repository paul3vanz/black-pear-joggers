<?php

use App\Models\Club;
use App\Models\ClubMember;
use App\Models\MemberLogin;
use Illuminate\Support\Carbon;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Shared setup for the /app endpoint tests: in-memory SQLite, the new
 * migrations, minimal versions of the legacy tables, fake Auth0 via the
 * X-Test-Sub header, and small helpers.
 *
 * The base athletes, users, payments and memberships tables have no migrations
 * in the repo, so setUp creates minimal versions with only the columns the
 * code touches, then runs the new migrations.
 */
abstract class AppApiTestCase extends TestCase
{
    protected const DOB = '1983-01-01';

    protected function setUp(): void
    {
        parent::setUp();

        $this->app->configure('database');
        config([
            'database.default' => 'sqlite',
            'database.connections.sqlite' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
                'foreign_key_constraints' => true,
            ],
        ]);
        $this->app['db']->purge();

        // The real log stack writes to MySQL and Slack.
        $this->app->configure('logging');
        config([
            'logging.default' => 'testing_null',
            'logging.channels.testing_null' => ['driver' => 'monolog', 'handler' => \Monolog\Handler\NullHandler::class],
        ]);

        $this->createBaseTables();
        $this->runMigrations([
            '2026_10_06_090000_create_clubs_table.php',
            '2026_10_06_090100_create_club_members_table.php',
            '2026_10_06_090200_create_member_logins_table.php',
            '2026_10_06_090300_create_member_link_attempts_table.php',
            '2026_10_07_090000_create_devices_table.php',
            '2026_10_07_090100_create_posts_table.php',
            '2026_10_07_090200_create_notifications_table.php',
            '2026_10_07_090300_create_notification_preferences_table.php',
        ]);

        // Stand in for the Auth0 verification: the sub comes from a header.
        $this->app['auth']->viaRequest('api', function ($request) {
            return $request->header('X-Test-Sub')
                ? ['sub' => $request->header('X-Test-Sub'), 'permissions' => []]
                : null;
        });
    }

    protected function createBaseTables(): void
    {
        Schema::create('athletes', function (Blueprint $table) {
            $table->integer('id')->primary();
            $table->integer('urn');
            $table->integer('athlete_id')->nullable();
            $table->string('po10_guid')->nullable();
            $table->string('first_name');
            $table->string('last_name');
            $table->string('gender');
            $table->date('dob');
        });

        Schema::create('users', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->integer('athleteId')->nullable();
            $table->timestamp('createdDate')->nullable();
            $table->timestamp('updatedDate')->nullable();
        });

        Schema::create('payments', function (Blueprint $table) {
            $table->integer('urn');
            $table->string('paymentStatus');
            $table->string('membershipType');
        });

        Schema::create('memberships', function (Blueprint $table) {
            $table->integer('urn')->primary();
            $table->string('competitiveRegStatus');
            $table->string('firstClaimClubName')->nullable();
        });
    }

    protected function runMigrations(array $files): void
    {
        foreach ($files as $file) {
            (require base_path('database/migrations/' . $file))->up();
        }
    }

    protected function makeAthlete(array $overrides = []): void
    {
        DB::table('athletes')->insert($overrides + [
            'id' => 123,
            'urn' => 1234567,
            'athlete_id' => 450606,
            'po10_guid' => 'a1b2c3d4-0000-0000-0000-000000000001',
            'first_name' => 'Jo',
            'last_name' => 'Bloggs',
            'gender' => 'W',
            'dob' => self::DOB,
        ]);
    }

    protected function registerAthlete(int $urn = 1234567): void
    {
        DB::table('memberships')->insert([
            'urn' => $urn,
            'competitiveRegStatus' => 'Registered',
            'firstClaimClubName' => 'Black Pear Joggers',
        ]);
    }

    protected function call_(string $method, string $uri, ?string $sub, array $data = []): array
    {
        // The guard caches the resolved user for the life of the app instance.
        $this->app['auth']->forgetGuards();

        $headers = $sub ? ['X-Test-Sub' => $sub] : [];
        $this->json($method, $uri, $data, $headers);

        return [
            $this->response->getStatusCode(),
            json_decode($this->response->getContent(), true),
        ];
    }

    protected function link(string $sub, int $urn = 1234567, string $dob = self::DOB, int $clubId = 1): array
    {
        return $this->call_('POST', "/app/clubs/$clubId/link", $sub, ['urn' => $urn, 'dob' => $dob]);
    }

    /** Creates an athlete, a club member and a login in one go. */
    protected function member(string $sub, int $athleteId, array $roles = [], string $status = 'active', ?string $name = null): ClubMember
    {
        DB::table('athletes')->insert([
            'id' => $athleteId,
            'urn' => 1000000 + $athleteId,
            'athlete_id' => $athleteId,
            'first_name' => $name ?? "First$athleteId",
            'last_name' => "Last$athleteId",
            'gender' => 'M',
            'dob' => '1980-01-01',
        ]);

        $member = ClubMember::create([
            'club_id' => 1,
            'athlete_id' => $athleteId,
            'display_name' => $name ? "$name Last$athleteId" : "First$athleteId Last$athleteId",
            'roles' => $roles,
            'status' => $status,
        ]);

        MemberLogin::create(['club_id' => 1, 'member_id' => $member->id, 'user_id' => $sub, 'linked_at' => Carbon::now()]);

        return $member;
    }
}
