import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AthleteService } from './athlete.service';
import { AthleteController } from './athlete.controller';
import { Athlete } from './athlete.entity';
import { AthleteResolver } from './athlete.resolver';
import { PerformanceService } from '../performance/performance.service';
import { PerformanceModule } from '../performance/performance.module';
import { Performance } from '../performance/performance.entity';

@Module({
  imports: [ TypeOrmModule.forFeature([ Athlete, Performance ]) ],
  providers: [ AthleteService, PerformanceService, AthleteResolver ],
  controllers: [ AthleteController ],
})
export class AthleteModule {}