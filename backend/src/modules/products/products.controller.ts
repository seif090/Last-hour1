import { Controller, Post, Patch, Delete, Param, Body, UseGuards, Req } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ProductsService } from './products.service';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CreateProductDto } from './dto/create-product.dto';

@ApiTags('Products')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), RolesGuard)
@Roles('merchant')
@Controller('merchant/products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a product' })
  async create(@Body() dto: CreateProductDto, @Req() req: any) {
    return this.productsService.create(req.user.storeId, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a product' })
  async update(@Param('id') id: string, @Body() dto: any, @Req() req: any) {
    return this.productsService.update(id, req.user.storeId, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Deactivate a product' })
  async delete(@Param('id') id: string, @Req() req: any) {
    await this.productsService.delete(id, req.user.storeId);
    return { success: true };
  }
}
