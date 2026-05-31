import { Controller, Post, Get, Param, Body, Query, UseGuards, Req } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ReviewsService } from './reviews.service';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('Reviews')
@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Post()
  @ApiBearerAuth()
  @UseGuards(AuthGuard('jwt'))
  @ApiOperation({ summary: 'Submit a review for a completed order' })
  async create(@Body() dto: any, @Req() req: any) {
    const review = await this.reviewsService.create(req.user.id, dto);
    return { success: true, data: review };
  }

  @Public()
  @Get('store/:storeId')
  @ApiOperation({ summary: 'Get store reviews' })
  async getStoreReviews(
    @Param('storeId') storeId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.reviewsService.getStoreReviews(storeId, +page, +limit);
  }
}
