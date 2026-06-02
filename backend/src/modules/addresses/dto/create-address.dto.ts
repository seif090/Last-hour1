import { IsString, IsOptional, IsNumber, IsBoolean, MinLength, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateAddressDto {
  @ApiPropertyOptional({ default: 'Home' })
  @IsOptional() @IsString() @MaxLength(50)
  label?: string;

  @ApiProperty()
  @IsString() @MinLength(3) @MaxLength(255)
  addressLine1: string;

  @ApiPropertyOptional()
  @IsOptional() @IsString() @MaxLength(255)
  addressLine2?: string;

  @ApiProperty()
  @IsString() @MinLength(2) @MaxLength(100)
  city: string;

  @ApiPropertyOptional()
  @IsOptional() @IsString() @MaxLength(100)
  district?: string;

  @ApiPropertyOptional()
  @IsOptional() @IsString() @MaxLength(20)
  postalCode?: string;

  @ApiPropertyOptional()
  @IsOptional() @IsNumber()
  latitude?: number;

  @ApiPropertyOptional()
  @IsOptional() @IsNumber()
  longitude?: number;

  @ApiPropertyOptional({ default: false })
  @IsOptional() @IsBoolean()
  isDefault?: boolean;
}
