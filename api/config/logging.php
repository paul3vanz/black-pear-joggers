<?php
return [
    /*
    |--------------------------------------------------------------------------
    | Default Log Channel
    |--------------------------------------------------------------------------
    |
    | This option defines the default log channel that gets used when writing
    | messages to the logs. The name specified in this option should match
    | one of the channels defined in the "channels" configuration array.
    |
    */
    'default' => env('LOG_CHANNEL', 'stack'),
    /*
    |--------------------------------------------------------------------------
    | Log Channels
    |--------------------------------------------------------------------------
    |
    | Here you may configure the log channels for your application. Out of
    | the box, Laravel uses the Monolog PHP logging library. This gives
    | you a variety of powerful log handlers / formatters to utilize.
    |
    | Available Drivers: "single", "daily", "slack", "syslog",
    |                    "errorlog", "custom", "stack"
    |
    */
    'channels' => [
        'stack' => [
            'driver' => 'stack',
            'channels' => ['db', 'slackInfo', 'slackErrors'],
        ],
        'single' => [
            'driver' => 'single',
            'path' => storage_path('logs/lumen.log'),
            'level' => 'debug',
        ],
        'daily' => [
            'driver' => 'daily',
            'path' => storage_path('logs/lumen.log'),
            'level' => 'debug',
            'days' => 7,
        ],
        'slackInfo' => [
            'driver' => 'slack',
            'url' => env('LOG_SLACK_WEBHOOK_URL_INFO'),
            'username' => 'BPJ Website Logging',
            'emoji' => ':running:',
            'level' => 'debug',
        ],
        'slackErrors' => [
            'driver' => 'slack',
            'url' => env('LOG_SLACK_WEBHOOK_URL_ERRORS'),
            'username' => 'BPJ Website Error',
            'emoji' => ':boom:',
            'level' => 'error',
        ],
        'slackAwardClaims' => [
            'driver' => 'slack',
            'url' => env('LOG_SLACK_WEBHOOK_URL_AWARD_CLAIMS'),
            'username' => 'Award Claim Submitted',
            'emoji' => ':trophy:',
            'level' => 'info',
        ],
        'syslog' => [
            'driver' => 'syslog',
            'level' => 'debug',
        ],
        'errorlog' => [
            'driver' => 'errorlog',
            'level' => 'debug',
        ],
        'db' => [
            'driver' => 'custom',
            'handler' => App\Logging\MySQLLoggingHandler::class,
            'via' => App\Logging\MySQLCustomLogger::class,
            'level' => 'debug',
        ],
    ],
];
