import { Test, TestingModule } from '@nestjs/testing';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule } from '../../src/database/database.module';
import { OffersModule } from '../../src/modules/offers/offers.module';

describe('Offers Integration', () => {
  let moduleFixture: TestingModule;

  beforeAll(async () => {
    moduleFixture = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        DatabaseModule,
        OffersModule,
      ],
    }).compile();
  });

  it('modules should compile', () => {
    expect(moduleFixture).toBeDefined();
  });
});
