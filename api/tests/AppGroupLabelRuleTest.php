<?php

require_once __DIR__ . '/AppGroupsBase.php';

use App\Models\SessionGroup;

/**
 * 2026-10-13: a group with no pace must have a label (create, and PATCH against the resulting values).
 */
class AppGroupLabelRuleTest extends AppGroupsBase
{
    /** @dataProvider createMatrix */
    public function testCreateMatrix(array $body, bool $valid)
    {
        $s = $this->session();
        [$status, $res] = $this->api('POST', "/sessions/{$s->id}/groups", 'committee', $body + ['lead' => false]);

        if ($valid) {
            $this->assertSame(201, $status, json_encode($res));
            $this->assertSame(1, SessionGroup::count());
        } else {
            $this->assertSame(422, $status);
            $this->assertSame('validation_failed', $res['error']);
            $this->assertSame(['label'], array_keys($res['errors']));
            $this->assertSame(0, SessionGroup::count());
        }
    }

    public function createMatrix(): array
    {
        $pace = ['paceUnit' => 'mi', 'paceFromS' => 570];

        return [
            'pace, no label' => [$pace, true],
            'pace, null label' => [$pace + ['label' => null], true],
            'pace, empty label' => [$pace + ['label' => ''], true],
            'pace range, label' => [['paceUnit' => 'km', 'paceFromS' => 300, 'paceToS' => 330, 'label' => 'Steady'], true],
            'label, no pace' => [['label' => 'Jog/walk'], true],
            'label and distance, no pace' => [['label' => 'Route A', 'distanceValue' => 5, 'distanceUnit' => 'km'], true],
            'neither' => [[], false],
            'null label, no pace' => [['label' => null], false],
            'empty label, no pace' => [['label' => ''], false],
            'spaces only, no pace' => [['label' => "  \t "], false],
            'distance only' => [['distanceValue' => 5, 'distanceUnit' => 'km'], false],
        ];
    }

    public function testRuleAlsoAppliesWhenALeaderCreatesAGroup()
    {
        $s = $this->session();
        [$status, $res] = $this->api('POST', "/sessions/{$s->id}/groups", 'plain', ['lead' => true]);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('label', $res['errors']);
        $this->assertSame(0, SessionGroup::count());
    }

    public function testPatchIsCheckedAgainstTheResultingValues()
    {
        $s = $this->session();
        $paced = $this->group($s, [$this->leaderA], ['pace_unit' => 'mi', 'pace_from_s' => 570]);
        $named = $this->group($s, [$this->leaderA], ['label' => 'Walk']);

        // Pace group without a label: dropping the pace leaves nothing to tell it apart.
        [$status, $res] = $this->api('PATCH', "/groups/{$paced->id}", 'leaderA', ['paceFromS' => null]);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('label', $res['errors']);
        $this->assertSame(570, (int) SessionGroup::find($paced->id)->pace_from_s);

        // ... unless the same request names it.
        [$status, $res] = $this->api('PATCH', "/groups/{$paced->id}", 'leaderA', ['paceFromS' => null, 'label' => 'Social']);
        $this->assertSame(200, $status);
        $this->assertSame('Social', $res['label']);
        $this->assertNull($res['paceFromS']);

        // Editing other fields of a pace group, or its label to null, is fine while a pace remains.
        $paced2 = $this->group($s, [$this->leaderA], ['label' => 'Fast', 'pace_unit' => 'mi', 'pace_from_s' => 480]);
        $this->assertSame(200, $this->api('PATCH', "/groups/{$paced2->id}", 'leaderA', ['label' => null])[0]);
        $this->assertSame(200, $this->api('PATCH', "/groups/{$paced2->id}", 'leaderA', ['description' => 'Quick'])[0]);

        // Label group without a pace: the label cannot be cleared or blanked, but can be changed.
        foreach ([null, '', '   '] as $bad) {
            [$status, $res] = $this->api('PATCH', "/groups/{$named->id}", 'leaderA', ['label' => $bad]);
            $this->assertSame(422, $status, var_export($bad, true));
            $this->assertArrayHasKey('label', $res['errors']);
        }
        $this->assertSame('Walk', SessionGroup::find($named->id)->label);
        $this->assertSame(200, $this->api('PATCH', "/groups/{$named->id}", 'leaderA', ['label' => 'Walk 2'])[0]);

        // Clearing the label while adding a pace in the same request is fine.
        [$status, $res] = $this->api('PATCH', "/groups/{$named->id}", 'leaderA', ['label' => null, 'paceUnit' => 'km', 'paceFromS' => 400]);
        $this->assertSame(200, $status);
        $this->assertNull($res['label']);

        // Too long is still a label error.
        $this->assertArrayHasKey('label', $this->api('PATCH', "/groups/{$named->id}", 'leaderA', ['label' => str_repeat('x', 81)])[1]['errors']);
    }

    public function testAnOldUnlabelledPacelessGroupMustBeNamedOnTheNextEdit()
    {
        $s = $this->session();
        $legacy = $this->group($s, [$this->leaderA]); // created before the rule: no label, no pace

        [$status, $res] = $this->api('PATCH', "/groups/{$legacy->id}", 'leaderA', ['description' => 'Easy']);
        $this->assertSame(422, $status);
        $this->assertArrayHasKey('label', $res['errors']);

        $this->assertSame(200, $this->api('PATCH', "/groups/{$legacy->id}", 'leaderA', ['description' => 'Easy', 'label' => 'Easy'])[0]);
    }
}
