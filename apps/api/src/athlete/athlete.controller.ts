import { ApiResponse, ApiUseTags } from '@nestjs/swagger';
import { Controller, Get, Param } from '@nestjs/common';

import { AthleteService } from './athlete.service';
import { Athlete } from './athlete.entity';

@ApiUseTags('athletes')
@Controller('athletes')
export class AthleteController {
  @Get()
  findAll(): Promise<Athlete[]> {
    return this.athleteService.findAll();
  }

  @Get(':id')
  @ApiResponse({
    status: 200,
    description: 'A single athlete',
    type: Athlete,
  })
  findOneById(@Param('id') id: number): Promise<Athlete> {
    return this.athleteService.findOneById(id);
  }

  constructor(
    private readonly athleteService: AthleteService
  ) {}
}