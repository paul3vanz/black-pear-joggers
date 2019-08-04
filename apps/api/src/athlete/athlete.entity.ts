import { ApiModelProperty } from '@nestjs/swagger';
import { Column, Entity, OneToMany, PrimaryColumn } from 'typeorm';
import { ObjectType, Field, ID } from 'type-graphql';

import { Performance } from '../performance/performance.entity';

@Entity('athletes')
@ObjectType()
export class Athlete {

  @ApiModelProperty()
  @Field(type => ID)
  @PrimaryColumn({ type: 'int', unsigned: true })
  id: number;

  @ApiModelProperty({
    description: 'Affiliation number'
  })
  @Column({ type: 'int', unsigned: true, nullable: true, default: null })
  @Field({ nullable: true })
  urn: number;

  @ApiModelProperty()
  @Column({ type: 'int', unsigned: true, nullable: true, default: null })
  @Field({ nullable: true })
  athlete_id: number;

  @ApiModelProperty()
  @Column({ type: 'int', unsigned: true, nullable: true, default: null })
  @Field({ nullable: true })
  athlete_id_alt: number;

  @ApiModelProperty()
  @Column({ length: 100 })
  @Field()
  first_name: string;

  @ApiModelProperty()
  @Column({ length: 100 })
  @Field()
  last_name: string;

  @ApiModelProperty()
  @Column({ length: 1 })
  @Field()
  gender: string;

  @ApiModelProperty()
  @Column({ type: 'date', nullable: true, default: null })
  @Field()
  dob: string;

  @ApiModelProperty()
  @Column({ type: 'tinyint', unsigned: true, nullable: true, default: null })
  @Field()
  age: number;

  @ApiModelProperty()
  @Column({ length: 20, nullable: true, default: null })
  @Field()
  category: string;

  @ApiModelProperty()
  @Column({ type: 'tinyint', unsigned: true, nullable: true, default: null })
  @Field()
  active: boolean;

  @ApiModelProperty()
  @Column({ length: 250 })
  @Field()
  club: string;

  @ApiModelProperty()
  @Column({ length: 100 })
  @Field()
  membership_check_status: string;

  @ApiModelProperty()
  @Column({ type: 'timestamp', nullable: true, default: null })
  @Field()
  membership_check: string;

  @ApiModelProperty()
  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  @Field()
  created_at: string;

  @ApiModelProperty()
  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP' })
  @Field()
  updated_at: string;

  @Field(type => [Performance])
  @OneToMany(type => Performance, performance => performance.athlete_id)
  performances: Performance[];
}