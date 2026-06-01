import { Controller, Get, Patch, Param, Body, UseGuards, ParseUUIDPipe } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  @ApiOperation({ summary: 'Get current user profile' })
  async getProfile(@CurrentUser() user: any) {
    const data = await this.usersService.getProfile(user.id);
    return { success: true, data };
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update current user profile' })
  async updateProfile(@CurrentUser() user: any, @Body() dto: any) {
    const data = await this.usersService.updateProfile(user.id, dto);
    return { success: true, data };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get user by ID (admin)' })
  async getUser(@Param('id', ParseUUIDPipe) id: string) {
    const data = await this.usersService.getProfile(id);
    return { success: true, data };
  }
}
