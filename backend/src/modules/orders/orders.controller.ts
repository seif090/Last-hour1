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
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
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
  async listOrders(
    @Req() req: any,
    @Query('status') status?: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.ordersService.getUserOrders(req.user.id, status, +page, +limit);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get order detail' })
  async getOrder(@Param('id', ParseUUIDPipe) id: string, @Req() req: any) {
    const order = await this.ordersService.getOrder(id, req.user.id);
    return { success: true, data: order };
  }
}
