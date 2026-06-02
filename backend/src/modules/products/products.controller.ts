import { Controller, Get, Post, Patch, Delete, Param, Body, UseGuards, Req } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { Request } from 'express';
import { ProductsService } from './products.service';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';

@ApiTags('Products')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), RolesGuard)
@Roles('merchant')
@Controller('merchant/products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get()
  @ApiOperation({ summary: 'List products for the merchant store' })
  async findAll(@Req() req: Request) {
    const products = await this.productsService.findByStore(req.user!.storeId!);
    return { products };
  }

  @Post()
  @ApiOperation({ summary: 'Create a product' })
  async create(@Body() dto: CreateProductDto, @Req() req: Request) {
    return this.productsService.create(req.user!.storeId!, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a product' })
  async update(@Param('id') id: string, @Body() dto: UpdateProductDto, @Req() req: Request) {
    return this.productsService.update(id, req.user!.storeId!, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Deactivate a product' })
  async delete(@Param('id') id: string, @Req() req: Request) {
    await this.productsService.delete(id, req.user!.storeId!);
    return { success: true };
  }
}
