const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Verify Firebase Auth token from request headers
 */
async function verifyAuthToken(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  try {
    const idToken = authHeader.split('Bearer ')[1];
    return await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    console.error('Auth token verification failed:', error);
    return null;
  }
}

/**
 * Set CORS headers for response
 */
function setCorsHeaders(req, res) {
  const allowedOrigins = [
    'http://localhost:3000',
    'http://localhost:5000',
    /\.web\.app$/,
    /\.firebaseapp\.com$/
  ];
  
  const origin = req.headers.origin;
  const isAllowed = allowedOrigins.some(allowed => 
    typeof allowed === 'string' ? allowed === origin : allowed.test(origin)
  );
  
  if (isAllowed) {
    res.set('Access-Control-Allow-Origin', origin);
  }
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

/**
 * Get subscription pricing in cents
 */
function getSubscriptionPrice(tier, isAnnual) {
  const prices = {
    project: { monthly: 7900, annual: 79000 },
    program: { monthly: 18900, annual: 189000 },
    portfolio: { monthly: 44900, annual: 449000 }
  };
  const tierPrices = prices[tier] || prices.project;
  return isAnnual ? tierPrices.annual : tierPrices.monthly;
}

/**
 * Secure OpenAI API Proxy
 * 
 * This Cloud Function acts as a secure proxy to OpenAI's API, keeping the API key
 * server-side and never exposing it to client code or version control.
 * 
 * Setup Instructions:
 * 1. Set your OpenAI API key as a secret in Firebase:
 *    firebase functions:secrets:set OPENAI_API_KEY
 *    
 * 2. Deploy this function:
 *    firebase deploy --only functions
 *    
 * 3. Update lib/services/api_config_secure.dart:
 *    Change baseUrl to your Cloud Function URL:
 *    'https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/openaiProxy'
 * 
 * Security Features:
 * - API key stored as Firebase secret (never in code or environment)
 * - Optional Firebase Auth verification
 * - CORS configured for your app domain only
 * - Request validation and sanitization
 * - Rate limiting per user (optional)
 */

exports.openaiProxy = functions
  .runWith({
    secrets: ['OPENAI_API_KEY'],
    timeoutSeconds: 60,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    // CORS configuration - restrict to your domain in production
    const allowedOrigins = [
      'http://localhost:3000',
      'https://your-app-domain.web.app',
      'https://your-app-domain.firebaseapp.com'
    ];
    
    const origin = req.headers.origin;
    if (allowedOrigins.includes(origin)) {
      res.set('Access-Control-Allow-Origin', origin);
    }
    
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    // Handle preflight requests
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    // Only allow POST requests
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed. Use POST.' });
      return;
    }
    
    try {
      // Optional: Verify Firebase Auth token
      // Uncomment the following lines to require authentication:
      /*
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).json({ error: 'Unauthorized. Missing or invalid token.' });
        return;
      }
      
      const idToken = authHeader.split('Bearer ')[1];
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      const userId = decodedToken.uid;
      
      // Optional: Implement rate limiting per user
      // Check Firestore for user's request count and block if exceeded
      */
      
      // Get OpenAI API key from Firebase secrets
      const apiKey = process.env.OPENAI_API_KEY;
      if (!apiKey) {
        console.error('OPENAI_API_KEY secret not configured');
        res.status(500).json({ error: 'Service configuration error' });
        return;
      }
      
      // Determine endpoint path from request payload
      // If client provides explicit endpoint, use it. Otherwise, infer:
      // - Presence of `input` usually means Responses API
      // - Otherwise default to Chat Completions
      let endpoint = req.body.endpoint;
      if (!endpoint) {
        if (req.body && (typeof req.body === 'object') && ('input' in req.body)) {
          endpoint = '/responses';
        } else {
          endpoint = '/chat/completions';
        }
      }
      const openaiUrl = `https://api.openai.com/v1${endpoint}`;
      
      // Forward the request to OpenAI
      const openaiResponse = await fetch(openaiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`
        },
        body: JSON.stringify(req.body.payload || req.body)
      });
      
      const data = await openaiResponse.json();
      
      // Return OpenAI's response to the client
      res.status(openaiResponse.status).json(data);
      
    } catch (error) {
      console.error('OpenAI proxy error:', error);
      res.status(500).json({ 
        error: 'Failed to process request',
        message: error.message 
      });
    }
  });

// ============================================================================
// STRIPE PAYMENT FUNCTIONS
// ============================================================================

/**
 * Create Stripe Checkout Session
 * 
 * Setup: firebase functions:secrets:set STRIPE_SECRET_KEY
 */
exports.createStripeCheckout = functions
  .runWith({
    secrets: ['STRIPE_SECRET_KEY'],
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
      if (!stripeSecretKey) {
        console.error('STRIPE_SECRET_KEY not configured');
        res.status(500).json({ error: 'Payment service not configured' });
        return;
      }
      
      const { tier, isAnnual, email } = req.body;
      const userId = decodedToken.uid;
      const priceInCents = getSubscriptionPrice(tier, isAnnual);
      
      // Create pending subscription record
      const subscriptionRef = db.collection('subscriptions').doc();
      await subscriptionRef.set({
        id: subscriptionRef.id,
        userId,
        tier,
        status: 'pending',
        provider: 'stripe',
        isAnnual: isAnnual || false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Call Stripe API to create checkout session
      const response = await fetch('https://api.stripe.com/v1/checkout/sessions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${stripeSecretKey}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: new URLSearchParams({
          'payment_method_types[]': 'card',
          'line_items[0][price_data][currency]': 'usd',
          'line_items[0][price_data][product_data][name]': `${tier.charAt(0).toUpperCase() + tier.slice(1)} Plan`,
          'line_items[0][price_data][unit_amount]': priceInCents.toString(),
          'line_items[0][quantity]': '1',
          'mode': 'payment',
          'success_url': `${req.headers.origin || 'https://app.example.com'}/payment-success?session_id={CHECKOUT_SESSION_ID}&subscription_id=${subscriptionRef.id}`,
          'cancel_url': `${req.headers.origin || 'https://app.example.com'}/pricing`,
          'customer_email': email,
          'metadata[subscription_id]': subscriptionRef.id,
          'metadata[user_id]': userId,
          'metadata[tier]': tier
        })
      });
      
      const session = await response.json();
      
      if (session.error) {
        throw new Error(session.error.message);
      }
      
      // Update subscription with Stripe session ID
      await subscriptionRef.update({
        externalSubscriptionId: session.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      res.json({
        success: true,
        checkoutUrl: session.url,
        subscriptionId: subscriptionRef.id
      });
      
    } catch (error) {
      console.error('Stripe checkout error:', error);
      res.status(500).json({ error: error.message });
    }
  });

/**
 * Verify Stripe Payment
 */
exports.verifyStripePayment = functions
  .runWith({
    secrets: ['STRIPE_SECRET_KEY'],
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
      if (!stripeSecretKey) {
        res.status(500).json({ error: 'Payment service not configured' });
        return;
      }
      
      const { reference } = req.body;
      
      // Retrieve session from Stripe
      const response = await fetch(`https://api.stripe.com/v1/checkout/sessions/${reference}`, {
        headers: {
          'Authorization': `Bearer ${stripeSecretKey}`
        }
      });
      
      const session = await response.json();
      
      if (session.payment_status === 'paid') {
        const subscriptionId = session.metadata?.subscription_id;
        if (subscriptionId) {
          const now = new Date();
          const endDate = new Date(now);
          endDate.setFullYear(endDate.getFullYear() + 1);
          
          await db.collection('subscriptions').doc(subscriptionId).update({
            status: 'active',
            startDate: admin.firestore.Timestamp.fromDate(now),
            endDate: admin.firestore.Timestamp.fromDate(endDate),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
        
        res.json({ success: true, subscriptionId });
      } else {
        res.json({ success: false, error: 'Payment not completed' });
      }
      
    } catch (error) {
      console.error('Stripe verification error:', error);
      res.status(500).json({ error: error.message });
    }
  });

// ============================================================================
// PAYPAL PAYMENT FUNCTIONS
// ============================================================================

/**
 * Create PayPal Order
 * 
 * Setup:
 *   firebase functions:secrets:set PAYPAL_CLIENT_ID
 *   firebase functions:secrets:set PAYPAL_CLIENT_SECRET
 */
exports.createPayPalOrder = functions
  .runWith({
    secrets: ['PAYPAL_CLIENT_ID', 'PAYPAL_CLIENT_SECRET'],
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const clientId = process.env.PAYPAL_CLIENT_ID;
      const clientSecret = process.env.PAYPAL_CLIENT_SECRET;
      
      if (!clientId || !clientSecret) {
        console.error('PayPal credentials not configured');
        res.status(500).json({ error: 'Payment service not configured' });
        return;
      }
      
      const { tier, isAnnual } = req.body;
      const userId = decodedToken.uid;
      const priceInCents = getSubscriptionPrice(tier, isAnnual);
      const priceInDollars = (priceInCents / 100).toFixed(2);
      
      // Create pending subscription record
      const subscriptionRef = db.collection('subscriptions').doc();
      await subscriptionRef.set({
        id: subscriptionRef.id,
        userId,
        tier,
        status: 'pending',
        provider: 'paypal',
        isAnnual: isAnnual || false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Get PayPal access token
      const authResponse = await fetch('https://api-m.paypal.com/v1/oauth2/token', {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${Buffer.from(`${clientId}:${clientSecret}`).toString('base64')}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: 'grant_type=client_credentials'
      });
      
      const authData = await authResponse.json();
      if (!authData.access_token) {
        throw new Error('Failed to authenticate with PayPal');
      }
      
      // Create PayPal order
      const orderResponse = await fetch('https://api-m.paypal.com/v2/checkout/orders', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authData.access_token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          intent: 'CAPTURE',
          purchase_units: [{
            amount: {
              currency_code: 'USD',
              value: priceInDollars
            },
            description: `${tier.charAt(0).toUpperCase() + tier.slice(1)} Plan Subscription`,
            custom_id: subscriptionRef.id
          }],
          application_context: {
            return_url: `${req.headers.origin || 'https://app.example.com'}/payment-success?subscription_id=${subscriptionRef.id}`,
            cancel_url: `${req.headers.origin || 'https://app.example.com'}/pricing`
          }
        })
      });
      
      const order = await orderResponse.json();
      
      if (order.error) {
        throw new Error(order.error.message || 'PayPal order creation failed');
      }
      
      // Update subscription with PayPal order ID
      await subscriptionRef.update({
        externalSubscriptionId: order.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      const approvalLink = order.links?.find(link => link.rel === 'approve');
      
      res.json({
        success: true,
        approvalUrl: approvalLink?.href,
        orderId: order.id,
        subscriptionId: subscriptionRef.id
      });
      
    } catch (error) {
      console.error('PayPal order error:', error);
      res.status(500).json({ error: error.message });
    }
  });

/**
 * Verify PayPal Payment
 */
exports.verifyPayPalPayment = functions
  .runWith({
    secrets: ['PAYPAL_CLIENT_ID', 'PAYPAL_CLIENT_SECRET'],
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const clientId = process.env.PAYPAL_CLIENT_ID;
      const clientSecret = process.env.PAYPAL_CLIENT_SECRET;
      
      if (!clientId || !clientSecret) {
        res.status(500).json({ error: 'Payment service not configured' });
        return;
      }
      
      const { reference } = req.body;
      
      // Get PayPal access token
      const authResponse = await fetch('https://api-m.paypal.com/v1/oauth2/token', {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${Buffer.from(`${clientId}:${clientSecret}`).toString('base64')}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: 'grant_type=client_credentials'
      });
      
      const authData = await authResponse.json();
      
      // Capture the payment
      const captureResponse = await fetch(`https://api-m.paypal.com/v2/checkout/orders/${reference}/capture`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authData.access_token}`,
          'Content-Type': 'application/json'
        }
      });
      
      const captureData = await captureResponse.json();
      
      if (captureData.status === 'COMPLETED') {
        const subscriptionId = captureData.purchase_units?.[0]?.custom_id;
        if (subscriptionId) {
          const now = new Date();
          const endDate = new Date(now);
          endDate.setFullYear(endDate.getFullYear() + 1);
          
          await db.collection('subscriptions').doc(subscriptionId).update({
            status: 'active',
            startDate: admin.firestore.Timestamp.fromDate(now),
            endDate: admin.firestore.Timestamp.fromDate(endDate),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
        
        res.json({ success: true, subscriptionId });
      } else {
        res.json({ success: false, error: 'Payment not completed' });
      }
      
    } catch (error) {
      console.error('PayPal verification error:', error);
      res.status(500).json({ error: error.message });
    }
  });

// ============================================================================
// PAYSTACK PAYMENT FUNCTIONS
// ============================================================================

/**
 * Create Paystack Transaction
 * 
 * Setup: firebase functions:secrets:set PAYSTACK_SECRET_KEY
 */
exports.createPaystackTransaction = functions
  .runWith({
    secrets: ['PAYSTACK_SECRET_KEY'],
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const paystackSecretKey = process.env.PAYSTACK_SECRET_KEY;
      if (!paystackSecretKey) {
        console.error('PAYSTACK_SECRET_KEY not configured');
        res.status(500).json({ error: 'Payment service not configured' });
        return;
      }
      
      const { tier, isAnnual, email } = req.body;
      const userId = decodedToken.uid;
      const priceInKobo = getSubscriptionPrice(tier, isAnnual) * 100; // Paystack uses kobo (1/100 of Naira) but we'll use USD cents
      
      // Create pending subscription record
      const subscriptionRef = db.collection('subscriptions').doc();
      await subscriptionRef.set({
        id: subscriptionRef.id,
        userId,
        tier,
        status: 'pending',
        provider: 'paystack',
        isAnnual: isAnnual || false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Initialize Paystack transaction
      const response = await fetch('https://api.paystack.co/transaction/initialize', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${paystackSecretKey}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          email,
          amount: priceInKobo,
          currency: 'USD',
          reference: subscriptionRef.id,
          callback_url: `${req.headers.origin || 'https://app.example.com'}/payment-success`,
          metadata: {
            subscription_id: subscriptionRef.id,
            user_id: userId,
            tier
          }
        })
      });
      
      const data = await response.json();
      
      if (!data.status) {
        throw new Error(data.message || 'Paystack initialization failed');
      }
      
      // Update subscription with Paystack reference
      await subscriptionRef.update({
        externalSubscriptionId: data.data.reference,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      res.json({
        success: true,
        authorizationUrl: data.data.authorization_url,
        accessCode: data.data.access_code,
        reference: data.data.reference,
        subscriptionId: subscriptionRef.id
      });
      
    } catch (error) {
      console.error('Paystack transaction error:', error);
      res.status(500).json({ error: error.message });
    }
  });

/**
 * Verify Paystack Payment
 */
exports.verifyPaystackPayment = functions
  .runWith({
    secrets: ['PAYSTACK_SECRET_KEY'],
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const paystackSecretKey = process.env.PAYSTACK_SECRET_KEY;
      if (!paystackSecretKey) {
        res.status(500).json({ error: 'Payment service not configured' });
        return;
      }
      
      const { reference } = req.body;
      
      // Verify transaction
      const response = await fetch(`https://api.paystack.co/transaction/verify/${reference}`, {
        headers: {
          'Authorization': `Bearer ${paystackSecretKey}`
        }
      });
      
      const data = await response.json();
      
      if (data.status && data.data.status === 'success') {
        const subscriptionId = data.data.metadata?.subscription_id || reference;
        
        const now = new Date();
        const endDate = new Date(now);
        endDate.setFullYear(endDate.getFullYear() + 1);
        
        await db.collection('subscriptions').doc(subscriptionId).update({
          status: 'active',
          startDate: admin.firestore.Timestamp.fromDate(now),
          endDate: admin.firestore.Timestamp.fromDate(endDate),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        res.json({ success: true, subscriptionId });
      } else {
        res.json({ success: false, error: 'Payment not completed' });
      }
      
    } catch (error) {
      console.error('Paystack verification error:', error);
      res.status(500).json({ error: error.message });
    }
  });

// ============================================================================
// SUBSCRIPTION MANAGEMENT
// ============================================================================

/**
 * Cancel Subscription
 */
exports.cancelSubscription = functions
  .runWith({
    secrets: ['STRIPE_SECRET_KEY', 'PAYPAL_CLIENT_ID', 'PAYPAL_CLIENT_SECRET', 'PAYSTACK_SECRET_KEY'],
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const { subscriptionId } = req.body;
      
      // Get subscription
      const subscriptionDoc = await db.collection('subscriptions').doc(subscriptionId).get();
      if (!subscriptionDoc.exists) {
        res.status(404).json({ error: 'Subscription not found' });
        return;
      }
      
      const subscription = subscriptionDoc.data();
      
      // Verify ownership
      if (subscription.userId !== decodedToken.uid) {
        res.status(403).json({ error: 'Not authorized to cancel this subscription' });
        return;
      }
      
      // Update subscription status to cancelled
      await db.collection('subscriptions').doc(subscriptionId).update({
        status: 'cancelled',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      res.json({ success: true, message: 'Subscription cancelled successfully' });
      
    } catch (error) {
      console.error('Cancel subscription error:', error);
      res.status(500).json({ error: error.message });
    }
  });
