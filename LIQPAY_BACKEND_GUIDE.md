# LiqPay Backend Integration Checklist

This checklist documents everything the backend service must implement so the vessel-owner mobile app can create and settle LiqPay payments without falling back to client-side signing.

---

## 1. High-Level Flow
1. **Mobile app** calls `POST /api/payments/create-liqpay-payment`.
2. **API** validates the request, persists a pending payment row, signs a LiqPay payload with the server's private key, and returns the signed payload + optional checkout URL/HTML.
3. **Mobile app** opens LiqPay checkout using the server-signed payload.
4. **LiqPay** sends asynchronous notifications to `POST /api/payments/liqpay-callback`.
5. **API** verifies LiqPay's signature, updates the payment record, activates the relevant subscription/pass, and responds `200 OK`.

---

## 2. Environment & Configuration
Add the following keys to the backend `.env` (and production secrets store):

```env
LIQPAY_PUBLIC_KEY=your-real-public-key
LIQPAY_PRIVATE_KEY=your-real-private-key
LIQPAY_ENVIRONMENT=sandbox              # or production
APP_BASE_URL=https://api-dev.sudnokontrol.online/api
CLIENT_PAYMENT_DEEP_LINK=sudno://payment-result
```

> **Note:** `APP_BASE_URL` must match what the mobile client uses for `EXPO_PUBLIC_API_BASE_URL` so that `server_url` points to the correct backend host.

---

## 3. Request Validation Schema
Use your preferred validator (Zod/Yup/Joi). Example with Zod:

```ts
import { z } from 'zod';

export const createPaymentSchema = z.object({
  amount: z.number().positive(),
  description: z.string().min(3),
  payment_type: z.enum(['single_trip', 'subscription']),
  vessel_id: z.string().uuid().optional(),
  subscription_plan_id: z.string().uuid().optional(),
});
```

Apply the schema inside the controller before proceeding.

---

## 4. Service Helpers
Create `src/services/liqpayService.ts` (or extend an existing service) to encapsulate signing & verification logic:

```ts
import crypto from 'crypto';

const LIQPAY_PUBLIC_KEY = process.env.LIQPAY_PUBLIC_KEY!;
const LIQPAY_PRIVATE_KEY = process.env.LIQPAY_PRIVATE_KEY!;
const APP_BASE_URL = (process.env.APP_BASE_URL ?? '').replace(/\/$/, '');
const CLIENT_PAYMENT_DEEP_LINK = process.env.CLIENT_PAYMENT_DEEP_LINK ?? 'sudno://payment-result';

export type PaymentAction = 'pay' | 'subscribe';

export interface LiqPayPayload {
  public_key: string;
  version: number;
  action: PaymentAction;
  amount: number;
  currency: 'UAH';
  description: string;
  order_id: string;
  result_url: string;
  server_url: string;
  language: 'uk';
  subscribe?: number;
  subscribe_date_start?: string;
  subscribe_periodicity?: string;
}

export function buildPayload(params: {
  orderId: string;
  action: PaymentAction;
  amount: number;
  description: string;
}): LiqPayPayload {
  const payload: LiqPayPayload = {
    public_key: LIQPAY_PUBLIC_KEY,
    version: 3,
    action: params.action,
    amount: params.amount,
    currency: 'UAH',
    description: params.description,
    order_id: params.orderId,
    result_url: CLIENT_PAYMENT_DEEP_LINK,
    server_url: `${APP_BASE_URL}/payments/liqpay-callback`,
    language: 'uk',
  };

  if (params.action === 'subscribe') {
    payload.subscribe = 1;
    payload.subscribe_date_start = new Date().toISOString().split('T')[0];
    payload.subscribe_periodicity = 'month';
  }

  return payload;
}

export function encodePayload(payload: LiqPayPayload) {
  const json = JSON.stringify(payload);
  const data = Buffer.from(json).toString('base64');
  const signature = crypto
    .createHash('sha1')
    .update(`${LIQPAY_PRIVATE_KEY}${data}${LIQPAY_PRIVATE_KEY}`, 'utf8')
    .digest('base64');
  return { data, signature };
}

export function verifyCallbackSignature(data: string, signature: string) {
  const expected = crypto
    .createHash('sha1')
    .update(`${LIQPAY_PRIVATE_KEY}${data}${LIQPAY_PRIVATE_KEY}`, 'utf8')
    .digest('base64');
  return expected === signature;
}
```

---

## 5. Controller Skeleton
Implement a new controller at `src/controllers/paymentController.ts`:

```ts
import { Request, Response, NextFunction } from 'express';
import { buildPayload, encodePayload, verifyCallbackSignature } from '../services/liqpayService';
import { createPaymentSchema } from '../validators/payments';
import { paymentsRepository } from '../repositories/paymentsRepository';

export async function createLiqPayPayment(req: Request, res: Response, next: NextFunction) {
  try {
    const body = createPaymentSchema.parse(req.body);
    const orderId = paymentsRepository.generateOrderId(body.payment_type); // implement helper

    await paymentsRepository.createPending({
      orderId,
      userId: req.user.id,
      amount: body.amount,
      description: body.description,
      type: body.payment_type,
      metadata: {
        vesselId: body.vessel_id,
        subscriptionPlanId: body.subscription_plan_id,
      },
    });

    const payload = buildPayload({
      orderId,
      action: body.payment_type === 'subscription' ? 'subscribe' : 'pay',
      amount: body.amount,
      description: body.description,
    });

    const { data, signature } = encodePayload(payload);

    return res.status(201).json({
      success: true,
      order_id: orderId,
      data,
      signature,
      checkout_url: `https://www.liqpay.ua/api/3/checkout?data=${encodeURIComponent(data)}&signature=${encodeURIComponent(signature)}`,
      form: {
        url: 'https://www.liqpay.ua/api/3/checkout',
        method: 'POST',
        data,
        signature,
        html: buildAutoSubmitHtml(data, signature), // helper shown below
      },
    });
  } catch (error) {
    next(error);
  }
}

export async function handleLiqPayCallback(req: Request, res: Response, next: NextFunction) {
  try {
    const { data, signature } = req.body as { data: string; signature: string };

    if (!data || !signature || !verifyCallbackSignature(data, signature)) {
      return res.status(400).json({ success: false, message: 'Invalid signature' });
    }

    const payload = JSON.parse(Buffer.from(data, 'base64').toString('utf8'));
    await paymentsRepository.markCompleted({ orderId: payload.order_id, payload });

    return res.json({ success: true });
  } catch (error) {
    next(error);
  }
}

function buildAutoSubmitHtml(data: string, signature: string) {
  return `<!DOCTYPE html><html><body>
    <form method="POST" action="https://www.liqpay.ua/api/3/checkout">
      <input type="hidden" name="data" value="${data}" />
      <input type="hidden" name="signature" value="${signature}" />
    </form>
    <script>document.forms[0].submit();</script>
  </body></html>`;
}
```

---

## 6. Express Routes
Create `src/routes/payments.ts` and wire everything up:

```ts
import { Router } from 'express';
import { createLiqPayPayment, handleLiqPayCallback } from '../controllers/paymentController';
import { authMiddleware } from '../middleware/auth';

const router = Router();

router.post('/create-liqpay-payment', authMiddleware, createLiqPayPayment);
router.post('/liqpay-callback', handleLiqPayCallback); // LiqPay servers cannot send JWT, keep this public but verify signature!

export default router;
```

Register the router in `src/index.ts`:

```ts
import paymentsRouter from './routes/payments';

app.use('/api/payments', paymentsRouter);
```

---

## 7. Persistence Layer
Update your repository / model layer:

```ts
// src/repositories/paymentsRepository.ts
import { db } from '../db'; // whatever DB helper you use
import { v4 as uuid } from 'uuid';

export function generateOrderId(type: string) {
  return `${type}_${Date.now()}_${uuid()}`;
}

export async function createPending(params: {
  orderId: string;
  userId: string;
  amount: number;
  description: string;
  type: string;
  metadata?: Record<string, unknown>;
}) {
  await db('payments').insert({
    order_id: params.orderId,
    user_id: params.userId,
    amount: params.amount,
    description: params.description,
    type: params.type,
    metadata: params.metadata,
    status: 'pending',
  });
}

export async function markCompleted({ orderId, payload }: { orderId: string; payload: any }) {
  await db('payments')
    .where({ order_id: orderId })
    .update({
      status: payload.status ?? 'success',
      liqpay_response: payload,
      paid_at: new Date(),
    });
}
```

Add/extend the `payments` table (Knex example):

```ts
exports.up = async function up(knex) {
  await knex.schema.createTable('payments', (table) => {
    table.uuid('order_id').primary();
    table.uuid('user_id').notNullable().references('id').inTable('users');
    table.decimal('amount', 12, 2).notNullable();
    table.string('description').notNullable();
    table.string('type').notNullable();
    table.jsonb('metadata');
    table.jsonb('liqpay_response');
    table.enum('status', ['pending', 'success', 'failure']).defaultTo('pending');
    table.timestamp('paid_at');
    table.timestamps(true, true);
  });
};
```

---

## 8. Security Considerations
- Never trust client-sent `public_key`, `order_id`, or `signature`; always rebuild them on the server.
- Store and audit every callback payload so you can reconcile transactions.
- Rate-limit `create-liqpay-payment` to prevent spamming.
- Log every callback (success & failure) for dispute resolution.
- Add alerts if LiqPay sends `status = failure`.

---

## 9. Testing Plan
1. Set `LIQPAY_ENVIRONMENT=sandbox` and use sandbox keys.
2. Hit `POST /api/payments/create-liqpay-payment` with a known token via Postman/cURL. Verify the response includes `data`, `signature`, `checkout_url`, `form.html`, and that a `payments` row is created.
3. Manually call `/api/payments/liqpay-callback` with the response you receive from LiqPay’s [test data generator](https://www.liqpay.ua/doc/forming_test_data). Confirm signature verification works and the payment row flips to `success`.
4. Enable `EXPO_PUBLIC_LIQPAY_USE_BACKEND=true` in the mobile app `.env`, restart Expo, and complete a sandbox payment via the device.
5. Move to production keys only after sandbox runs cleanly end-to-end.

---

## 10. Deliverables Checklist
- [ ] `.env` updated with LiqPay keys & URLs
- [ ] `liqpayService` helper with build/sign/verify functions
- [ ] `paymentController` create + callback handlers
- [ ] `/api/payments` routes registered
- [ ] Database migration for `payments` table (or equivalent persistence)
- [ ] Monitoring/logging for callbacks and failures
- [ ] Postman collection or HTTPie scripts to re-run sandbox tests
- [ ] Documentation updated for DevOps (ports, firewall allowing LiqPay IPs)

Once these items are in place, inform the mobile team to toggle `EXPO_PUBLIC_LIQPAY_USE_BACKEND=true` so the app uses the new backend endpoints instead of local fallbacks.
