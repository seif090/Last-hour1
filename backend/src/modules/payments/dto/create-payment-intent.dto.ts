import { IsString, IsEnum, IsOptional, IsObject } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export enum PaymentProviderEnum {
  stripe = 'stripe',
  paymob = 'paymob',
}

export class CreatePaymentIntentDto {
  @ApiProperty({ enum: PaymentProviderEnum })
  @IsEnum(PaymentProviderEnum)
  provider: PaymentProviderEnum;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  paymentMethodId?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  integrationId?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsObject()
  billingData?: Record<string, string>;
}
