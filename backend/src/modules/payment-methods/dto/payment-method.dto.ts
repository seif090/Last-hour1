import { IsString, IsOptional, IsBoolean, IsIn, IsNumber } from 'class-validator';

export class CreatePaymentMethodDto {
  @IsString()
  @IsIn(['stripe', 'paymob'])
  provider: string;

  @IsString()
  paymentMethodId: string;

  @IsString()
  last4: string;

  @IsString()
  brand: string;

  @IsOptional()
  @IsNumber()
  expiryMonth?: number;

  @IsOptional()
  @IsNumber()
  expiryYear?: number;

  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}

export class UpdatePaymentMethodDto {
  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}
