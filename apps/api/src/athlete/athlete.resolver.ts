import { AthleteService } from './athlete.service';
import { Args, Query, Parent, ResolveProperty, Resolver } from '@nestjs/graphql';
import { Athlete } from './athlete.entity';
import { Performance } from '../performance/performance.entity';

@Resolver(of => Athlete)
export class AthleteResolver {
  constructor(
    private readonly athleteService: AthleteService
  ) {}

  @Query(returns => Athlete)
  async athlete(@Args('id') id: number) {
    return await this.athleteService.findOneById(id);
  }

  @Query(returns => [Athlete])
  async athletes(@Args() filter?: number) {
    return await this.athleteService.findAll();
  }

  @ResolveProperty('performances')
  public async performances(@Parent() athlete: Athlete): Promise<Performance[]> {
    return this.athleteService.performances(athlete.id);
  }
}