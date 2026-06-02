import { IsString, IsNumber, IsOptional, IsIn, Min, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateCouponDto {
  @ApiProperty()
  @IsString() @MaxLength(50)
  code: string;

  @ApiProperty({ enum: ['percentage', 'fixed'] })
  @IsIn(['percentage', 'fixed'])
  discountType: 'percentage' | 'fixed';

  @ApiProperty()
  @IsNumber() @Min(0)
  discountValue: number;

  @ApiPropertyOptional()
  @IsOptional() @IsNumber() @Min(0)
  minOrderAmount?: number;

  @ApiPropertyOptional()
  @IsOptional() @IsNumber() @Min(0)
  maxDiscount?: number;

  @ApiPropertyOptional({ default: 100 })
  @IsOptional() @IsNumber() @Min(1)
  maxUses?: number;

  @ApiPropertyOptional()
  @IsOptional() @IsString()
  expiresAt?: string;

  @ApiPropertyOptional()
  @IsOptional() @IsString()
  description?: string;
}

export class ApplyCouponDto {
  @ApiProperty()
  @IsString()
  code: string;

  @ApiProperty()
  @IsNumber() @Min(0)
  orderTotal: number;
}
