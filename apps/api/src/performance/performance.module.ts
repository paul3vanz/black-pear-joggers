import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PerformanceService } from './performance.service';
import { PerformanceController } from './performance.controller';
import { Performance } from './performance.entity';

@Module({
  imports: [ TypeOrmModule.forFeature([ Performance ]) ],
  providers: [ PerformanceService ],
  controllers: [ PerformanceController ],
})
export class PerformanceModule {}