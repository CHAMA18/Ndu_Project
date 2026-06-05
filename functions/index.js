const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Initialize admin only if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const DEFAULT_OPENAI_WORKFLOW_ID = 'wf_69f1f5acc7ec819082fb76bbbf79b64d088ea0e514080150';

// Lazy-load config to avoid deployment timeouts
function getRuntimeConfig() {
  try {
    return typeof functions.config === 'function' ? functions.config() : {};
  } catch (e) {
    console.warn('Failed to load runtime config:', e);
    return {};
  }
}

function getCorsAllowedOrigins() {
  const runtimeConfig = getRuntimeConfig();
  const appConfig = runtimeConfig.app || {};
  const configuredBaseUrl = appConfig.base_url || appConfig.baseUrl || '';
  const configAllowedOrigins = appConfig.allowed_origins || appConfig.allowedOrigins || '';
  const envAllowedOrigins = process.env.APP_ALLOWED_ORIGINS || '';
  const APP_BASE_URL = process.env.APP_BASE_URL || configuredBaseUrl || 'https://ndu-d3f60.web.app';
  const EXTRA_ALLOWED_ORIGINS = [configAllowedOrigins, envAllowedOrigins]
    .flatMap((value) => value.split(','))
    .map((origin) => origin.trim())
    .filter(Boolean);
  return [
    /^(http|https):\/\/localhost(:\d+)?$/,
    /^(http|https):\/\/127\.0\.0\.1(:\d+)?$/,
    /\.web\.app$/,
    /\.firebaseapp\.com$/,
    /^https:\/\/staging\.admin\.nduproject\.com$/,
    /^https:\/\/.*\.nduproject\.com$/, // Allow all nduproject.com subdomains
    /^https:\/\/nduproject\.com$/, // Allow bare domain
    /^https:\/\/www\.nduproject\.com$/, // Allow www
    APP_BASE_URL,
    ...EXTRA_ALLOWED_ORIGINS
  ];
}

const FX_CACHE_TTL_MS = 6 * 60 * 60 * 1000;
const fxCache = { usdToNgn: null, fetchedAt: 0 };

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
  const origin = (req.headers.origin || '').toString().trim();
  const CORS_ALLOWED_ORIGINS = getCorsAllowedOrigins();
  const isAllowed = origin.length > 0 && CORS_ALLOWED_ORIGINS.some((allowed) =>
    typeof allowed === 'string' ? allowed === origin : allowed.test(origin)
  );

  if (isAllowed) {
    res.set('Access-Control-Allow-Origin', origin);
  } else if (req.method === 'OPTIONS') {
    // Keep preflight resilient even if an origin string is unexpectedly missing
    // or slightly different from runtime configuration.
    res.set('Access-Control-Allow-Origin', '*');
  }
  res.set('Vary', 'Origin');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

function getConfiguredOpenAiWorkflowId(req) {
  // Only use workflow when EXPLICITLY requested by the client.
  // Removed DEFAULT_OPENAI_WORKFLOW_ID fallback to avoid routing all
  // requests through the Workflows API (which injects unsupported
  // parameters like 'reasoning' causing 400 errors).
  const explicitWorkflowId =
    req.body?.workflow_id ||
    req.body?.workflowId ||
    req.body?.payload?.workflow_id ||
    req.body?.payload?.workflowId ||
    process.env.OPENAI_WORKFLOW_ID ||
    '';  // No default workflow — direct API calls by default

  const workflowId = String(explicitWorkflowId || '').trim();
  return workflowId.startsWith('wf_') ? workflowId : '';
}

function stripWorkflowFields(payload) {
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
    return payload;
  }
  const { workflow_id, workflowId, ...rest } = payload;
  return rest;
}

/**
 * Strip parameters that are not supported by the target OpenAI model.
 * The 'reasoning' parameter is only valid for o-series reasoning models
 * (o1, o3, etc.) and causes a 400 error with gpt-4o / gpt-4o-mini.
 */
function stripInvalidModelParams(payload) {
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
    return payload;
  }
  const { reasoning, ...rest } = payload;
  if (reasoning) {
    console.log('Stripped unsupported "reasoning" parameter from request payload.');
  }
  return rest;
}

function normalizeWorkflowInput(payload) {
  if (payload && Array.isArray(payload.input)) {
    return payload.input;
  }

  if (payload && Array.isArray(payload.messages)) {
    return payload.messages.map((message) => {
      const role = message?.role || 'user';
      const content = message?.content;
      if (Array.isArray(content)) {
        return { role, content };
      }
      return {
        role,
        content: [
          {
            type: role === 'assistant' ? 'output_text' : 'input_text',
            text: String(content || '')
          }
        ]
      };
    });
  }

  return [
    {
      role: 'user',
      content: [
        {
          type: 'input_text',
          text: typeof payload === 'string' ? payload : JSON.stringify(payload || {})
        }
      ]
    }
  ];
}

function extractWorkflowText(value) {
  if (typeof value === 'string') return value;
  if (!value || typeof value !== 'object') return '';

  const preferredKeys = ['output_text', 'final_output', 'text', 'content'];
  for (const key of preferredKeys) {
    const candidate = value[key];
    if (typeof candidate === 'string' && candidate.trim()) {
      return candidate;
    }
  }

  if (Array.isArray(value)) {
    for (const item of value) {
      const found = extractWorkflowText(item);
      if (found.trim()) return found;
    }
    return '';
  }

  for (const nested of Object.values(value)) {
    const found = extractWorkflowText(nested);
    if (found.trim()) return found;
  }

  return '';
}

function normalizeWorkflowResponse(data, endpoint, workflowId) {
  const text = extractWorkflowText(data);
  if (endpoint === '/responses') {
    return {
      id: data?.id || data?.workflow_run?.id || `resp-${workflowId}`,
      object: 'response',
      output: [
        {
          type: 'message',
          role: 'assistant',
          content: [
            {
              type: 'output_text',
              text
            }
          ]
        }
      ],
      workflow_run: data?.workflow_run || data
    };
  }

  return {
    id: data?.id || data?.workflow_run?.id || `chatcmpl-${workflowId}`,
    object: 'chat.completion',
    model: `openai-workflow-${workflowId}`,
    choices: [
      {
        index: 0,
        message: {
          role: 'assistant',
          content: text
        },
        finish_reason: 'stop'
      }
    ],
    workflow_run: data?.workflow_run || data
  };
}

function getRequestOrigin(req) {
  return req.headers.origin || APP_BASE_URL;
}

function getPayPalBaseUrl(clientId) {
  const env = (process.env.PAYPAL_ENV || '').toLowerCase();
  if (env === 'sandbox') return 'https://api-m.sandbox.paypal.com';
  if (env === 'live') return 'https://api-m.paypal.com';

  const normalizedId = (clientId || '').toLowerCase();
  if (normalizedId.startsWith('sb') || normalizedId.includes('sandbox')) {
    return 'https://api-m.sandbox.paypal.com';
  }

  return 'https://api-m.paypal.com';
}

async function getUsdToNgnRate() {
  const now = Date.now();
  if (fxCache.usdToNgn && now - fxCache.fetchedAt < FX_CACHE_TTL_MS) {
    return fxCache.usdToNgn;
  }

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 3500);
    const response = await fetch('https://open.er-api.com/v6/latest/USD', {
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (!response.ok) {
      throw new Error(`FX fetch failed (${response.status})`);
    }

    const data = await response.json();
    const rate = Number(data?.rates?.NGN);
    if (!Number.isFinite(rate) || rate <= 0) {
      throw new Error('FX rate for NGN unavailable');
    }

    fxCache.usdToNgn = rate;
    fxCache.fetchedAt = now;
    return rate;
  } catch (error) {
    console.warn('FX rate fetch failed:', error.message || error);
    return null;
  }
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
 * Validate a coupon and calculate the discounted price (in cents).
 */
async function validateCouponForTier(couponCode, tier, originalPriceCents) {
  if (!couponCode) {
    return { couponId: null, discountedPriceCents: originalPriceCents, discountPercent: 0, discountAmount: 0 };
  }

  const couponSnapshot = await db.collection('coupons')
    .where('code', '==', couponCode.toUpperCase())
    .limit(1)
    .get();

  if (couponSnapshot.empty) {
    throw new Error('Coupon not found');
  }

  const couponDoc = couponSnapshot.docs[0];
  const coupon = couponDoc.data();

  const now = new Date();
  const validFrom = coupon.validFrom?.toDate ? coupon.validFrom.toDate() : new Date(0);
  const validUntil = coupon.validUntil?.toDate ? coupon.validUntil.toDate() : new Date(0);

  if (!coupon.isActive) throw new Error('Coupon is inactive');
  if (now < validFrom || now > validUntil) throw new Error('Coupon has expired');
  if (coupon.maxUses && coupon.currentUses >= coupon.maxUses) throw new Error('Coupon usage limit reached');
  if (coupon.applicableTiers && coupon.applicableTiers.length > 0 && !coupon.applicableTiers.includes(tier)) {
    throw new Error('Coupon not valid for this plan');
  }

  let discountedPriceCents = originalPriceCents;
  if (coupon.discountAmount && coupon.discountAmount > 0) {
    discountedPriceCents = Math.max(0, originalPriceCents - Math.round(coupon.discountAmount * 100));
  } else if (coupon.discountPercent && coupon.discountPercent > 0) {
    discountedPriceCents = Math.max(0, Math.round(originalPriceCents * (1 - coupon.discountPercent / 100)));
  }

  return {
    couponId: couponDoc.id,
    discountedPriceCents,
    discountPercent: coupon.discountPercent || 0,
    discountAmount: coupon.discountAmount || 0,
  };
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
    // Use the centralized CORS helper function
    setCorsHeaders(req, res);
    
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
      
      const workflowId = getConfiguredOpenAiWorkflowId(req);

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
      const requestPayload = stripInvalidModelParams(stripWorkflowFields(req.body.payload || req.body));
      const openaiUrl = workflowId
        ? `https://api.openai.com/v1/workflows/${workflowId}/run`
        : `https://api.openai.com/v1${endpoint}`;
      const openaiPayload = workflowId
        ? {
            input_data: {
              input: normalizeWorkflowInput(requestPayload)
            },
            state_values: [],
            session: true,
            tracing: { enabled: true },
            stream: false
          }
        : requestPayload;
      
      // Forward the request to OpenAI
      const openaiResponse = await fetch(openaiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`
        },
        body: JSON.stringify(openaiPayload)
      });
      
      const data = await openaiResponse.json();
      
      // Return OpenAI's response to the client
      res.status(openaiResponse.status).json(
        workflowId && openaiResponse.ok
          ? normalizeWorkflowResponse(data, endpoint, workflowId)
          : data
      );
      
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
      
      const { tier, isAnnual, email, couponCode } = req.body;
      const userId = decodedToken.uid;
      let priceInCents = getSubscriptionPrice(tier, isAnnual);
      let couponId = null;

      if (couponCode) {
        try {
          const couponResult = await validateCouponForTier(couponCode, tier, priceInCents);
          priceInCents = couponResult.discountedPriceCents;
          couponId = couponResult.couponId;
        } catch (err) {
          res.status(400).json({ error: err.message || 'Invalid coupon' });
          return;
        }
      }
      
      // Create pending subscription record
      const subscriptionRef = db.collection('subscriptions').doc();
      await subscriptionRef.set({
        id: subscriptionRef.id,
        userId,
        tier,
        status: 'pending',
        provider: 'stripe',
        isAnnual: isAnnual || false,
        couponId: couponId || null,
        couponCode: couponCode ? couponCode.toUpperCase() : null,
        discountedPriceCents: priceInCents,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Call Stripe API to create checkout session
      const origin = getRequestOrigin(req);
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
          'success_url': `${origin}/payment-success?session_id={CHECKOUT_SESSION_ID}&subscription_id=${subscriptionRef.id}`,
          'cancel_url': `${origin}/pricing`,
          'customer_email': email,
          'metadata[subscription_id]': subscriptionRef.id,
          'metadata[user_id]': userId,
          'metadata[tier]': tier,
          ...(couponId ? { 'metadata[coupon_id]': couponId } : {})
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
        const userId = session.metadata?.user_id;
        const tier = session.metadata?.tier;
        const couponId = session.metadata?.coupon_id;
        
        if (subscriptionId) {
          const now = new Date();
          const endDate = new Date(now);
          endDate.setFullYear(endDate.getFullYear() + 1);

          const subscriptionDoc = await db.collection('subscriptions').doc(subscriptionId).get();
          const subscriptionData = subscriptionDoc.data() || {};
          
          await db.collection('subscriptions').doc(subscriptionId).update({
            status: 'active',
            startDate: admin.firestore.Timestamp.fromDate(now),
            endDate: admin.firestore.Timestamp.fromDate(endDate),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });

          const appliedCouponId = couponId || subscriptionData.couponId;
          if (appliedCouponId) {
            await db.collection('coupons').doc(appliedCouponId).update({
              currentUses: admin.firestore.FieldValue.increment(1),
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
          }
          
          // Record invoice
          const invoiceRef = db.collection('invoices').doc();
          await invoiceRef.set({
            id: invoiceRef.id,
            userId: userId || decodedToken.uid,
            amount: session.amount_total / 100,
            currency: (session.currency || 'usd').toUpperCase(),
            status: 'paid',
            provider: 'stripe',
            subscriptionId,
            externalId: session.id,
            tier,
            description: `${tier ? tier.charAt(0).toUpperCase() + tier.slice(1) : ''} Plan Subscription`,
            receiptUrl: session.receipt_url || null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            paidAt: admin.firestore.FieldValue.serverTimestamp(),
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
      
      const { tier, isAnnual, couponCode } = req.body;
      const userId = decodedToken.uid;
      let priceInCents = getSubscriptionPrice(tier, isAnnual);
      let couponId = null;

      if (couponCode) {
        try {
          const couponResult = await validateCouponForTier(couponCode, tier, priceInCents);
          priceInCents = couponResult.discountedPriceCents;
          couponId = couponResult.couponId;
        } catch (err) {
          res.status(400).json({ error: err.message || 'Invalid coupon' });
          return;
        }
      }
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
        couponId: couponId || null,
        couponCode: couponCode ? couponCode.toUpperCase() : null,
        discountedPriceCents: priceInCents,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Get PayPal access token
      const paypalBaseUrl = getPayPalBaseUrl(clientId);
      const authResponse = await fetch(`${paypalBaseUrl}/v1/oauth2/token`, {
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
      const origin = getRequestOrigin(req);
      const orderResponse = await fetch(`${paypalBaseUrl}/v2/checkout/orders`, {
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
            return_url: `${origin}/payment-success?subscription_id=${subscriptionRef.id}`,
            cancel_url: `${origin}/pricing`
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
      const paypalBaseUrl = getPayPalBaseUrl(clientId);
      const authResponse = await fetch(`${paypalBaseUrl}/v1/oauth2/token`, {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${Buffer.from(`${clientId}:${clientSecret}`).toString('base64')}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: 'grant_type=client_credentials'
      });
      
      const authData = await authResponse.json();
      
      // Capture the payment
      const captureResponse = await fetch(`${paypalBaseUrl}/v2/checkout/orders/${reference}/capture`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authData.access_token}`,
          'Content-Type': 'application/json'
        }
      });
      
      const captureData = await captureResponse.json();
      
      if (captureData.status === 'COMPLETED') {
        const subscriptionId = captureData.purchase_units?.[0]?.custom_id;
        const purchaseUnit = captureData.purchase_units?.[0];
        const capture = purchaseUnit?.payments?.captures?.[0];
        
        if (subscriptionId) {
          const now = new Date();
          const endDate = new Date(now);
          endDate.setFullYear(endDate.getFullYear() + 1);
          
          // Get subscription to get tier and userId
          const subscriptionDoc = await db.collection('subscriptions').doc(subscriptionId).get();
          const subscriptionData = subscriptionDoc.data() || {};
          
          await db.collection('subscriptions').doc(subscriptionId).update({
            status: 'active',
            startDate: admin.firestore.Timestamp.fromDate(now),
            endDate: admin.firestore.Timestamp.fromDate(endDate),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });

          if (subscriptionData.couponId) {
            await db.collection('coupons').doc(subscriptionData.couponId).update({
              currentUses: admin.firestore.FieldValue.increment(1),
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
          }
          
          // Record invoice
          const invoiceRef = db.collection('invoices').doc();
          await invoiceRef.set({
            id: invoiceRef.id,
            userId: subscriptionData.userId || decodedToken.uid,
            amount: parseFloat(capture?.amount?.value || purchaseUnit?.amount?.value || 0),
            currency: (capture?.amount?.currency_code || purchaseUnit?.amount?.currency_code || 'USD'),
            status: 'paid',
            provider: 'paypal',
            subscriptionId,
            externalId: captureData.id,
            tier: subscriptionData.tier,
            description: `${subscriptionData.tier ? subscriptionData.tier.charAt(0).toUpperCase() + subscriptionData.tier.slice(1) : ''} Plan Subscription`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            paidAt: admin.firestore.FieldValue.serverTimestamp(),
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
      
      const { tier, isAnnual, email, couponCode } = req.body;
      const userId = decodedToken.uid;
      let priceInCents = getSubscriptionPrice(tier, isAnnual);
      let couponId = null;

      if (couponCode) {
        try {
          const couponResult = await validateCouponForTier(couponCode, tier, priceInCents);
          priceInCents = couponResult.discountedPriceCents;
          couponId = couponResult.couponId;
        } catch (err) {
          res.status(400).json({ error: err.message || 'Invalid coupon' });
          return;
        }
      }

      const paystackCurrency = (process.env.PAYSTACK_CURRENCY || 'NGN').toUpperCase();
      const paystackUsdRateRaw = process.env.PAYSTACK_USD_TO_NGN;
      const paystackUsdRateOverride = Number.isFinite(Number(paystackUsdRateRaw)) ? Number(paystackUsdRateRaw) : null;
      const liveUsdToNgnRate = paystackCurrency === 'NGN' ? await getUsdToNgnRate() : null;
      const paystackUsdRate = paystackUsdRateOverride ?? liveUsdToNgnRate ?? 1500;
      const paystackUsdEquivalentRaw = process.env.PAYSTACK_USD_EQUIVALENT;
      const paystackUsdEquivalent = Number.isFinite(Number(paystackUsdEquivalentRaw)) ? Number(paystackUsdEquivalentRaw) : 20;
      const baseUsdAmount = paystackUsdEquivalent > 0 ? paystackUsdEquivalent : (priceInCents / 100);
      let priceInMinorUnits;

      if (paystackCurrency === 'NGN') {
        priceInMinorUnits = Math.round(baseUsdAmount * paystackUsdRate * 100);
      } else {
        const paystackAmountMultiplierRaw = process.env.PAYSTACK_AMOUNT_MULTIPLIER;
        const paystackAmountMultiplier = Number.isFinite(Number(paystackAmountMultiplierRaw))
          ? Number(paystackAmountMultiplierRaw)
          : 1;
        priceInMinorUnits = Math.round(priceInCents * paystackAmountMultiplier);
      }
      
      // Create pending subscription record
      const subscriptionRef = db.collection('subscriptions').doc();
      await subscriptionRef.set({
        id: subscriptionRef.id,
        userId,
        tier,
        status: 'pending',
        provider: 'paystack',
        isAnnual: isAnnual || false,
        couponId: couponId || null,
        couponCode: couponCode ? couponCode.toUpperCase() : null,
        discountedPriceCents: priceInCents,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Initialize Paystack transaction
      const origin = getRequestOrigin(req);
      const response = await fetch('https://api.paystack.co/transaction/initialize', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${paystackSecretKey}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          email,
          amount: priceInMinorUnits,
          currency: paystackCurrency,
          reference: subscriptionRef.id,
          callback_url: `${origin}/payment-success`,
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
        const txnData = data.data;
        
        const now = new Date();
        const endDate = new Date(now);
        endDate.setFullYear(endDate.getFullYear() + 1);
        
        // Get subscription to get tier and userId
        const subscriptionDoc = await db.collection('subscriptions').doc(subscriptionId).get();
        const subscriptionData = subscriptionDoc.data() || {};
        
        await db.collection('subscriptions').doc(subscriptionId).update({
          status: 'active',
          startDate: admin.firestore.Timestamp.fromDate(now),
          endDate: admin.firestore.Timestamp.fromDate(endDate),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        if (subscriptionData.couponId) {
          await db.collection('coupons').doc(subscriptionData.couponId).update({
            currentUses: admin.firestore.FieldValue.increment(1),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
        
        // Record invoice
        const invoiceRef = db.collection('invoices').doc();
        await invoiceRef.set({
          id: invoiceRef.id,
          userId: subscriptionData.userId || decodedToken.uid,
          amount: (txnData.amount || 0) / 100,
          currency: txnData.currency || 'NGN',
          status: 'paid',
          provider: 'paystack',
          subscriptionId,
          externalId: txnData.reference,
          tier: subscriptionData.tier || txnData.metadata?.tier,
          description: `${subscriptionData.tier ? subscriptionData.tier.charAt(0).toUpperCase() + subscriptionData.tier.slice(1) : ''} Plan Subscription`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
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
// COUPON MANAGEMENT
// ============================================================================

/**
 * Apply Coupon to Payment
 * Validates and applies a coupon code during checkout
 */
exports.applyCoupon = functions
  .runWith({
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
      
      const { couponCode, tier, originalPrice } = req.body;
      
      if (!couponCode || !tier || originalPrice === undefined) {
        res.status(400).json({ error: 'Missing required fields' });
        return;
      }

      const originalPriceCents = Math.round(Number(originalPrice) * 100);
      const couponResult = await validateCouponForTier(couponCode, tier, originalPriceCents);
      
      res.json({
        success: true,
        couponId: couponResult.couponId,
        originalPrice,
        discountedPrice: Math.round(couponResult.discountedPriceCents) / 100,
        discountPercent: couponResult.discountPercent,
        discountAmount: couponResult.discountAmount || 0,
        description: ''
      });
      
    } catch (error) {
      console.error('Apply coupon error:', error);
      res.status(500).json({ error: error.message });
    }
  });

/**
 * Use Coupon (increment usage count)
 * Called after successful payment
 */
exports.useCoupon = functions
  .runWith({
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
      
      const { couponId } = req.body;
      
      if (!couponId) {
        res.status(400).json({ error: 'Missing coupon ID' });
        return;
      }
      
      // Increment usage count
      await db.collection('coupons').doc(couponId).update({
        currentUses: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      res.json({ success: true });
      
    } catch (error) {
      console.error('Use coupon error:', error);
      res.status(500).json({ error: error.message });
    }
  });

// ============================================================================
// INVOICE HISTORY
// ============================================================================

/**
 * Get User Invoice History
 * Fetches payment history from all providers for a specific user
 */
exports.getUserInvoices = functions
  .runWith({
    secrets: ['STRIPE_SECRET_KEY', 'PAYPAL_CLIENT_ID', 'PAYPAL_CLIENT_SECRET', 'PAYSTACK_SECRET_KEY'],
    timeoutSeconds: 60,
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
      
      const { userId, userEmail } = req.body;
      const targetUserId = userId || decodedToken.uid;
      
      // Check if requesting user is admin or requesting own data
      const adminEmails = ['chungu424@gmail.com'];
      const isAdmin = adminEmails.includes(decodedToken.email);
      if (!isAdmin && targetUserId !== decodedToken.uid) {
        res.status(403).json({ error: 'Not authorized to view this user\'s invoices' });
        return;
      }
      
      const invoices = [];
      
      // Get subscriptions for the user to find external IDs
      const subscriptionsSnapshot = await db.collection('subscriptions')
        .where('userId', '==', targetUserId)
        .orderBy('createdAt', 'desc')
        .get();
      
      // Also fetch from invoices collection (stored after successful payments)
      const invoicesSnapshot = await db.collection('invoices')
        .where('userId', '==', targetUserId)
        .orderBy('createdAt', 'desc')
        .get();
      
      for (const doc of invoicesSnapshot.docs) {
        const data = doc.data();
        invoices.push({
          id: doc.id,
          amount: data.amount || 0,
          currency: data.currency || 'USD',
          status: data.status || 'paid',
          provider: data.provider || 'unknown',
          description: data.description || 'Subscription payment',
          createdAt: data.createdAt?.toDate()?.toISOString() || new Date().toISOString(),
          paidAt: data.paidAt?.toDate()?.toISOString(),
          subscriptionId: data.subscriptionId,
          externalId: data.externalId,
          tier: data.tier,
          receiptUrl: data.receiptUrl,
        });
      }
      
      // Try to fetch from Stripe if configured
      const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
      if (stripeSecretKey && userEmail) {
        try {
          // First find customer by email
          const customerResponse = await fetch(
            `https://api.stripe.com/v1/customers?email=${encodeURIComponent(userEmail)}&limit=1`,
            {
              headers: { 'Authorization': `Bearer ${stripeSecretKey}` }
            }
          );
          const customerData = await customerResponse.json();
          
          if (customerData.data && customerData.data.length > 0) {
            const customerId = customerData.data[0].id;
            
            // Fetch charges/payments for this customer
            const chargesResponse = await fetch(
              `https://api.stripe.com/v1/charges?customer=${customerId}&limit=100`,
              {
                headers: { 'Authorization': `Bearer ${stripeSecretKey}` }
              }
            );
            const chargesData = await chargesResponse.json();
            
            if (chargesData.data) {
              for (const charge of chargesData.data) {
                // Avoid duplicates
                if (!invoices.find(i => i.externalId === charge.id)) {
                  invoices.push({
                    id: `stripe_${charge.id}`,
                    amount: charge.amount / 100,
                    currency: charge.currency.toUpperCase(),
                    status: charge.status === 'succeeded' ? 'paid' : charge.status,
                    provider: 'stripe',
                    description: charge.description || 'Stripe payment',
                    createdAt: new Date(charge.created * 1000).toISOString(),
                    paidAt: charge.status === 'succeeded' ? new Date(charge.created * 1000).toISOString() : null,
                    externalId: charge.id,
                    receiptUrl: charge.receipt_url,
                    tier: charge.metadata?.tier,
                  });
                }
              }
            }
          }
        } catch (stripeError) {
          console.error('Error fetching Stripe invoices:', stripeError);
        }
      }
      
      // Try to fetch from PayPal if configured
      const paypalClientId = process.env.PAYPAL_CLIENT_ID;
      const paypalClientSecret = process.env.PAYPAL_CLIENT_SECRET;
      if (paypalClientId && paypalClientSecret && userEmail) {
        try {
          // Get PayPal access token
          const paypalBaseUrl = getPayPalBaseUrl(paypalClientId);
          const authResponse = await fetch(`${paypalBaseUrl}/v1/oauth2/token`, {
            method: 'POST',
            headers: {
              'Authorization': `Basic ${Buffer.from(`${paypalClientId}:${paypalClientSecret}`).toString('base64')}`,
              'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: 'grant_type=client_credentials'
          });
          
          const authData = await authResponse.json();
          if (authData.access_token) {
            // Search for transactions by email (PayPal Reporting API)
            const startDate = new Date();
            startDate.setFullYear(startDate.getFullYear() - 2);
            const endDate = new Date();
            
            const transactionsResponse = await fetch(
              `${paypalBaseUrl}/v1/reporting/transactions?start_date=${startDate.toISOString()}&end_date=${endDate.toISOString()}&fields=all`,
              {
                headers: {
                  'Authorization': `Bearer ${authData.access_token}`,
                  'Content-Type': 'application/json'
                }
              }
            );
            
            const transactionsData = await transactionsResponse.json();
            if (transactionsData.transaction_details) {
              for (const txn of transactionsData.transaction_details) {
                const info = txn.transaction_info || {};
                const payerEmail = txn.payer_info?.email_address;
                
                // Only include if payer email matches
                if (payerEmail && payerEmail.toLowerCase() === userEmail.toLowerCase()) {
                  if (!invoices.find(i => i.externalId === info.transaction_id)) {
                    invoices.push({
                      id: `paypal_${info.transaction_id}`,
                      amount: parseFloat(info.transaction_amount?.value || 0),
                      currency: info.transaction_amount?.currency_code || 'USD',
                      status: info.transaction_status === 'S' ? 'paid' : info.transaction_status,
                      provider: 'paypal',
                      description: info.transaction_subject || 'PayPal payment',
                      createdAt: info.transaction_initiation_date || new Date().toISOString(),
                      paidAt: info.transaction_updated_date,
                      externalId: info.transaction_id,
                    });
                  }
                }
              }
            }
          }
        } catch (paypalError) {
          console.error('Error fetching PayPal invoices:', paypalError);
        }
      }
      
      // Try to fetch from Paystack if configured
      const paystackSecretKey = process.env.PAYSTACK_SECRET_KEY;
      if (paystackSecretKey && userEmail) {
        try {
          // First find customer by email
          const customerResponse = await fetch(
            `https://api.paystack.co/customer/${encodeURIComponent(userEmail)}`,
            {
              headers: { 'Authorization': `Bearer ${paystackSecretKey}` }
            }
          );
          const customerData = await customerResponse.json();
          
          if (customerData.status && customerData.data) {
            const customerCode = customerData.data.customer_code;
            
            // Fetch transactions for this customer
            const transactionsResponse = await fetch(
              `https://api.paystack.co/transaction?customer=${customerCode}&perPage=100`,
              {
                headers: { 'Authorization': `Bearer ${paystackSecretKey}` }
              }
            );
            const transactionsData = await transactionsResponse.json();
            
            if (transactionsData.status && transactionsData.data) {
              for (const txn of transactionsData.data) {
                if (!invoices.find(i => i.externalId === txn.reference)) {
                  invoices.push({
                    id: `paystack_${txn.id}`,
                    amount: txn.amount / 100,
                    currency: txn.currency || 'NGN',
                    status: txn.status === 'success' ? 'paid' : txn.status,
                    provider: 'paystack',
                    description: txn.metadata?.description || 'Paystack payment',
                    createdAt: txn.created_at || new Date().toISOString(),
                    paidAt: txn.paid_at,
                    externalId: txn.reference,
                    tier: txn.metadata?.tier,
                  });
                }
              }
            }
          }
        } catch (paystackError) {
          console.error('Error fetching Paystack invoices:', paystackError);
        }
      }
      
      // Sort by date descending
      invoices.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
      
      res.json({ success: true, invoices });
      
    } catch (error) {
      console.error('Get invoices error:', error);
      res.status(500).json({ error: error.message });
    }
  });

/**
 * Record Invoice After Payment
 * Called by webhook or after successful payment verification
 */
exports.recordInvoice = functions
  .runWith({
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
      
      const { 
        userId, 
        amount, 
        currency, 
        provider, 
        subscriptionId, 
        externalId, 
        tier,
        description,
        receiptUrl
      } = req.body;
      
      const invoiceRef = db.collection('invoices').doc();
      await invoiceRef.set({
        id: invoiceRef.id,
        userId: userId || decodedToken.uid,
        amount,
        currency: currency || 'USD',
        status: 'paid',
        provider,
        subscriptionId,
        externalId,
        tier,
        description: description || `${tier ? tier.charAt(0).toUpperCase() + tier.slice(1) : ''} Plan Subscription`,
        receiptUrl,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      res.json({ success: true, invoiceId: invoiceRef.id });
      
    } catch (error) {
      console.error('Record invoice error:', error);
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

// ============================================================================
// DEPLOYMENT CONFIRMATION EMAIL FUNCTIONS
// ============================================================================

/**
 * Send Deployment Confirmation Email
 *
 * Sends an email to the owner requesting confirmation before a deployment
 * proceeds to the live domains. The deployment is recorded in Firestore
 * with a unique request ID and must be explicitly approved before the
 * deploy script will continue.
 *
 * Workflow:
 *   1. Deploy script calls this function with deployment details
 *   2. Email is sent to the owner with approve/reject links
 *   3. Owner clicks approve or reject in the email
 *   4. Deploy script polls checkDeploymentStatus until status is resolved
 *
 * Setup:
 *   firebase functions:secrets:set SMTP_HOST
 *   firebase functions:secrets:set SMTP_PORT
 *   firebase functions:secrets:set SMTP_USER
 *   firebase functions:secrets:set SMTP_PASS
 *   firebase functions:secrets:set DEPLOY_NOTIFY_EMAIL
 *
 *   OR use Gmail:
 *   firebase functions:secrets:set GMAIL_USER
 *   firebase functions:secrets:set GMAIL_APP_PASSWORD
 */

const DEPLOYMENT_OWNER_EMAIL = process.env.DEPLOY_NOTIFY_EMAIL || 'chungu424@gmail.com';

/**
 * Create a nodemailer transport using environment configuration
 */
function createEmailTransport() {
  // Gmail configuration (preferred)
  if (process.env.GMAIL_USER && process.env.GMAIL_APP_PASSWORD) {
    return nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.GMAIL_USER,
        pass: process.env.GMAIL_APP_PASSWORD,
      },
    });
  }

  // Custom SMTP configuration
  if (process.env.SMTP_HOST && process.env.SMTP_USER) {
    return nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: parseInt(process.env.SMTP_PORT || '587', 10),
      secure: parseInt(process.env.SMTP_PORT || '587', 10) === 465,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });
  }

  // Fallback: use Ethereal Email (test account) for development
  console.warn('No email credentials configured. Using Ethereal test account.');
  return null;
}

/**
 * HTTP Callable: Send deployment confirmation email
 *
 * Body:
 *   - target: string (e.g., "staging", "admin", "both")
 *   - commitHash: string
 *   - commitMessage: string
 *   - branch: string
 *   - deployedBy: string (who/what initiated)
 *   - domains: string[] (list of domains being deployed to)
 *   - changesSummary: string (brief description of what changed)
 */
exports.sendDeploymentConfirmation = functions
  .runWith({
    secrets: ['GMAIL_USER', 'GMAIL_APP_PASSWORD', 'SMTP_HOST', 'SMTP_PORT', 'SMTP_USER', 'SMTP_PASS'],
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
      res.status(405).json({ error: 'Method not allowed. Use POST.' });
      return;
    }

    try {
      const {
        target = 'unknown',
        commitHash = 'unknown',
        commitMessage = 'No commit message',
        branch = 'main',
        deployedBy = 'automated',
        domains = [],
        changesSummary = 'No summary provided',
      } = req.body || {};

      // Generate a unique deployment request ID
      const requestId = `deploy_${Date.now()}_${Math.random().toString(36).substring(2, 10)}`;

      // Create the deployment request in Firestore
      const deployRef = db.collection('deployment_requests').doc(requestId);
      await deployRef.set({
        id: requestId,
        status: 'pending', // pending | approved | rejected | expired
        target,
        commitHash,
        commitMessage,
        branch,
        deployedBy,
        domains,
        changesSummary,
        ownerEmail: DEPLOYMENT_OWNER_EMAIL,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 30 * 60 * 1000) // 30 min expiry
        ),
      });

      // Build the email
      const transporter = createEmailTransport();

      if (!transporter) {
        // No email configured - auto-approve for development
        console.warn('No email transport available. Auto-approving deployment request.');
        await deployRef.update({
          status: 'approved',
          approvedAt: admin.firestore.FieldValue.serverTimestamp(),
          approvedBy: 'auto (no email config)',
        });
        res.json({
          success: true,
          requestId,
          status: 'approved',
          message: 'No email configuration found. Deployment auto-approved for development.',
        });
        return;
      }

      const functionRegion = process.env.FUNCTION_REGION || process.env.FUNCTION_TARGET || 'us-central1';
      const projectId = process.env.GCLOUD_PROJECT || 'ndu-d3f60';
      const baseUrl = `https://${functionRegion}-${projectId}.cloudfunctions.net`;

      const approveUrl = `${baseUrl}/handleDeploymentAction?action=approve&requestId=${requestId}`;
      const rejectUrl = `${baseUrl}/handleDeploymentAction?action=reject&requestId=${requestId}`;

      const domainsList = domains.length > 0
        ? domains.map(d => `<li><code>${d}</code></li>`).join('')
        : '<li><code>staging.nduproject.com</code></li><li><code>admin.nduproject.com</code></li>';

      const htmlBody = `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f172a; color: #e2e8f0; margin: 0; padding: 20px; }
    .container { max-width: 600px; margin: 0 auto; background: #1e293b; border-radius: 12px; overflow: hidden; border: 1px solid #334155; }
    .header { background: linear-gradient(135deg, #3b82f6, #8b5cf6); padding: 24px; text-align: center; }
    .header h1 { margin: 0; color: white; font-size: 22px; }
    .header p { margin: 8px 0 0; color: rgba(255,255,255,0.8); font-size: 14px; }
    .content { padding: 24px; }
    .detail-row { display: flex; padding: 8px 0; border-bottom: 1px solid #334155; }
    .detail-label { width: 140px; font-weight: 600; color: #94a3b8; font-size: 13px; }
    .detail-value { flex: 1; font-size: 14px; color: #e2e8f0; }
    .detail-value code { background: #0f172a; padding: 2px 6px; border-radius: 4px; font-size: 13px; }
    .summary { background: #0f172a; border-radius: 8px; padding: 16px; margin: 16px 0; border-left: 3px solid #3b82f6; }
    .summary p { margin: 0; font-size: 14px; line-height: 1.6; }
    .actions { display: flex; gap: 12px; margin: 24px 0; }
    .btn { display: inline-block; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 15px; text-align: center; flex: 1; }
    .btn-approve { background: #22c55e; color: white; }
    .btn-reject { background: #ef4444; color: white; }
    .footer { padding: 16px 24px; text-align: center; color: #64748b; font-size: 12px; border-top: 1px solid #334155; }
    .warning { background: #422006; border: 1px solid #f59e0b; border-radius: 8px; padding: 12px; margin: 16px 0; }
    .warning p { margin: 0; color: #fbbf24; font-size: 13px; }
    ul { padding-left: 20px; }
    li { margin: 4px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>NDU Project Deployment Request</h1>
      <p>Confirmation required before deploying to production</p>
    </div>
    <div class="content">
      <div class="warning">
        <p>A deployment is pending your approval. This will push changes to the live domains listed below. Please review carefully before approving.</p>
      </div>

      <div class="detail-row">
        <div class="detail-label">Request ID</div>
        <div class="detail-value"><code>${requestId}</code></div>
      </div>
      <div class="detail-row">
        <div class="detail-label">Target</div>
        <div class="detail-value"><strong>${target.toUpperCase()}</strong></div>
      </div>
      <div class="detail-row">
        <div class="detail-label">Branch</div>
        <div class="detail-value"><code>${branch}</code></div>
      </div>
      <div class="detail-row">
        <div class="detail-label">Commit</div>
        <div class="detail-value"><code>${commitHash.substring(0, 12)}</code></div>
      </div>
      <div class="detail-row">
        <div class="detail-label">Initiated By</div>
        <div class="detail-value">${deployedBy}</div>
      </div>
      <div class="detail-row">
        <div class="detail-label">Domains</div>
        <div class="detail-value">
          <ul>${domainsList}</ul>
        </div>
      </div>

      <div class="summary">
        <p><strong>Commit Message:</strong><br>${commitMessage}</p>
      </div>
      <div class="summary">
        <p><strong>Changes Summary:</strong><br>${changesSummary}</p>
      </div>

      <div class="actions">
        <a href="${approveUrl}" class="btn btn-approve">Approve Deployment</a>
        <a href="${rejectUrl}" class="btn btn-reject">Reject Deployment</a>
      </div>
    </div>
    <div class="footer">
      <p>NDU Project Deployment System &bull; This request expires in 30 minutes</p>
      <p>If you did not initiate this deployment, please reject it immediately.</p>
    </div>
  </div>
</body>
</html>`;

      const textBody = `
NDU PROJECT DEPLOYMENT REQUEST
==============================

A deployment is pending your approval.

Request ID: ${requestId}
Target: ${target.toUpperCase()}
Branch: ${branch}
Commit: ${commitHash.substring(0, 12)}
Initiated By: ${deployedBy}
Domains: ${domains.join(', ') || 'staging.nduproject.com, admin.nduproject.com'}

Commit Message: ${commitMessage}

Changes Summary: ${changesSummary}

APPROVE: ${approveUrl}
REJECT: ${rejectUrl}

This request expires in 30 minutes.
If you did not initiate this deployment, please reject it immediately.
`;

      // Send the email
      const mailResult = await transporter.sendMail({
        from: `"NDU Deploy" <${process.env.GMAIL_USER || process.env.SMTP_USER || 'noreply@nduproject.com'}>`,
        to: DEPLOYMENT_OWNER_EMAIL,
        subject: `[NDU Deploy] Deployment Confirmation Required - ${target.toUpperCase()} - ${commitHash.substring(0, 8)}`,
        html: htmlBody,
        text: textBody,
      });

      console.log('Deployment confirmation email sent:', mailResult.messageId);

      res.json({
        success: true,
        requestId,
        status: 'pending',
        message: `Confirmation email sent to ${DEPLOYMENT_OWNER_EMAIL}. Waiting for approval.`,
        messageId: mailResult.messageId,
      });

    } catch (error) {
      console.error('Failed to send deployment confirmation email:', error);
      res.status(500).json({
        error: 'Failed to send confirmation email',
        message: error.message,
      });
    }
  });

/**
 * HTTP Callable: Handle deployment action (approve/reject)
 *
 * This is called via email links. It updates the Firestore document
 * and shows a confirmation page to the user.
 */
exports.handleDeploymentAction = functions
  .runWith({
    timeoutSeconds: 15,
    memory: '128MB'
  })
  .https.onRequest(async (req, res) => {
    const { action, requestId } = req.query;

    if (!action || !requestId) {
      res.status(400).send('Missing action or requestId parameters.');
      return;
    }

    if (!['approve', 'reject'].includes(action)) {
      res.status(400).send('Invalid action. Must be "approve" or "reject".');
      return;
    }

    try {
      const deployDoc = await db.collection('deployment_requests').doc(requestId).get();

      if (!deployDoc.exists) {
        res.status(404).send(`
          <html><body style="font-family:sans-serif;text-align:center;padding:40px;background:#0f172a;color:#e2e8f0;">
            <h1 style="color:#ef4444;">Deployment Request Not Found</h1>
            <p>This deployment request may have expired or does not exist.</p>
          </body></html>
        `);
        return;
      }

      const deployData = deployDoc.data();

      if (deployData.status !== 'pending') {
        const statusColor = deployData.status === 'approved' ? '#22c55e' : '#ef4444';
        res.status(200).send(`
          <html><body style="font-family:sans-serif;text-align:center;padding:40px;background:#0f172a;color:#e2e8f0;">
            <h1 style="color:${statusColor};">Already ${deployData.status.toUpperCase()}</h1>
            <p>This deployment request was already ${deployData.status}.</p>
            <p>Request ID: ${requestId}</p>
          </body></html>
        `);
        return;
      }

      // Check expiry
      const now = new Date();
      const expiresAt = deployData.expiresAt?.toDate ? deployData.expiresAt.toDate() : new Date(0);
      if (now > expiresAt) {
        await deployDoc.ref.update({
          status: 'expired',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        res.status(200).send(`
          <html><body style="font-family:sans-serif;text-align:center;padding:40px;background:#0f172a;color:#e2e8f0;">
            <h1 style="color:#f59e0b;">Request Expired</h1>
            <p>This deployment request has expired (30 minute window).</p>
            <p>Please initiate a new deployment.</p>
          </body></html>
        `);
        return;
      }

      // Update the status
      const newStatus = action === 'approve' ? 'approved' : 'rejected';
      await deployDoc.ref.update({
        status: newStatus,
        [action === 'approve' ? 'approvedAt' : 'rejectedAt']: admin.firestore.FieldValue.serverTimestamp(),
        [action === 'approve' ? 'approvedBy' : 'rejectedBy']: 'owner',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const color = action === 'approve' ? '#22c55e' : '#ef4444';
      const icon = action === 'approve' ? '&#10004;' : '&#10008;';
      const message = action === 'approve'
        ? 'The deployment will now proceed to the live domains.'
        : 'The deployment has been cancelled and will NOT proceed.';

      res.status(200).send(`
        <html><body style="font-family:sans-serif;text-align:center;padding:40px;background:#0f172a;color:#e2e8f0;">
          <div style="max-width:500px;margin:0 auto;background:#1e293b;border-radius:12px;padding:32px;border:1px solid #334155;">
            <div style="font-size:48px;color:${color};">${icon}</div>
            <h1 style="color:${color};">Deployment ${newStatus.toUpperCase()}</h1>
            <p>${message}</p>
            <div style="text-align:left;background:#0f172a;border-radius:8px;padding:16px;margin:16px 0;">
              <p style="margin:4px 0;color:#94a3b8;font-size:13px;">Request ID: <code style="color:#e2e8f0;">${requestId}</code></p>
              <p style="margin:4px 0;color:#94a3b8;font-size:13px;">Target: <strong style="color:#e2e8f0;">${deployData.target?.toUpperCase() || 'N/A'}</strong></p>
              <p style="margin:4px 0;color:#94a3b8;font-size:13px;">Commit: <code style="color:#e2e8f0;">${(deployData.commitHash || '').substring(0, 12)}</code></p>
              <p style="margin:4px 0;color:#94a3b8;font-size:13px;">Branch: <code style="color:#e2e8f0;">${deployData.branch || 'N/A'}</code></p>
            </div>
          </div>
        </body></html>
      `);

    } catch (error) {
      console.error('Error handling deployment action:', error);
      res.status(500).send('Internal server error');
    }
  });

/**
 * HTTP Callable: Check deployment status
 *
 * Called by the deploy script to poll whether the owner has approved
 * or rejected a deployment request.
 *
 * Query params:
 *   - requestId: string
 */
exports.checkDeploymentStatus = functions
  .runWith({
    timeoutSeconds: 10,
    memory: '128MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    if (req.method !== 'GET' && req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    const requestId = req.query.requestId || req.body?.requestId;

    if (!requestId) {
      res.status(400).json({ error: 'Missing requestId parameter' });
      return;
    }

    try {
      const deployDoc = await db.collection('deployment_requests').doc(requestId).get();

      if (!deployDoc.exists) {
        res.status(404).json({ error: 'Deployment request not found', status: 'not_found' });
        return;
      }

      const data = deployDoc.data();

      // Check expiry and auto-expire if needed
      const now = new Date();
      const expiresAt = data.expiresAt?.toDate ? data.expiresAt.toDate() : new Date(0);
      if (data.status === 'pending' && now > expiresAt) {
        await deployDoc.ref.update({
          status: 'expired',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        res.json({
          status: 'expired',
          requestId: data.id,
          message: 'Deployment request has expired. Please initiate a new one.',
        });
        return;
      }

      res.json({
        status: data.status,
        requestId: data.id,
        target: data.target,
        commitHash: data.commitHash,
        branch: data.branch,
        approvedBy: data.approvedBy || null,
        rejectedBy: data.rejectedBy || null,
        createdAt: data.createdAt?.toDate ? data.createdAt.toDate().toISOString() : null,
        approvedAt: data.approvedAt?.toDate ? data.approvedAt.toDate().toISOString() : null,
        rejectedAt: data.rejectedAt?.toDate ? data.rejectedAt.toDate().toISOString() : null,
      });

    } catch (error) {
      console.error('Error checking deployment status:', error);
      res.status(500).json({ error: 'Failed to check deployment status', message: error.message });
    }
  });
