<?php

use App\Services\RunText;
use Illuminate\Support\Carbon;
use PHPUnit\Framework\TestCase as BaseTestCase;

/**
 * D48: times the server writes for people are 12-hour, "7pm" / "7:30pm", with ranges that
 * drop a shared am/pm. The API itself keeps 24-hour HH:MM.
 */
class RunTextClockTest extends BaseTestCase
{
    /** @dataProvider clocks */
    public function testClock(string $hm, string $expected)
    {
        $this->assertSame($expected, RunText::clock($hm));
    }

    public function clocks(): array
    {
        return [
            'midnight' => ['00:00', '12am'],
            'just after midnight' => ['00:05', '12:05am'],
            'early morning' => ['06:00', '6am'],
            'morning with minutes' => ['06:30', '6:30am'],
            'minutes keep two digits' => ['09:05', '9:05am'],
            'last minute before noon' => ['11:59', '11:59am'],
            'noon' => ['12:00', '12pm'],
            'just after noon' => ['12:30', '12:30pm'],
            'one pm' => ['13:00', '1pm'],
            'evening' => ['19:00', '7pm'],
            'evening half hour' => ['19:30', '7:30pm'],
            'evening quarter' => ['20:45', '8:45pm'],
            'last minute of the day' => ['23:59', '11:59pm'],
            'seconds are ignored' => ['19:00:00', '7pm'],
            'single digit hour' => ['7:15', '7:15am'],
            'not a time is left alone' => ['soon', 'soon'],
            'out of range is left alone' => ['24:00', '24:00'],
        ];
    }

    /** @dataProvider ranges */
    public function testRange(string $start, ?string $end, string $expected)
    {
        $this->assertSame($expected, RunText::range($start, $end));
    }

    public function ranges(): array
    {
        return [
            'shared pm' => ['19:00', '20:30', '7-8:30pm'],
            'shared pm, both minutes' => ['19:15', '20:45', '7:15-8:45pm'],
            'shared am' => ['06:30', '08:00', '6:30-8am'],
            'across noon' => ['11:00', '13:00', '11am-1pm'],
            'ends at noon' => ['10:30', '12:00', '10:30am-12pm'],
            'starts at noon' => ['12:00', '12:30', '12-12:30pm'],
            'noon to afternoon' => ['12:00', '14:00', '12-2pm'],
            'across midnight' => ['23:00', '01:00', '11pm-1am'],
            'from midnight' => ['00:00', '02:00', '12-2am'],
            'no end shows only the start' => ['19:00', null, '7pm'],
            'no end, with minutes' => ['19:30', null, '7:30pm'],
            'no end at noon' => ['12:00', null, '12pm'],
            'no end at midnight' => ['00:00', null, '12am'],
        ];
    }

    public function testTimeConvertsAnInstantToClubLocalTwelveHour()
    {
        // 18:00Z in October is 19:00 BST; in January it is 18:00 GMT.
        $this->assertSame('7pm', RunText::time(Carbon::parse('2026-10-12 18:00:00', 'UTC'), 'Europe/London'));
        $this->assertSame('6pm', RunText::time(Carbon::parse('2026-01-12 18:00:00', 'UTC'), 'Europe/London'));
        $this->assertSame('7:30pm', RunText::time(Carbon::parse('2026-10-12 18:30:00', 'UTC'), 'Europe/London'));
        $this->assertSame('12am', RunText::time(Carbon::parse('2026-10-11 23:00:00', 'UTC'), 'Europe/London'));
        $this->assertSame('12pm', RunText::time(Carbon::parse('2026-10-12 11:00:00', 'UTC'), 'Europe/London'));
    }
}
