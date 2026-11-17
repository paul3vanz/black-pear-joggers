<?php

use App\Services\PaceSpread;
use PHPUnit\Framework\TestCase as BaseTestCase;

/**
 * D134 (was D128): the pace spread rule, checked against the case table the app's tests read too
 * (tests/fixtures/spread_target_cases.json). The expected values there are worked by hand,
 * so this test and the Dart one each prove their own copy of the rule.
 */
class PaceSpreadTest extends BaseTestCase
{
    /** @return array<string, array{array}> */
    public function cases(): array
    {
        $table = json_decode(file_get_contents(__DIR__ . '/fixtures/spread_target_cases.json'), true);
        $cases = [];

        foreach ($table['cases'] as $case) {
            $cases[$case['name']] = [$case];
        }

        return $cases;
    }

    /** @dataProvider cases */
    public function testTheRuleMatchesTheSharedTable(array $case)
    {
        $bands = [];
        $jogWalk = false;

        foreach ($case['groups'] as $group) {
            if (($group['led'] ?? true) === false) {
                continue;
            }

            $band = PaceSpread::band($group['unit'] ?? null, $group['from'] ?? null, $group['to'] ?? null);

            if ($band !== null) {
                $bands[] = $band;
            } elseif (($group['kind'] ?? 'run') === 'jog_walk') {
                $jogWalk = true;
            }
        }

        $unit = $case['unit'];
        $spread = PaceSpread::analyse($bands);

        $whole = fn (float $perKm) => (int) round(PaceSpread::inUnit($perKm, $unit));

        $actual = [
            'empty' => $spread['empty'],
            'gaps' => array_map(fn ($gap) => [$whole($gap['fast']), $whole($gap['slow'])], $spread['gaps']),
            'fasterEnd' => $spread['fasterEnd'] === null ? null : $whole($spread['fasterEnd']['slow']),
            'slowerEnd' => $spread['slowerEnd'] === null ? null : $whole($spread['slowerEnd']['fast']),
            'jogWalk' => $jogWalk,
        ];

        $this->assertSame($case['expect'], $actual, $case['name']);
    }

    public function testAUsualPaceFitsAStretchWithinThirtySecondsEitherSide()
    {
        $nineFifteen = PaceSpread::band('mi', 555, null);
        $stretch = fn (int $fast, int $slow) => [PaceSpread::km($fast), PaceSpread::km($slow)];

        $this->assertTrue(PaceSpread::fits($nineFifteen, ...$stretch(570, 615)));  // 9:30 to 10:15
        $this->assertTrue(PaceSpread::fits($nineFifteen, ...$stretch(585, 615)));  // 9:45 is within 30 s of 9:15
        $this->assertFalse(PaceSpread::fits($nineFifteen, ...$stretch(630, 690))); // 10:30 to 11:30
        $this->assertFalse(PaceSpread::fits(null, ...$stretch(570, 615)));         // no usual pace
    }

    public function testAppliesToPacedRunsOnly()
    {
        $paced = new App\Models\ClubSession(['group_mode' => 'paced']);
        $this->assertTrue(PaceSpread::appliesTo($paced));

        foreach (['single', 'open', 'routes', 'events', 'race'] as $mode) {
            $this->assertFalse(PaceSpread::appliesTo(new App\Models\ClubSession(['group_mode' => $mode])), $mode);
        }
    }
}
