<?php
namespace App\Logging;
// use Illuminate\Log\Logger;
use DB;
use Illuminate\Support\Facades\Auth;
use Monolog\Logger;
use Monolog\Handler\AbstractProcessingHandler;
use Monolog\Level;
use Monolog\LogRecord;

class MySQLLoggingHandler extends AbstractProcessingHandler{
/**
 *
 * Reference:
 * https://github.com/markhilton/monolog-mysql/blob/master/src/Logger/Monolog/Handler/MysqlHandler.php
 */
    public function __construct($level = Level::Debug, $bubble = true) {
        $this->table = 'logs';
        parent::__construct($level, $bubble);
    }
    protected function write(LogRecord $record): void
    {
       $data = array(
           'message'       => $record['message'],
           'context'       => json_encode($record['context']),
           'level'         => $record['level'],
           'level_name'    => $record['level_name'],
           'channel'       => $record['channel'],
           'record_datetime' => $record['datetime']->format('Y-m-d H:i:s'),
           'extra'         => json_encode($record['extra']),
           'formatted'     => $record['formatted'],
           'remote_addr'   => $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1',
           'user_agent'    => $_SERVER['HTTP_USER_AGENT'] ?? null,
           'created_at'    => date("Y-m-d H:i:s"),
       );
       DB::connection()->table($this->table)->insert($data);
    }
}