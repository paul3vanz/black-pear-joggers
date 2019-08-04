import { Module } from '@nestjs/common';
import { GraphQLModule } from '@nestjs/graphql';
import { TypeOrmModule, TypeOrmModuleOptions } from '@nestjs/typeorm';

import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AthleteModule } from './athlete/athlete.module';
import { PerformanceModule } from './performance/performance.module';

const typeOrmConfig: TypeOrmModuleOptions = {
  type: 'mysql',
  port: 3306,
  entities: [__dirname + '/**/*.entity{.ts,.js}'],
      // host: 'bpj.org.uk',
      // username: 'blackpea_bpj_pb',
      // password: '%!}jI4Q*^5pL',
      // database: 'blackpea_pearbase',
      host: 'localhost',
      username: 'root',
      password: '',
      database: 'blackpea_memberships',
      // synchronize: true,
};

@Module({
  imports: [
    AthleteModule,
    PerformanceModule,
    TypeOrmModule.forRoot(typeOrmConfig),
    GraphQLModule.forRoot({
      autoSchemaFile: 'schema.gql',
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}