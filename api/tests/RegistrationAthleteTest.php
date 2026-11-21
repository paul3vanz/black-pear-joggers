<?php

require_once __DIR__ . '/AppApiTestCase.php';

use App\Http\Controllers\MembershipController;
use App\Http\Controllers\RegistrationController;
use App\Models\Athlete;
use App\Models\Registration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * A verified registration becomes an athlete even when Power of 10 cannot be
 * reached, so the member can link their membership in the app by urn and dob.
 */
class RegistrationAthleteTest extends AppApiTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // Production athletes carry timestamps; the minimal test table does not.
        Schema::table('athletes', function ($table) {
            $table->timestamps();
        });

        Schema::create('registration', function ($table) {
            $table->increments('id');
            $table->integer('urn');
            $table->string('firstName')->nullable();
            $table->string('lastName')->nullable();
            $table->string('gender')->nullable();
            $table->date('dateOfBirth')->nullable();
            $table->string('emailAddress')->nullable();
            $table->string('notes')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function testCreatesAthleteWithoutPowerOfTenIdsAndRemovesRegistration()
    {
        $this->makeAthlete(['id' => 500, 'urn' => 1111111]);
        $registration = Registration::create([
            'urn' => 3706350, 'firstName' => 'Sam', 'lastName' => 'Runner',
            'gender' => 'M', 'dateOfBirth' => '1980-02-03',
            'notes' => 'Needs an athlete id adding by hand: Power of 10 can no longer be searched by URN.',
        ]);

        $controller = new RegistrationController(new MembershipController());
        $athlete = $controller->createAthleteFromRegistration($registration, 'Sam', 'Runner');

        $this->assertGreaterThan(500, $athlete->id);
        $row = DB::table('athletes')->where('urn', 3706350)->first();
        $this->assertNull($row->athlete_id);
        $this->assertNull($row->po10_guid);
        $this->assertSame('1980-02-03', $row->dob);
        $this->assertSame(0, Registration::withTrashed()->count());
    }

    public function testDoesNotDuplicateAnExistingAthlete()
    {
        $this->makeAthlete(['id' => 7, 'urn' => 3706350]);
        $registration = Registration::create(['urn' => 3706350, 'gender' => 'M', 'dateOfBirth' => '1980-02-03']);

        (new RegistrationController(new MembershipController()))
            ->createAthleteFromRegistration($registration, 'Sam', 'Runner');

        $this->assertSame(1, Athlete::where('urn', 3706350)->count());
    }
}
