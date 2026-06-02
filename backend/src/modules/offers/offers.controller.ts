import {
  Controller,
  Get,
  Param,
  Req,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { JwtService } from '@nestjs/jwt';
import { OffersService } from './offers.service';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('Offers')
@Controller('offers')
export class OffersController {
  constructor(
    private readonly offersService: OffersService,
    private readonly jwtService: JwtService,
  ) {}

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'Get offer detail with quota info' })
  async getOfferDetail(
    @Param('id', ParseUUIDPipe) id: string,
    @Req() req: any,
  ) {
    const authHeader = req.headers.authorization;
    let userId: string | null = null;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      try {
        const decoded = this.jwtService.decode(token) as { sub?: string };
        userId = decoded?.sub || null;
      } catch {
        // Ignore invalid token, treat as guest
      }
    }

    const data = await this.offersService.getOfferDetail(id, userId);
    return { success: true, data };
  }
}
