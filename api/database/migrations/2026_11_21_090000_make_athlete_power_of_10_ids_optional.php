<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Every club member needs an athletes row, whether or not Power of 10 knows them.
 *
 * Power of 10 can no longer be searched by URN, so new athletes arrive with no
 * old integer athlete_id and no po10_guid. `athletes.id` is the internal key
 * (club_members, performances and rankings join on it), so it now just
 * auto-increments, and athlete_id becomes optional. The existing column types are
 * kept so unsigned or wider ints are not narrowed. MariaDB/MySQL only; the sqlite
 * test schema already allows both.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() === 'sqlite' || !Schema::hasTable('athletes')) {
            return;
        }

        $id = $this->columnType('id');
        $athleteId = $this->columnType('athlete_id');

        DB::statement("ALTER TABLE `athletes` MODIFY `athlete_id` {$athleteId} NULL");
        DB::statement("ALTER TABLE `athletes` MODIFY `id` {$id} NOT NULL AUTO_INCREMENT");
    }

    public function down(): void
    {
        // Not reversible without discarding athletes that have no athlete_id.
    }

    private function columnType(string $column): string
    {
        $row = DB::selectOne('SHOW COLUMNS FROM `athletes` WHERE Field = ?', [$column]);

        return $row->Type;
    }
};
