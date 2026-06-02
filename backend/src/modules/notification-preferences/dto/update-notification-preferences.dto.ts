import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateNotificationPreferencesDto {
  @IsOptional()
  @IsBoolean()
  pushEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  orderConfirmed?: boolean;

  @IsOptional()
  @IsBoolean()
  orderReady?: boolean;

  @IsOptional()
  @IsBoolean()
  nearbyOffers?: boolean;

  @IsOptional()
  @IsBoolean()
  promotions?: boolean;
}
