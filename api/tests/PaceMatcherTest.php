<?php

use App\Models\MemberPreference;
use App\Models\SessionAttendee;
use App\Models\SessionGroup;
use App\Services\PaceMatcher;
use PHPUnit\Framework\TestCase as BaseTestCase;

/**
 * The server-side pace rule (D28): single paces get +/-15 s/km, ranges are exact,
 * bands touching counts as a match, no pace never matches.
 */
class PaceMatcherTest extends BaseTestCase
{
    private function group(?string $unit, $from, $to = null): SessionGroup
    {
        return new SessionGroup(['pace_unit' => $unit, 'pace_from_s' => $from, 'pace_to_s' => $to]);
    }

    private function pref(?string $unit, $from, $to = null): MemberPreference
    {
        return new MemberPreference(['pace_unit' => $unit, 'pace_from_s' => $from, 'pace_to_s' => $to]);
    }

    private function answer(?string $unit, $from, $to = null): SessionAttendee
    {
        return new SessionAttendee(['status' => 'going', 'pace_unit' => $unit, 'pace_from_s' => $from, 'pace_to_s' => $to]);
    }

    public function testBandsAreNormalisedToSecondsPerKm()
    {
        // 9:30/mi is 354 s/km (rounded), 10:00/mi is 373.
        $this->assertSame([339, 369], PaceMatcher::band('mi', 570, null));
        $this->assertSame([339, 369], PaceMatcher::band('mi', 570, 570));
        $this->assertSame([354, 373], PaceMatcher::band('mi', 570, 600));
        $this->assertSame([300, 330], PaceMatcher::band('km', 300, 330));
        $this->assertSame([285, 315], PaceMatcher::band('km', 300, null));
    }

    public function testNoPaceHasNoBand()
    {
        $this->assertNull(PaceMatcher::band(null, null, null));
        $this->assertNull(PaceMatcher::band('mi', null, null));
        $this->assertNull(PaceMatcher::band(null, 570, null));
        $this->assertNull(PaceMatcher::groupBand($this->group(null, null)));
    }

    public function testASwappedRangeIsPutTheRightWayRound()
    {
        $this->assertSame([300, 330], PaceMatcher::band('km', 330, 300));
    }

    public function testSinglePacesMatchWithinThirtySecondsPerKm()
    {
        $a = PaceMatcher::band('km', 300, null); // 285-315
        $this->assertTrue(PaceMatcher::overlaps($a, PaceMatcher::band('km', 330, null))); // 315-345 touches
        $this->assertFalse(PaceMatcher::overlaps($a, PaceMatcher::band('km', 331, null)));
        $this->assertTrue(PaceMatcher::overlaps($a, PaceMatcher::band('km', 270, null))); // 255-285 touches
        $this->assertFalse(PaceMatcher::overlaps($a, PaceMatcher::band('km', 269, null)));
    }

    public function testRangesAreExactAndSinglesAreWidened()
    {
        $range = PaceMatcher::band('km', 300, 330);

        $this->assertTrue(PaceMatcher::overlaps($range, PaceMatcher::band('km', 345, null))); // 330-360
        $this->assertFalse(PaceMatcher::overlaps($range, PaceMatcher::band('km', 346, null)));
        $this->assertTrue(PaceMatcher::overlaps($range, PaceMatcher::band('km', 315, 400)));
        $this->assertTrue(PaceMatcher::overlaps($range, PaceMatcher::band('km', 200, 300))); // touches at 300
        $this->assertFalse(PaceMatcher::overlaps($range, PaceMatcher::band('km', 200, 299)));
        $this->assertTrue(PaceMatcher::overlaps(PaceMatcher::band('km', 100, 500), $range)); // contains
    }

    public function testUnitsAreComparedInSecondsPerKm()
    {
        // 9:00/mi = 336 s/km, 5:36/km: the same pace in two units.
        $this->assertTrue(PaceMatcher::overlaps(PaceMatcher::band('mi', 540, null), PaceMatcher::band('km', 336, null)));
        $this->assertFalse(PaceMatcher::overlaps(PaceMatcher::band('mi', 540, null), PaceMatcher::band('km', 400, null)));
    }

    public function testNoPaceNeverMatches()
    {
        $band = PaceMatcher::band('km', 300, 330);

        $this->assertFalse(PaceMatcher::overlaps(null, $band));
        $this->assertFalse(PaceMatcher::overlaps($band, null));
        $this->assertFalse(PaceMatcher::overlaps(null, null));
    }

    public function testAMembersRunAnswerBeatsTheirUsualRange()
    {
        $pref = $this->pref('mi', 540, 600);

        $this->assertSame([336, 373], PaceMatcher::memberBand(null, $pref));
        $this->assertSame([336, 373], PaceMatcher::memberBand($this->answer(null, null), $pref));
        $this->assertSame([336, 373], PaceMatcher::memberBand($this->answer('mi', null), $pref)); // a unit alone is no pace
        $this->assertSame([300, 330], PaceMatcher::memberBand($this->answer('km', 300, 330), $pref));
        $this->assertNull(PaceMatcher::memberBand(null, null));
        $this->assertNull(PaceMatcher::memberBand($this->answer(null, null), $this->pref('mi', null)));
    }

    public function testMemberFitsGroup()
    {
        $group = $this->group('mi', 570, 600); // 354-373 s/km
        $pref = $this->pref('mi', 540, 600);

        $this->assertTrue(PaceMatcher::memberFitsGroup(null, $pref, $group));
        $this->assertFalse(PaceMatcher::memberFitsGroup(null, $this->pref('mi', 420, 450), $group));
        $this->assertFalse(PaceMatcher::memberFitsGroup(null, null, $group));
        $this->assertFalse(PaceMatcher::memberFitsGroup(null, $pref, $this->group(null, null)));
        // The answer for this run wins over the usual range.
        $this->assertFalse(PaceMatcher::memberFitsGroup($this->answer('mi', 420, 450), $pref, $group));
        $this->assertTrue(PaceMatcher::memberFitsGroup($this->answer('mi', 570, null), $this->pref('mi', 420, 450), $group));
    }

    public function testFormatInTheViewersUnit()
    {
        $this->assertSame('9:00-9:30/mi', PaceMatcher::format('mi', 540, 570, 'mi'));
        $this->assertSame('9:30/mi', PaceMatcher::format('mi', 570, null, 'mi'));
        $this->assertSame('9:30/mi', PaceMatcher::format('mi', 570, 570, 'mi'));
        $this->assertSame('5:00-5:30/km', PaceMatcher::format('km', 300, 330, 'km'));
        $this->assertSame('5:36-5:54/km', PaceMatcher::format('mi', 540, 570, 'km'));
        $this->assertSame('9:30/mi', PaceMatcher::format('km', 354, null, 'mi'));
        $this->assertSame('9:05/mi', PaceMatcher::format('mi', 545, null, null)); // no unit: miles
        $this->assertSame('', PaceMatcher::format('mi', null, null, 'mi'));
        $this->assertSame('', PaceMatcher::format(null, 540, null, 'mi'));
        $this->assertSame('6:05/mi', PaceMatcher::format('mi', 365, null, 'mi'));
    }

    public function testFormatGroup()
    {
        $this->assertSame('9:00-9:30/mi', PaceMatcher::formatGroup($this->group('mi', 540, 570), 'mi'));
        $this->assertSame('', PaceMatcher::formatGroup($this->group(null, null), 'km'));
    }
}
