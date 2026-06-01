import { Controller, Get, Patch, Param, Query, Body, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';

@ApiTags('Admin')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), RolesGuard)
@Roles('admin')
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('stats')
  @ApiOperation({ summary: 'Platform-wide statistics' })
  async getStats() {
    const data = await this.adminService.getPlatformStats();
    return { success: true, data };
  }

  @Get('users')
  @ApiOperation({ summary: 'List all users' })
  async listUsers(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('role') role?: string,
  ) {
    return this.adminService.listUsers(+page, +limit, role);
  }

  @Patch('users/:id/ban')
  @ApiOperation({ summary: 'Ban/unban a user' })
  async toggleBan(@Param('id') id: string, @Body('banned') banned: boolean) {
    const data = await this.adminService.toggleUserBan(id, banned);
    return { success: true, data };
  }

  @Get('orders')
  @ApiOperation({ summary: 'List all orders' })
  async listOrders(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('status') status?: string,
  ) {
    return this.adminService.listOrders(+page, +limit, status);
  }

  @Get('revenue')
  @ApiOperation({ summary: 'Revenue analytics' })
  async getRevenue(@Query('days') days = 30) {
    return this.adminService.getRevenueAnalytics(+days);
  }

  @Get('merchants')
  @ApiOperation({ summary: 'List all merchants' })
  async listMerchants(
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('verified') verified?: string,
  ) {
    const verifiedFilter = verified !== undefined ? verified === 'true' : undefined;
    return this.adminService.listMerchants(+page, +limit, verifiedFilter);
  }

  @Patch('merchants/:id/verify')
  @ApiOperation({ summary: 'Verify a merchant' })
  async verifyMerchant(@Param('id') id: string) {
    const data = await this.adminService.verifyMerchant(id);
    return { success: true, data };
  }

  @Get('offers')
  @ApiOperation({ summary: 'List all offers across platform' })
  async listOffers(
    @Query('status') status?: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.adminService.listOffers(status, +page, +limit);
  }

  @Patch('offers/:id/expire')
  @ApiOperation({ summary: 'Force expire an offer' })
  async forceExpireOffer(@Param('id') id: string) {
    const data = await this.adminService.forceExpireOffer(id);
    return { success: true, data };
  }

  @Get('system/health')
  @ApiOperation({ summary: 'Detailed system health' })
  async systemHealth() {
    return this.adminService.getSystemHealth();
  }
}
