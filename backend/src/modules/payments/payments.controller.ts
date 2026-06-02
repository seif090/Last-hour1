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
import { ApiTags, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';

@ApiTags('Payments')
@Controller('payments')
export class PaymentsController {
  private readonly logger = new Logger(PaymentsController.name);

  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('paymob/webhook')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Paymob transaction callback webhook' })
  @ApiQuery({ name: 'hmac', required: false })
  async paymobWebhook(
    @Query('hmac') hmac: string,
    @Body() body: Record<string, unknown>,
  ) {
    this.logger.log('Received Paymob webhook event');

    if (!hmac) {
      throw new BadRequestException('HMAC is required');
    }
    if (!body || !body.obj) {
      throw new BadRequestException('Transaction payload (body.obj) is required');
    }

    const obj = body.obj as Record<string, unknown>;
    const verified = this.paymentsService.verifyPaymobWebhook(hmac, obj);
    if (!verified) {
      this.logger.warn('Paymob webhook verification failed: Invalid HMAC');
      throw new BadRequestException('Invalid HMAC signature');
    }

    await this.paymentsService.handlePaymobWebhook(obj);
    return { success: true };
  }
}
