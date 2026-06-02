import { Controller, Post, Get, Patch, Param, Body, Query, UseGuards, Req } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { Request } from 'express';
import { MerchantsService } from './merchants.service';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RegisterMerchantDto } from './dto/register-merchant.dto';
import { CreateOfferDto } from './dto/create-offer.dto';

@ApiTags('Merchant')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), RolesGuard)
@Roles('merchant')
@Controller('merchant')
export class MerchantsController {
  constructor(private readonly merchantsService: MerchantsService) {}

  @Post('register')
  @Roles('customer')
  @ApiOperation({ summary: 'Register as a merchant' })
  async register(@Body() dto: RegisterMerchantDto, @Req() req: Request) {
    return this.merchantsService.register(req.user!.id, dto);
  }

  @Get('dashboard')
  @ApiOperation({ summary: 'Get merchant dashboard' })
  async getDashboard(@Req() req: Request) {
    return this.merchantsService.getDashboard(req.user!.merchantId!);
  }

  @Get('sales/today')
  @ApiOperation({ summary: 'Get today sales report' })
  async getTodaySales(@Req() req: Request) {
    return this.merchantsService.getTodaySales(req.user!.merchantId!);
  }

  @Post('offers')
  @ApiOperation({ summary: 'Create a flash offer' })
  async createOffer(@Body() dto: CreateOfferDto, @Req() req: Request) {
    const offer = await this.merchantsService.createOffer(req.user!.merchantId!, dto);
    return { success: true, data: offer };
  }

  @Patch('offers/:offerId')
  @ApiOperation({ summary: 'Update an offer' })
  async updateOffer(
    @Param('offerId') offerId: string,
    @Body() dto: Record<string, unknown>,
    @Req() req: Request,
  ) {
    const offer = await this.merchantsService.updateOffer(req.user!.merchantId!, offerId, dto);
    return { success: true, data: offer };
  }

  @Patch('offers/:offerId/stock')
  @ApiOperation({ summary: 'Update live stock for an offer' })
  async updateStock(
    @Param('offerId') offerId: string,
    @Body('stock_remaining') stockRemaining: number,
    @Req() req: Request,
  ) {
    const offer = await this.merchantsService.updateStock(req.user!.merchantId!, offerId, stockRemaining);
    return { success: true, data: offer };
  }

  @Get('orders')
  @ApiOperation({ summary: 'List incoming orders' })
  async listOrders(
    @Req() req: Request,
    @Query('status') status?: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.merchantsService.listOrders(
      req.user!.merchantId!,
      status,
      +page,
      +limit,
    );
  }

  @Patch('orders/:orderId/status')
  @ApiOperation({ summary: 'Update order status' })
  async updateOrderStatus(
    @Param('orderId') orderId: string,
    @Body('status') status: string,
    @Req() req: Request,
  ) {
    const order = await this.merchantsService.updateOrderStatus(
      req.user!.merchantId!,
      orderId,
      status,
    );
    return { success: true, data: order };
  }

  @Patch('stores/:storeId/hours')
  @ApiOperation({ summary: 'Update store operating hours' })
  async updateStoreHours(
    @Param('storeId') storeId: string,
    @Body() dto: Record<string, string>,
    @Req() req: Request,
  ) {
    const store = await this.merchantsService.updateStoreHours(
      req.user!.merchantId!,
      storeId,
      dto,
    );
    return { success: true, data: store };
  }

  @Get('analytics')
  @ApiOperation({ summary: 'Get sales analytics' })
  async getAnalytics(
    @Req() req: Request,
    @Query('days') days = '30',
  ) {
    return this.merchantsService.getAnalytics(req.user!.merchantId!, parseInt(days, 10));
  }
}
