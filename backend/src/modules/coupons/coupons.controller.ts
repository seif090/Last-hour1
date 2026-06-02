import {
  Controller, Get, Post, Patch, Param, Body, Req, UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { Request } from 'express';
import { CouponsService } from './coupons.service';
import { CreateCouponDto, ApplyCouponDto } from './dto/create-coupon.dto';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';

@ApiTags('Coupons')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller()
export class CouponsController {
  constructor(private readonly couponsService: CouponsService) {}

  @Post('merchant/coupons')
  @UseGuards(RolesGuard)
  @Roles('merchant')
  @ApiOperation({ summary: 'Create a coupon for a store' })
  async create(@Body() dto: CreateCouponDto, @Req() req: Request) {
    const storeId = req.body?.storeId ?? req.query?.storeId as string;
    if (!storeId) throw new Error('storeId is required');
    return this.couponsService.create(storeId, dto);
  }

  @Get('merchant/coupons/:storeId')
  @UseGuards(RolesGuard)
  @Roles('merchant')
  @ApiOperation({ summary: 'List coupons for a store' })
  async findByStore(@Param('storeId') storeId: string) {
    const coupons = await this.couponsService.findByStore(storeId);
    return { success: true, data: coupons };
  }

  @Post('coupons/validate')
  @ApiOperation({ summary: 'Validate and apply a coupon' })
  async validate(@Body() dto: ApplyCouponDto, @Req() req: Request) {
    const storeId = req.body?.storeId ?? '';
    return this.couponsService.validateAndApply(storeId, dto);
  }

  @Patch('merchant/coupons/:id/toggle')
  @UseGuards(RolesGuard)
  @Roles('merchant')
  @ApiOperation({ summary: 'Toggle coupon active status' })
  async toggle(@Param('id') id: string, @Req() req: Request) {
    return this.couponsService.toggleActive(id, req.body?.storeId ?? '');
  }
}
