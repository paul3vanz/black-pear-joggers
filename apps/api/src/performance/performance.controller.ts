import { ApiResponse, ApiUseTags } from '@nestjs/swagger';
import { Controller, Get, Param } from '@nestjs/common';

import { PerformanceService } from './performance.service';
import { Performance } from './performance.entity';

@ApiUseTags('performances')
@Controller('performances')
export class PerformanceController {
  // @Get()
  // findAll(): Promise<Performance[]> {
  //   return this.performanceService.findAll();
  // }

  @Get(':id')
  @ApiResponse({
    status: 200,
    description: 'A single performance',
    type: Performance,
  })
  findOne(@Param('id') id: number): Promise<Performance> {
    return this.performanceService.findByID(id);
  }

  constructor(private readonly performanceService: PerformanceService) {}
}