import {
  Controller,
  Post,
  Body,
  Query,
  BadRequestException,
  HttpCode,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';

@ApiTags('Payments')
@Controller('payments')
export class PaymentsController {
  private readonly logger = new Logger(PaymentsController.name);

  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('paymob/webhook')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Paymob transaction callback webhook' })
  async paymobWebhook(
    @Query('hmac') hmac: string,
    @Body() body: any,
  ) {
    this.logger.log('Received Paymob webhook event');

    if (!hmac) {
      throw new BadRequestException('HMAC is required');
    }
    if (!body || !body.obj) {
      throw new BadRequestException('Transaction payload (body.obj) is required');
    }

    const verified = this.paymentsService.verifyPaymobWebhook(hmac, body.obj);
    if (!verified) {
      this.logger.warn('Paymob webhook verification failed: Invalid HMAC');
      throw new BadRequestException('Invalid HMAC signature');
    }

    await this.paymentsService.handlePaymobWebhook(body.obj);
    return { success: true };
  }
}
