import {
  Controller,
  Post,
  Get,
  Param,
  Body,
  Query,
  UseGuards,
  Req,
  ParseUUIDPipe,
  Patch,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiParam, ApiQuery } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { CreateOrderDto } from './dto/create-order.dto';


@ApiTags('Orders')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  @ApiOperation({ summary: 'Place an order (flash sale concurrency-safe)' })
  async placeOrder(@Body() dto: CreateOrderDto, @Req() req: any) {
    const order = await this.ordersService.placeOrder(dto, req.user.id);
    return { success: true, data: order };
  }

  @Get()
  @ApiOperation({ summary: 'List my orders' })
  @ApiQuery({ name: 'status', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'startDate', required: false })
  @ApiQuery({ name: 'endDate', required: false })
  @ApiQuery({ name: 'minPrice', required: false, type: Number })
  @ApiQuery({ name: 'maxPrice', required: false, type: Number })
  @ApiQuery({ name: 'sort', required: false })
  async listOrders(
    @Req() req: any,
    @Query('status') status?: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('minPrice') minPrice?: string,
    @Query('maxPrice') maxPrice?: string,
    @Query('sort') sort?: string,
  ) {
    return this.ordersService.getUserOrders(req.user.id, status, +page, +limit, {
      startDate,
      endDate,
      minPrice: minPrice ? parseFloat(minPrice) : undefined,
      maxPrice: maxPrice ? parseFloat(maxPrice) : undefined,
      sort,
    });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get order detail' })
  @ApiParam({ name: 'id', description: 'Order ID' })
  async getOrder(@Param('id', ParseUUIDPipe) id: string, @Req() req: any) {
    const order = await this.ordersService.getOrder(id, req.user.id);
    return { success: true, data: order };
  }

  @Patch(':id/status')
  @ApiOperation({ summary: 'Confirm pickup (customer)' })
  @ApiParam({ name: 'id', description: 'Order ID' })
  async confirmPickup(@Param('id', ParseUUIDPipe) id: string, @Req() req: any) {
    const order = await this.ordersService.confirmPickup(id, req.user.id);
    return { success: true, data: order };
  }

  @Patch(':id/cancel')
  @ApiOperation({ summary: 'Cancel an order (customer)' })
  @ApiParam({ name: 'id', description: 'Order ID' })
  async cancelOrder(
    @Param('id', ParseUUIDPipe) id: string,
    @Body('reason') reason: string | undefined,
    @Req() req: any,
  ) {
    const order = await this.ordersService.cancelOrder(id, req.user.id, reason);
    return { success: true, data: order };
  }
}
