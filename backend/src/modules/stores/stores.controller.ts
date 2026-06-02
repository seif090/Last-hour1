import { Controller, Get, Param, Query, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiParam, ApiQuery } from '@nestjs/swagger';
import { StoresService } from './stores.service';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('Stores')
@Controller()
export class StoresController {
  constructor(private readonly storesService: StoresService) {}

  @Public()
  @Get('offers/nearby')
  @ApiOperation({ summary: 'Find active offers within radius' })
  @ApiQuery({ name: 'lat', required: true })
  @ApiQuery({ name: 'lng', required: true })
  @ApiQuery({ name: 'radius', required: false, type: Number })
  @ApiQuery({ name: 'category', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async findNearby(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
    @Query('radius') radius = '5000',
    @Query('category') category?: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.storesService.findNearbyOffers(
      parseFloat(lat),
      parseFloat(lng),
      parseInt(radius, 10),
      category,
      +page,
      +limit,
    );
  }

  @Public()
  @Get('offers/search')
  @ApiOperation({ summary: 'Search offers by text' })
  @ApiQuery({ name: 'q', required: true })
  @ApiQuery({ name: 'lat', required: false })
  @ApiQuery({ name: 'lng', required: false })
  @ApiQuery({ name: 'radius', required: false, type: Number })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async search(
    @Query('q') q: string,
    @Query('lat') lat: string,
    @Query('lng') lng: string,
    @Query('radius') radius = '20000',
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.storesService.searchOffers(
      q,
      parseFloat(lat),
      parseFloat(lng),
      parseInt(radius, 10),
      +page,
      +limit,
    );
  }

  @Public()
  @Get('stores/:id')
  @ApiOperation({ summary: 'Get store detail with menu' })
  @ApiParam({ name: 'id', description: 'Store ID' })
  async getStore(@Param('id', ParseUUIDPipe) id: string) {
    const data = await this.storesService.getStoreDetail(id);
    return { success: true, data };
  }

  @Public()
  @Get('stores/:id/menu')
  @ApiOperation({ summary: 'Get store menu with active offers' })
  @ApiParam({ name: 'id', description: 'Store ID' })
  async getMenu(@Param('id', ParseUUIDPipe) id: string) {
    const data = await this.storesService.getStoreMenu(id);
    return { success: true, data };
  }
}
