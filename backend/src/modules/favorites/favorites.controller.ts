import { Controller, Get, Post, Delete, Param, UseGuards, Req } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { Request } from 'express';
import { FavoritesService } from './favorites.service';

@ApiTags('Favorites')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller('favorites')
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  @Get()
  @ApiOperation({ summary: 'List user favorite offers' })
  async list(@Req() req: Request) {
    const items = await this.favoritesService.list(req.user!.id);
    return { data: items };
  }

  @Post(':offerId')
  @ApiOperation({ summary: 'Add offer to favorites' })
  async add(@Param('offerId') offerId: string, @Req() req: Request) {
    const fav = await this.favoritesService.add(req.user!.id, offerId);
    return { success: true, data: fav };
  }

  @Delete(':offerId')
  @ApiOperation({ summary: 'Remove offer from favorites' })
  async remove(@Param('offerId') offerId: string, @Req() req: Request) {
    await this.favoritesService.remove(req.user!.id, offerId);
    return { success: true };
  }

  @Get('check/:offerId')
  @ApiOperation({ summary: 'Check if offer is favorited' })
  async check(@Param('offerId') offerId: string, @Req() req: Request) {
    const favorited = await this.favoritesService.isFavorited(req.user!.id, offerId);
    return { favorited };
  }
}
