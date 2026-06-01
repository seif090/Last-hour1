import { ApiProperty } from '@nestjs/swagger';

export class OrderItemResponse {
  @ApiProperty()
  id: string;

  @ApiProperty()
  productName: string;

  @ApiProperty()
  quantity: number;

  @ApiProperty()
  unitPrice: number;

  @ApiProperty()
  subtotal: number;
}

export class PaymentResponse {
  @ApiProperty()
  id: string;

  @ApiProperty()
  provider: string;

  @ApiProperty()
  status: string;

  @ApiProperty()
  amount: number;

  @ApiProperty({ required: false })
  iframeUrl?: string;
}

export class StoreBriefResponse {
  @ApiProperty()
  id: string;

  @ApiProperty()
  name: string;

  @ApiProperty({ required: false })
  slug?: string;

  @ApiProperty({ required: false })
  addressLine1?: string;
}

export class OrderResponse {
  @ApiProperty()
  id: string;

  @ApiProperty()
  orderNumber: string;

  @ApiProperty()
  status: string;

  @ApiProperty()
  quantity: number;

  @ApiProperty()
  unitPrice: number;

  @ApiProperty()
  subtotal: number;

  @ApiProperty()
  serviceFee: number;

  @ApiProperty()
  totalAmount: number;

  @ApiProperty()
  currency: string;

  @ApiProperty({ required: false })
  estimatedReadyAt?: Date;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty({ required: false, type: [OrderItemResponse] })
  items?: OrderItemResponse[];

  @ApiProperty({ required: false, type: PaymentResponse })
  payment?: PaymentResponse;

  @ApiProperty({ required: false, type: StoreBriefResponse })
  store?: StoreBriefResponse;
}
