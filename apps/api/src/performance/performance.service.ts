import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Performance } from './performance.entity';

@Injectable()
export class PerformanceService {
  constructor(
    @InjectRepository(Performance)
    private readonly performanceRepository: Repository<Performance>,
  ) {}

  findAll(search?: Object): Promise<Performance[]> {
    return this.performanceRepository.find(search);
  }

  findByID(id: number): Promise<Performance> {
    return this.performanceRepository.findOne(id);
  }
}