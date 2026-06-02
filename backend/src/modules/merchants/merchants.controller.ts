import { Controller, Post, Get, Patch, Param, Body, Query, Res, UseGuards, Req } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiParam, ApiQuery } from '@nestjs/swagger';
import { Request } from 'express';
import { Response } from 'express';
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
  @ApiParam({ name: 'offerId', description: 'Offer ID' })
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
  @ApiParam({ name: 'offerId', description: 'Offer ID' })
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
  @ApiQuery({ name: 'status', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
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
  @ApiParam({ name: 'orderId', description: 'Order ID' })
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
  @ApiParam({ name: 'storeId', description: 'Store ID' })
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
  @ApiQuery({ name: 'days', required: false, type: Number })
  async getAnalytics(
    @Req() req: Request,
    @Query('days') days = '30',
  ) {
    return this.merchantsService.getAnalytics(req.user!.merchantId!, parseInt(days, 10));
  }

  @Get('report/csv')
  @ApiOperation({ summary: 'Export sales report as CSV' })
  @ApiQuery({ name: 'days', required: false, type: Number })
  @ApiQuery({ name: 'storeId', required: false })
  async exportCsv(
    @Req() req: Request,
    @Res() res: Response,
    @Query('days') days = '30',
    @Query('storeId') storeId?: string,
  ) {
    const csv = await this.merchantsService.generateCsvReport(req.user!.merchantId!, parseInt(days, 10), storeId);
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="sales-report-${new Date().toISOString().slice(0, 10)}.csv"`);
    res.send(csv);
  }

  @Get('orders/:orderId/invoice')
  @ApiOperation({ summary: 'Get invoice data for an order' })
  @ApiParam({ name: 'orderId', description: 'Order ID' })
  async getInvoice(@Param('orderId') orderId: string, @Req() req: Request) {
    return this.merchantsService.getInvoice(req.user!.merchantId!, orderId);
  }
}
