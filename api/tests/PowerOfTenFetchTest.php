<?php

use App\Services\PowerOfTenClient;
use GuzzleHttp\Client;
use GuzzleHttp\Handler\MockHandler;
use GuzzleHttp\HandlerStack;
use GuzzleHttp\Middleware;
use GuzzleHttp\Psr7\Response;

/**
 * How the scraper talks to Power of 10, as opposed to what it makes of the
 * reply. The nightly run reads one page per member and there are several
 * hundred members, so the cost of a request is worth pinning down.
 */
// Boots the app because the fetch path logs, and the Log facade needs a
// container behind it.
class PowerOfTenFetchTest extends TestCase
{
    private array $sent = [];

    private function clientReturning(Response ...$responses): PowerOfTenClient
    {
        $this->sent = [];

        $stack = HandlerStack::create(new MockHandler($responses));
        $stack->push(Middleware::history($this->sent));

        return new PowerOfTenClient(new Client([
            'handler' => $stack,
            'headers' => ['Accept-Encoding' => 'gzip'],
        ]));
    }

    public function testAsksForACompressedPage()
    {
        $client = $this->clientReturning(new Response(200, [], 'a page'));

        $client->fetchAthletePage('a-guid');

        // 340 KB of HTML, 50 KB compressed, once per member per night.
        $this->assertSame(
            'gzip',
            $this->sent[0]['request']->getHeaderLine('Accept-Encoding')
        );
    }

    public function testUnwrapsACompressedPageTheHttpClientLeftAlone()
    {
        $client = $this->clientReturning(
            new Response(200, ['Content-Encoding' => 'gzip'], gzencode('a page'))
        );

        // Handed to the parser as it arrived, this reads as an athlete who has
        // never raced rather than as a failure, so it must not get that far.
        $this->assertSame('a page', $client->fetchAthletePage('a-guid'));
    }

    public function testReadsThePageOnceForBothThePerformancesAndTheHandicap()
    {
        $client = $this->clientReturning(new Response(200, [], 'a page'));

        $first = $client->fetchAthletePage('a-guid');
        $second = $client->fetchAthletePage('a-guid');

        $this->assertSame($first, $second);
        $this->assertCount(1, $this->sent);
    }

    public function testStillFetchesWhenTheAthleteChanges()
    {
        $client = $this->clientReturning(
            new Response(200, [], 'one athlete'),
            new Response(200, [], 'another athlete')
        );

        $this->assertSame('one athlete', $client->fetchAthletePage('a-guid'));
        $this->assertSame('another athlete', $client->fetchAthletePage('another-guid'));
        $this->assertCount(2, $this->sent);
    }

    public function testRemembersThatAnAthleteWasNotFound()
    {
        $client = $this->clientReturning(
            new Response(200, [], 'This athlete could not be found')
        );

        $this->assertNull($client->fetchAthletePage('a-guid'));
        $this->assertNull($client->fetchAthletePage('a-guid'));
        $this->assertCount(1, $this->sent);
    }
}
