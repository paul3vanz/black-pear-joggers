import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Athlete } from './athlete.entity';
import { Performance } from '../performance/performance.entity';

@Injectable()
export class AthleteService {
  findAll(): Promise<Athlete[]> {
    return this.athleteRepository.find();
  }

  findOneById(id: number): Promise<Athlete> {
    return this.athleteRepository.findOne(id);
  }

  performances(athleteId: number): Promise<Performance[]> {
    return this.performanceRepository.find({ where: { athlete_id: athleteId } });
  }

  constructor(
    @InjectRepository(Athlete)
    private readonly athleteRepository: Repository<Athlete>,
    @InjectRepository(Performance)
    private readonly performanceRepository: Repository<Performance>
  ) {}
}