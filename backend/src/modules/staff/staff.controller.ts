import { Controller, Get, Post, Patch, Delete, Param, Body, UseGuards, Req } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiParam } from '@nestjs/swagger';
import { Request } from 'express';
import { StaffService } from './staff.service';
import { InviteStaffDto, UpdateStaffDto } from './dto/staff.dto';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';

@ApiTags('Staff')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), RolesGuard)
@Roles('merchant')
@Controller('merchant/staff')
export class StaffController {
  constructor(private readonly service: StaffService) {}

  @Get()
  @ApiOperation({ summary: 'List staff members' })
  async list(@Req() req: Request) {
    return this.service.list(req.user!.merchantId!);
  }

  @Post()
  @ApiOperation({ summary: 'Invite a staff member' })
  async invite(@Body() dto: InviteStaffDto, @Req() req: Request) {
    return this.service.invite(req.user!.merchantId!, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a staff member' })
  @ApiParam({ name: 'id', description: 'Staff Member ID' })
  async update(@Param('id') id: string, @Body() dto: UpdateStaffDto, @Req() req: Request) {
    return this.service.update(req.user!.merchantId!, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove a staff member' })
  @ApiParam({ name: 'id', description: 'Staff Member ID' })
  async remove(@Param('id') id: string, @Req() req: Request) {
    return this.service.remove(req.user!.merchantId!, id);
  }
}
