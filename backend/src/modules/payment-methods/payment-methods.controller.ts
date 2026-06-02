import { Controller, Get, Post, Patch, Delete, Param, Body, UseGuards, Req } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiParam } from '@nestjs/swagger';
import { Request } from 'express';
import { PaymentMethodsService } from './payment-methods.service';
import { CreatePaymentMethodDto, UpdatePaymentMethodDto } from './dto/payment-method.dto';

@ApiTags('Payment Methods')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller('payment-methods')
export class PaymentMethodsController {
  constructor(private readonly service: PaymentMethodsService) {}

  @Get()
  @ApiOperation({ summary: 'List saved payment methods' })
  async list(@Req() req: Request) {
    return this.service.findByUser(req.user!.id);
  }

  @Post()
  @ApiOperation({ summary: 'Save a payment method' })
  async create(@Body() dto: CreatePaymentMethodDto, @Req() req: Request) {
    return this.service.create(req.user!.id, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a payment method' })
  @ApiParam({ name: 'id', description: 'Payment Method ID' })
  async update(@Param('id') id: string, @Body() dto: UpdatePaymentMethodDto, @Req() req: Request) {
    return this.service.update(req.user!.id, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove a payment method' })
  @ApiParam({ name: 'id', description: 'Payment Method ID' })
  async remove(@Param('id') id: string, @Req() req: Request) {
    return this.service.remove(req.user!.id, id);
  }
}
