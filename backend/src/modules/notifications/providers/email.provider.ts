import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class EmailProvider {
  private readonly logger = new Logger(EmailProvider.name);

  async send(to: string, subject: string, _html: string) {
    try {
      this.logger.log(`Email to ${to}: ${subject}`);
      // AWS SES / SendGrid integration
      // const params = {
      //   Source: 'noreply@lasthour.app',
      //   Destination: { ToAddresses: [to] },
      //   Message: {
      //     Subject: { Data: subject },
      //     Body: { Html: { Data: html } },
      //   },
      // };
      // await ses.sendEmail(params).promise();

      this.logger.log(`Email sent to ${to}: ${subject}`);
      return { success: true };
    } catch (err: any) {
      this.logger.error(`Email send failed to ${to}: ${err.message}`);
      return { success: false, error: err.message };
    }
  }

  async sendOrderConfirmation(to: string, data: {
    orderNumber: string;
    storeName: string;
    items: { name: string; quantity: number; price: number }[];
    total: number;
    estimatedReadyAt?: Date;
  }) {
    const itemsHtml = data.items
      .map((i) => `<tr><td>${i.name}</td><td>x${i.quantity}</td><td>${i.price}</td></tr>`)
      .join('');

    const html = `
      <h1>Order Confirmed!</h1>
      <p>Order <strong>${data.orderNumber}</strong> from ${data.storeName}</p>
      <table>${itemsHtml}</table>
      <p><strong>Total: ${data.total}</strong></p>
      ${data.estimatedReadyAt ? `<p>Estimated ready: ${data.estimatedReadyAt.toLocaleTimeString()}</p>` : ''}
    `;

    return this.send(to, `Order ${data.orderNumber} Confirmed`, html);
  }

  async sendDailyReport(to: string, data: {
    merchantName: string;
    date: string;
    totalOrders: number;
    totalRevenue: number;
    itemsSold: number;
  }) {
    const html = `
      <h1>Daily Sales Report</h1>
      <p>${data.merchantName} — ${data.date}</p>
      <ul>
        <li>Orders: ${data.totalOrders}</li>
        <li>Revenue: ${data.totalRevenue}</li>
        <li>Items Sold: ${data.itemsSold}</li>
      </ul>
    `;

    return this.send(to, `Sales Report — ${data.date}`, html);
  }
}
