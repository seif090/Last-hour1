import { Controller, Get, Patch, Body, UseGuards, Req } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { Request } from 'express';
import { NotificationPreferencesService } from './notification-preferences.service';
import { UpdateNotificationPreferencesDto } from './dto/update-notification-preferences.dto';

@ApiTags('Notification Preferences')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller('notification-preferences')
export class NotificationPreferencesController {
  constructor(private readonly service: NotificationPreferencesService) {}

  @Get()
  @ApiOperation({ summary: 'Get notification preferences' })
  async get(@Req() req: Request) {
    return this.service.getPreferences(req.user!.id);
  }

  @Patch()
  @ApiOperation({ summary: 'Update notification preferences' })
  async update(@Body() dto: UpdateNotificationPreferencesDto, @Req() req: Request) {
    return this.service.updatePreferences(req.user!.id, dto);
  }
}
