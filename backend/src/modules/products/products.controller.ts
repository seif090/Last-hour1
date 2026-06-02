import { Controller, Get, Post, Patch, Delete, Param, Body, UseGuards, Req, Query } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiParam, ApiQuery } from '@nestjs/swagger';
import { Request } from 'express';
import { ProductsService } from './products.service';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { MerchantsService } from '../merchants/merchants.service';

@ApiTags('Products')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), RolesGuard)
@Roles('merchant')
@Controller('merchant/products')
export class ProductsController {
  constructor(
    private readonly productsService: ProductsService,
    private readonly merchantsService: MerchantsService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'List products for the merchant store' })
  @ApiQuery({ name: 'storeId', required: true })
  async findAll(@Req() req: Request, @Query('storeId') storeId?: string) {
    const sid = storeId || await this.merchantsService.getFirstStoreId(req.user!.id);
    const products = await this.productsService.findByStore(sid);
    return { products };
  }

  @Post()
  @ApiOperation({ summary: 'Create a product' })
  @ApiQuery({ name: 'storeId', required: true })
  async create(@Body() dto: CreateProductDto, @Req() req: Request, @Query('storeId') storeId?: string) {
    const sid = dto.storeId || storeId || await this.merchantsService.getFirstStoreId(req.user!.id);
    return this.productsService.create(sid, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a product' })
  @ApiParam({ name: 'id', description: 'Product ID' })
  async update(@Param('id') id: string, @Body() dto: UpdateProductDto, @Req() req: Request) {
    const sid = dto.storeId || await this.merchantsService.getFirstStoreId(req.user!.id);
    return this.productsService.update(id, sid, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Deactivate a product' })
  @ApiParam({ name: 'id', description: 'Product ID' })
  async delete(@Param('id') id: string, @Req() req: Request) {
    const sid = await this.merchantsService.getFirstStoreId(req.user!.id);
    await this.productsService.delete(id, sid);
    return { success: true };
  }
}
