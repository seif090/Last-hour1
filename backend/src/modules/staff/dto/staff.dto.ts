import { IsEmail, IsOptional, IsString, IsIn } from 'class-validator';

export class InviteStaffDto {
  @IsEmail()
  email: string;

  @IsString()
  name: string;

  @IsOptional()
  @IsIn(['admin', 'manager', 'staff'])
  role?: string;
}

export class UpdateStaffDto {
  @IsOptional()
  @IsIn(['admin', 'manager', 'staff'])
  role?: string;

  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  isActive?: boolean;
}
