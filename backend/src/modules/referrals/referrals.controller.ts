import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { Request } from 'express';
import { ReferralsService } from './referrals.service';

@ApiTags('Referrals')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'))
@Controller('referrals')
export class ReferralsController {
  constructor(private readonly referralsService: ReferralsService) {}

  @Get('info')
  @ApiOperation({ summary: 'Get referral code and stats' })
  async getInfo(@Req() req: Request) {
    return this.referralsService.getReferralInfo(req.user!.id);
  }

  @Get()
  @ApiOperation({ summary: 'List my referred users' })
  async getReferrals(@Req() req: Request) {
    const referrals = await this.referralsService.getReferrals(req.user!.id);
    return { success: true, data: referrals };
  }

  @Get('rewards')
  @ApiOperation({ summary: 'Get referral rewards summary' })
  async getRewards(@Req() req: Request) {
    return this.referralsService.getRewardsSummary(req.user!.id);
  }
}
