# 🚀 Mobile App - LiqPay Integration Quick Start

**For Mobile App Developer**  
**Date:** October 1, 2025  
**Status:** Ready for Implementation

---

## 📋 What's Ready

✅ **Backend API** - Fully operational with LiqPay payment gateway  
✅ **Sandbox Credentials** - Testing environment configured  
✅ **Webhook** - Payment confirmation system working  
✅ **Admin Dashboard** - Subscription management interface live

---

## 🔐 Credentials (Sandbox)

Use these in your mobile app for testing:

```
Public Key:  sandbox_i47115455584
Private Key: sandbox_OgFbEGuhwjJi4taO8LKfCODL2jTRis0ex7PTVRMp
```

**Note:** These are sandbox credentials. Real payments won't be charged.

---

## 🎯 Quick Implementation Steps

### 1. Load Subscription Plans

```typescript
GET https://api-dev.sudnokontrol.online/api/subscriptions/plans
Headers: Authorization: Bearer <user_jwt_token>
```

### 2. Subscribe to Plan

```typescript
POST https://api-dev.sudnokontrol.online/api/subscriptions/subscribe
Headers: 
  Authorization: Bearer <user_jwt_token>
  Content-Type: application/json
Body: {
  "plan_id": "uuid-from-plans-list",
  "auto_renew": false,
  "payment_method": "liqpay"
}
```

**Returns:** `payment_form` (HTML) and `order_id`

### 3. Show Payment in WebView

```typescript
<WebView source={{ html: payment_form }} />
```

**Save the `order_id` from step 2 - you'll need it for activation!**

### 4. Handle Payment Completion

**⚠️ Important:** LiqPay sandbox may not call webhooks automatically.

**Option A: Wait for Webhook (Production & Some Sandbox)**
```typescript
// Wait 3-5 seconds after payment
await new Promise(r => setTimeout(r, 3000));

// Check payment status
GET https://api-dev.sudnokontrol.online/api/subscriptions/payment/status/:order_id
```

**Option B: Manual Activation (Sandbox Only - Recommended)**
```typescript
// After payment completes in WebView, manually activate:
POST https://api-dev.sudnokontrol.online/api/subscriptions/webhook/test/:order_id

// No authentication required
// Response: { "success": true, "message": "Subscription activated manually" }
```

**Implementation Example:**
```typescript
// After WebView payment completes
const activateSubscription = async (orderId: string) => {
  try {
    const response = await fetch(
      `${API_URL}/api/subscriptions/webhook/test/${orderId}`,
      { method: 'POST' }
    );
    const result = await response.json();

    if (result.success) {
      // Subscription activated, refresh user profile
      await checkAuth();
      navigation.navigate('Home');
    }
  } catch (error) {
    console.error('Manual activation failed:', error);
  }
};
```

### 5. Refresh User Profile

```typescript
GET https://api-dev.sudnokontrol.online/api/auth/profile
```

User will now have `subscription_status: "active"`

---

## 🧪 Test Cards

**Success:**
```
Card: 4242 4242 4242 4242
Expiry: 12/25
CVV: 123
```

**Fail:**
```
Card: 4000 0000 0000 0002
Expiry: 12/25
CVV: 123
```

---

## 📱 React Native WebView Example

```typescript
import { WebView } from 'react-native-webview';
import { useState } from 'react';

function PaymentScreen({ paymentForm, orderId }) {
  const [loading, setLoading] = useState(false);

  const checkStatus = async () => {
    setLoading(true);
    
    // Wait for webhook to process
    await new Promise(r => setTimeout(r, 3000));
    
    const response = await fetch(
      `https://api-dev.sudnokontrol.online/api/subscriptions/payment/status/${orderId}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    const { status } = await response.json();
    
    if (status === 'completed') {
      Alert.alert('Success', 'Subscription activated!');
      navigation.navigate('Home');
    } else {
      Alert.alert('Pending', 'Payment is processing...');
    }
    
    setLoading(false);
  };

  return (
    <View style={{ flex: 1 }}>
      <WebView 
        source={{ html: paymentForm }}
        onNavigationStateChange={(nav) => {
          if (nav.url.includes('sudnokontrol')) {
            checkStatus();
          }
        }}
      />
      {loading && <ActivityIndicator />}
    </View>
  );
}
```

---

## ⚠️ Important Notes

1. **Payment Processing:** After user pays, wait 3-5 seconds before checking status
2. **Polling:** Poll payment status every 2-3 seconds (max 10 attempts)
3. **WebView:** Enable JavaScript in WebView settings
4. **Refresh Profile:** Always refresh user profile after successful payment
5. **Trial Users:** Check `subscription_status` field - "trial" or "active" = access granted

---

## 📚 Complete Documentation

Full API reference with all endpoints, examples, and troubleshooting:
- `/var/www/sudnokontrol.online/MOBILE_API_DOCUMENTATION.md`
- `/var/www/sudnokontrol.online/LIQPAY_INTEGRATION_COMPLETE.md`

---

## 🐛 Common Issues

**Payment not activating?**
→ LiqPay sandbox may not call webhooks. Use manual activation endpoint (see Step 4, Option B)

**WebView blank?**
→ Enable JavaScript in WebView props

**Still shows "pending"?**
→ Use manual activation: `POST /api/subscriptions/webhook/test/:order_id`

**Manual activation returns 404?**
→ Check that you're using the correct `order_id` from the subscription response

---

## 📞 Need Help?

**Backend API:** https://api-dev.sudnokontrol.online  
**Admin Dashboard:** https://dev.sudnokontrol.online/subscriptions  
**LiqPay Docs:** https://www.liqpay.ua/documentation/uk

---

**Ready to test!** 🎉

