import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn } from 'typeorm';
import { ApiModelProperty } from '@nestjs/swagger';
import { Athlete } from '../athlete/athlete.entity';
import { ObjectType, Field } from 'type-graphql';

@Entity('performances')
@ObjectType()
export class Performance {
	@ApiModelProperty() @Field() @PrimaryGeneratedColumn({ type: 'int', unsigned: true}) id: number;
	@ApiModelProperty() @Field() @Column({ type: 'int', unsigned: true }) athlete_id: number;
	@ApiModelProperty() @Field() @Column({ length: 20 }) category: string;
	@ApiModelProperty() @Field() @Column({ type: 'int', unsigned: true }) meeting_id: number;
	@ApiModelProperty() @Field() @Column({ length: 20 }) event: string;
	@ApiModelProperty() @Field() @Column({ length: 20, nullable: true, default: null }) time: string;
	@ApiModelProperty() @Field() @Column({ type: 'int', unsigned: true, nullable: true, default: null }) time_parsed: number;
	@ApiModelProperty() @Field() @Column({ length: 100 }) race: string;
	@ApiModelProperty() @Field() @Column({ type: 'date' }) date: string;
	@ApiModelProperty() @Field() @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' }) created_at: string;
	@ApiModelProperty() @Field() @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP' }) updated_at: string;
	@ApiModelProperty() @Field() @Column({ type: 'tinyint', unsigned: true, nullable: true, default: null }) manual: boolean;
  @ApiModelProperty() @Field() @Column({ length: 250, nullable: true, default: null }) notes: string;

  @ManyToOne(type => Athlete, athlete => athlete.performances)
  @JoinColumn({ name: 'athlete_id' })
  athlete: Athlete;
}