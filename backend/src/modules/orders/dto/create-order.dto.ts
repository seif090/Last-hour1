import {
  IsUUID,
  IsInt,
  Min,
  Max,
  IsString,
  IsOptional,
  IsObject,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class PaymentDto {
  @ApiProperty({ enum: ['stripe', 'paymob'] })
  @IsString()
  provider: 'stripe' | 'paymob';

  @ApiProperty()
  @IsString()
  paymentMethodId: string;

  @ApiProperty({ required: false, default: false })
  @IsOptional()
  saveForFuture?: boolean;
}

export class CreateOrderDto {
  @ApiProperty()
  @IsUUID()
  offerId: string;

  @ApiProperty({ minimum: 1, maximum: 50 })
  @IsInt()
  @Min(1)
  @Max(50)
  quantity: number;

  @ApiProperty()
  @ValidateNested()
  @Type(() => PaymentDto)
  @IsObject()
  payment: PaymentDto;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  couponCode?: string;
}
