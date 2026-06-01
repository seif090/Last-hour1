import { IsString, IsEnum, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export enum AllowedOrderStatus {
  pending = 'pending',
  confirmed = 'confirmed',
  preparing = 'preparing',
  ready = 'ready',
  picked_up = 'picked_up',
  cancelled = 'cancelled',
  refunded = 'refunded',
}

export class UpdateOrderStatusDto {
  @ApiProperty({ enum: AllowedOrderStatus })
  @IsEnum(AllowedOrderStatus)
  status: AllowedOrderStatus;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  cancelReason?: string;
}
