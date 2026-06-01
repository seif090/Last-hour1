import { IsString, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export enum BusinessType {
  restaurant = 'restaurant',
  bakery = 'bakery',
  supermarket = 'supermarket',
  cafe = 'cafe',
  other = 'other',
}

export class RegisterMerchantDto {
  @ApiProperty()
  @IsString()
  businessName: string;

  @ApiProperty({ enum: BusinessType })
  @IsEnum(BusinessType)
  businessType: BusinessType;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  taxId?: string;
}
