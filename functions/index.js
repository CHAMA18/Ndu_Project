const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const crypto = require('crypto');
const { Resend } = require('resend');

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
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-api-key, x-anthropic-api-key, anthropic-version');
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
      const requestPayload = stripInvalidModelParams(stripWorkflowFields(req.body.payload || req.body));
      const model = (requestPayload.model || '').toLowerCase();

      // ── Anthropic (Claude) routing ──────────────────────────────────
      if (model.startsWith('claude')) {
        // Check for client-provided API key first (from Settings > Integrations)
        let anthropicApiKey = req.headers['x-anthropic-api-key'] ||
          req.headers['x-api-key'] || '';

        // If no client key, try Firebase secret
        if (!anthropicApiKey) {
          anthropicApiKey = process.env.ANTHROPIC_API_KEY;
        }

        // Fallback: try to read the key from Firestore (settings/ai_config)
        if (!anthropicApiKey) {
          try {
            const configDoc = await db.collection('settings').doc('ai_config').get();
            anthropicApiKey = configDoc.data()?.anthropicApiKey || '';
          } catch (e) {
            console.warn('Failed to read Anthropic key from Firestore:', e.message);
          }
        }

        if (!anthropicApiKey) {
          console.error('ANTHROPIC_API_KEY not configured (neither client header, secret, nor Firestore)');
          res.status(500).json({ error: 'Anthropic service not configured. Add your API key in Settings > Integrations.' });
          return;
        }

        // Convert OpenAI-format request to Anthropic Messages API format
        const openaiMessages = requestPayload.messages || [];
        let systemPrompt = '';
        const anthropicMessages = [];

        for (const msg of openaiMessages) {
          if (msg.role === 'system') {
            // Anthropic uses a top-level `system` field
            const content = typeof msg.content === 'string'
              ? msg.content
              : Array.isArray(msg.content)
                ? msg.content.map(c => c.text || '').join('\n')
                : '';
            systemPrompt = content;
          } else {
            // user / assistant messages
            let text = '';
            if (typeof msg.content === 'string') {
              text = msg.content;
            } else if (Array.isArray(msg.content)) {
              text = msg.content.map(c => {
                if (c.type === 'text' || c.type === 'input_text') return c.text || '';
                return '';
              }).join('\n');
            }
            anthropicMessages.push({ role: msg.role, content: text });
          }
        }

        const anthropicPayload = {
          model: requestPayload.model,
          max_tokens: requestPayload.max_completion_tokens || requestPayload.max_tokens || 1024,
          messages: anthropicMessages,
        };
        if (systemPrompt) anthropicPayload.system = systemPrompt;
        if (requestPayload.temperature != null) anthropicPayload.temperature = requestPayload.temperature;
        if (requestPayload.response_format) {
          // Anthropic doesn't use response_format the same way,
          // but we can instruct via system prompt
          if (requestPayload.response_format.type === 'json_object') {
            anthropicPayload.system = (anthropicPayload.system || '') +
              '\n\nIMPORTANT: You MUST return only valid JSON matching the requested schema. Do not include any text outside the JSON object.';
          }
        }

        console.log(`Proxying to Anthropic API: model=${requestPayload.model}, messages=${anthropicMessages.length}`);

        const anthropicResponse = await fetch('https://api.anthropic.com/v1/messages', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': anthropicApiKey,
            'anthropic-version': '2023-06-01',
            'anthropic-dangerous-direct-browser-access': 'true'
          },
          body: JSON.stringify(anthropicPayload)
        });

        const anthropicData = await anthropicResponse.json();

        if (!anthropicResponse.ok) {
          console.error('Anthropic API error:', JSON.stringify(anthropicData));
          res.status(anthropicResponse.status).json(anthropicData);
          return;
        }

        // Convert Anthropic response back to OpenAI Chat Completions format
        // so the client parsing logic continues to work unchanged
        const textContent = (anthropicData.content || [])
          .filter(block => block.type === 'text')
          .map(block => block.text)
          .join('');

        const openaiCompatResponse = {
          id: anthropicData.id || `chatcmpl-anthropic-${Date.now()}`,
          object: 'chat.completion',
          model: anthropicData.model || requestPayload.model,
          choices: [{
            index: 0,
            message: {
              role: 'assistant',
              content: textContent
            },
            finish_reason: anthropicData.stop_reason === 'end_turn' ? 'stop' : (anthropicData.stop_reason || 'stop')
          }],
          usage: {
            prompt_tokens: anthropicData.usage?.input_tokens || 0,
            completion_tokens: anthropicData.usage?.output_tokens || 0,
            total_tokens: (anthropicData.usage?.input_tokens || 0) + (anthropicData.usage?.output_tokens || 0)
          }
        };

        res.status(200).json(openaiCompatResponse);
        return;
      }

      // ── OpenAI routing (default) ────────────────────────────────────
      const apiKey = process.env.OPENAI_API_KEY;
      if (!apiKey) {
        console.error('OPENAI_API_KEY secret not configured');
        res.status(500).json({ error: 'Service configuration error' });
        return;
      }

      const workflowId = getConfiguredOpenAiWorkflowId(req);

      // Determine endpoint path from request payload
      let endpoint = req.body.endpoint;
      if (!endpoint) {
        if (req.body && (typeof req.body === 'object') && ('input' in req.body)) {
          endpoint = '/responses';
        } else {
          endpoint = '/chat/completions';
        }
      }
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
// EMAIL INVITATION FUNCTIONS
// ============================================================================

/**
 * Send Invitation Email — Firestore Trigger
 *
 * Fires when a new document is created in the collaboration_invites collection.
 * Sends a professional invitation email via Resend and updates the document status.
 *
 * Setup: firebase functions:secrets:set RESEND_API_KEY
 */
exports.sendInvitationEmail = functions
  .runWith({
    secrets: ['RESEND_API_KEY'],
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .firestore.document('collaboration_invites/{inviteId}')
  .onCreate(async (snap, context) => {
    const inviteData = snap.data();

    // Skip if status is not 'pending' (avoid re-sending)
    if (inviteData.status !== 'pending') {
      console.log(`Skipping invite ${context.params.inviteId}: status is '${inviteData.status}', not 'pending'`);
      return null;
    }

    try {
      // Generate a secure invite token
      const inviteToken = crypto.randomUUID();

      // Build the acceptance URL
      const acceptanceUrl = `https://ndu-d3f60.web.app/invite?token=${inviteToken}`;

      // Create the Resend instance
      const resend = new Resend(process.env.RESEND_API_KEY);

      const projectName = inviteData.projectName || 'a project';
      const invitedByEmail = inviteData.invitedByEmail || 'A project member';
      const siteRole = inviteData.siteRole || 'collaborator';
      const personalMessage = inviteData.personalMessage || inviteData.message || '';

      // Build the personal message section
      const personalMessageSection = personalMessage
        ? `
        <tr>
          <td style="padding: 16px 24px; background: #0f172a; border-radius: 8px; margin-top: 8px;">
            <p style="margin: 0; color: #94a3b8; font-size: 14px; font-style: italic;">Personal message:</p>
            <p style="margin: 8px 0 0; color: #e2e8f0; font-size: 15px; line-height: 1.6;">${personalMessage}</p>
          </td>
        </tr>
        `
        : '';

      // Professional dark-themed HTML email matching NDU Project design system
      const htmlBody = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>You're invited to collaborate on ${projectName}</title>
</head>
<body style="margin: 0; padding: 0; background: #0f172a; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;">

  <!-- Header -->
  <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background: #0f172a;">
    <tr>
      <td align="center" style="padding: 40px 24px 0;">
        <table width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width: 560px;">
          <tr>
            <td style="text-align: center;">
              <h1 style="margin: 0; font-size: 28px; font-weight: 700; color: #e2e8f0; letter-spacing: -0.5px;">
                NDU <span style="color: #3b82f6;">Project</span>
              </h1>
              <div style="width: 48px; height: 3px; background: #3b82f6; border-radius: 2px; margin: 16px auto 0;"></div>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>

  <!-- Main Card -->
  <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background: #0f172a;">
    <tr>
      <td align="center" style="padding: 32px 24px;">
        <table width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width: 560px; background: #1e293b; border-radius: 16px; border: 1px solid #334155; overflow: hidden;">

          <!-- Invite Content -->
          <tr>
            <td style="padding: 40px 32px 24px;">
              <h2 style="margin: 0 0 8px; font-size: 22px; font-weight: 600; color: #e2e8f0;">
                You're Invited to Collaborate
              </h2>
              <p style="margin: 0 0 24px; font-size: 15px; color: #94a3b8; line-height: 1.6;">
                <strong style="color: #e2e8f0;">${invitedByEmail}</strong> has invited you to join their project on NDU Project.
              </p>

              <!-- Project & Role Details -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-bottom: 24px;">
                <tr>
                  <td style="padding: 16px 24px; background: #0f172a; border-radius: 8px 8px 0 0; border-bottom: 1px solid #1e293b;">
                    <p style="margin: 0; color: #94a3b8; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px;">Project</p>
                    <p style="margin: 4px 0 0; color: #e2e8f0; font-size: 16px; font-weight: 600;">${projectName}</p>
                  </td>
                </tr>
                <tr>
                  <td style="padding: 16px 24px; background: #0f172a; border-radius: 0 0 8px 8px;">
                    <p style="margin: 0; color: #94a3b8; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px;">Role</p>
                    <p style="margin: 4px 0 0; color: #3b82f6; font-size: 16px; font-weight: 600;">${siteRole}</p>
                  </td>
                </tr>
              </table>

              <!-- Personal Message -->
              ${personalMessageSection}

              <!-- CTA Button -->
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-top: 32px;">
                <tr>
                  <td align="center">
                    <a href="${acceptanceUrl}" target="_blank" style="display: inline-block; padding: 14px 40px; background: #3b82f6; color: #ffffff; font-size: 16px; font-weight: 600; text-decoration: none; border-radius: 10px; letter-spacing: 0.3px;">
                      Accept Invitation
                    </a>
                  </td>
                </tr>
                <tr>
                  <td align="center" style="padding-top: 16px;">
                    <p style="margin: 0; font-size: 13px; color: #64748b; line-height: 1.5;">
                      If the button above doesn't work, copy and paste this link into your browser:
                    </p>
                    <p style="margin: 4px 0 0; font-size: 13px;">
                      <a href="${acceptanceUrl}" target="_blank" style="color: #3b82f6; word-break: break-all;">${acceptanceUrl}</a>
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Expiry Notice -->
          <tr>
            <td style="padding: 0 32px 24px;">
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background: #0f172a; border-radius: 8px;">
                <tr>
                  <td style="padding: 12px 16px;">
                    <p style="margin: 0; font-size: 13px; color: #94a3b8; line-height: 1.5;">
                      ⏳ <strong style="color: #e2e8f0;">This invitation will expire.</strong> Please accept it promptly to gain access to the project.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

  <!-- Footer -->
  <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background: #0f172a;">
    <tr>
      <td align="center" style="padding: 24px 24px 40px;">
        <table width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width: 560px;">
          <tr>
            <td style="text-align: center; border-top: 1px solid #1e293b; padding-top: 24px;">
              <p style="margin: 0; font-size: 13px; color: #475569;">
                Sent by NDU Project &mdash; Collaborative project management
              </p>
              <p style="margin: 8px 0 0; font-size: 12px; color: #334155;">
                If you weren't expecting this invitation, you can safely ignore this email.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>

</body>
</html>`;

      // Send the email
      // NOTE: onboarding@resend.dev can ONLY send to the email registered on
      // the Resend account. For production, verify a custom domain and update
      // the 'from' address below.
      const fromAddress = process.env.RESEND_FROM_ADDRESS || 'onboarding@resend.dev';
      console.log(`Sending invitation email from=${fromAddress} to=${inviteData.email} project=${projectName}`);

      const { data: sendData, error: sendError } = await resend.emails.send({
        from: fromAddress,
        to: inviteData.email,
        subject: `You're invited to collaborate on ${projectName} — NDU Project`,
        html: htmlBody,
      });

      if (sendError) {
        console.error('Resend API error details:', JSON.stringify(sendError));
        // Provide a helpful message for the common onboarding@resend.dev restriction
        const errorMsg = sendError.message || 'Resend API returned an error';
        if (errorMsg.includes('not allowed') || errorMsg.includes('not verified') || errorMsg.includes('restricted')) {
          throw new Error(
            `Cannot send to ${inviteData.email}: The onboarding@resend.dev sender can only ` +
            `deliver to the email address registered on your Resend account. ` +
            `To send to other addresses, verify a custom domain in Resend and set ` +
            `RESEND_FROM_ADDRESS secret. Original error: ${errorMsg}`
          );
        }
        throw new Error(errorMsg);
      }

      console.log(`Resend email ID: ${sendData?.id || 'unknown'}`);

      // Update the invite document with success status
      await snap.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        inviteToken: inviteToken,
      });

      console.log(`Invitation email sent successfully to ${inviteData.email} for project ${projectName} (invite: ${context.params.inviteId})`);

      return null;

    } catch (error) {
      console.error(`Failed to send invitation email for invite ${context.params.inviteId}:`, error);

      // Update the invite document with failure status
      try {
        await snap.ref.update({
          status: 'failed',
          errorMessage: error.message,
        });
      } catch (updateError) {
        console.error(`Also failed to update invite status for ${context.params.inviteId}:`, updateError);
      }

      return null;
    }
  });

/**
 * Accept Invitation — HTTPS Request Function
 *
 * Handles invitation acceptance via GET (email link clicks) and POST (API calls).
 * On GET: validates the token and redirects or shows an error page.
 * On POST: creates the role assignment and marks the invite as accepted.
 *
 * Setup: firebase functions:secrets:set RESEND_API_KEY
 */
exports.acceptInvitation = functions
  .runWith({
    secrets: ['RESEND_API_KEY'],
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);

    // Handle preflight requests
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    // ── Helper: return a dark-themed HTML error/info page ──────────────
    function renderHtmlPage(title, message, isError = true) {
      const accentColor = isError ? '#ef4444' : '#3b82f6';
      const icon = isError ? '✕' : '✓';
      return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #0f172a; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; min-height: 100vh; display: flex; align-items: center; justify-content: center; }
    .card { background: #1e293b; border-radius: 16px; border: 1px solid #334155; padding: 48px 40px; max-width: 460px; width: 90%; text-align: center; }
    .icon { width: 64px; height: 64px; border-radius: 50%; background: ${accentColor}20; color: ${accentColor}; font-size: 28px; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px; }
    h1 { color: #e2e8f0; font-size: 22px; font-weight: 600; margin-bottom: 12px; }
    p { color: #94a3b8; font-size: 15px; line-height: 1.6; }
    a { color: #3b82f6; text-decoration: none; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">${icon}</div>
    <h1>${title}</h1>
    <p>${message}</p>
  </div>
</body>
</html>`;
    }

    // ── GET: Email link click ──────────────────────────────────────────
    if (req.method === 'GET') {
      try {
        const token = req.query.token;

        if (!token) {
          res.status(400).send(renderHtmlPage('Missing Token', 'No invitation token was provided. Please check your invitation link and try again.'));
          return;
        }

        // Look up the invite document by inviteToken field
        const inviteSnapshot = await db.collection('collaboration_invites')
          .where('inviteToken', '==', token)
          .limit(1)
          .get();

        if (inviteSnapshot.empty) {
          res.status(404).send(renderHtmlPage('Invitation Not Found', 'We couldn\'t find an invitation matching this token. It may have been revoked or the link may be incorrect.'));
          return;
        }

        const inviteDoc = inviteSnapshot.docs[0];
        const invite = inviteDoc.data();

        // Check if already accepted
        if (invite.status === 'accepted') {
          res.status(200).send(renderHtmlPage('Already Accepted', 'This invitation has already been accepted. You can sign in to access the project.', false));
          return;
        }

        // Check if expired
        if (invite.expiresAt) {
          const expiresAt = invite.expiresAt.toDate ? invite.expiresAt.toDate() : new Date(invite.expiresAt);
          if (expiresAt < new Date()) {
            res.status(410).send(renderHtmlPage('Invitation Expired', 'This invitation has expired. Please request a new invitation from the project owner.'));
            return;
          }
        }

        // Check if failed or revoked
        if (invite.status === 'failed' || invite.status === 'revoked') {
          res.status(410).send(renderHtmlPage('Invitation Unavailable', `This invitation is no longer valid (status: ${invite.status}). Please contact the project owner.`));
          return;
        }

        // Valid invitation — redirect to Flutter app
        res.redirect(302, `https://ndu-d3f60.web.app/invite?token=${token}&status=valid`);

      } catch (error) {
        console.error('Accept invitation GET error:', error);
        res.status(500).send(renderHtmlPage('Server Error', 'Something went wrong while processing your invitation. Please try again later.'));
      }
      return;
    }

    // ── POST: API call to accept the invitation ───────────────────────
    if (req.method === 'POST') {
      try {
        const { token, uid } = req.body;

        if (!token) {
          res.status(400).json({ error: 'Missing required field: token' });
          return;
        }

        // Look up the invite by token
        const inviteSnapshot = await db.collection('collaboration_invites')
          .where('inviteToken', '==', token)
          .limit(1)
          .get();

        if (inviteSnapshot.empty) {
          res.status(404).json({ error: 'Invitation not found' });
          return;
        }

        const inviteDoc = inviteSnapshot.docs[0];
        const invite = inviteDoc.data();

        // Validate it's still pending/valid
        if (invite.status === 'accepted') {
          res.status(409).json({ error: 'Invitation has already been accepted' });
          return;
        }

        if (invite.status === 'revoked') {
          res.status(410).json({ error: 'Invitation has been revoked' });
          return;
        }

        // Check expiry
        if (invite.expiresAt) {
          const expiresAt = invite.expiresAt.toDate ? invite.expiresAt.toDate() : new Date(invite.expiresAt);
          if (expiresAt < new Date()) {
            res.status(410).json({ error: 'Invitation has expired' });
            return;
          }
        }

        if (invite.status !== 'sent' && invite.status !== 'pending') {
          res.status(400).json({ error: `Invitation is not in an acceptable state (status: ${invite.status})` });
          return;
        }

        // Create a user_roles document with the role assignment
        const userRoleRef = db.collection('user_roles').doc();
        await userRoleRef.set({
          uid: uid || '',
          email: invite.email,
          siteRole: invite.siteRole,
          resourceAccessLevel: invite.resourceAccessLevel || null,
          scope: invite.scope || null,
          projectId: invite.projectId || null,
          customPermissions: invite.customPermissions || [],
          assignedBy: invite.invitedByUid || null,
          assignedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update the invite as accepted
        await inviteDoc.ref.update({
          status: 'accepted',
          acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
          acceptedByUid: uid || null,
        });

        // Create an audit event in rbac_audit_events
        const auditRef = db.collection('rbac_audit_events').doc();
        await auditRef.set({
          action: 'collaborator_accepted',
          actorUid: uid || null,
          actorEmail: invite.email,
          targetUid: uid || null,
          targetEmail: invite.email,
          resourceType: 'project',
          resourceId: invite.projectId || null,
          details: {
            inviteId: inviteDoc.id,
            siteRole: invite.siteRole,
            scope: invite.scope || null,
            resourceAccessLevel: invite.resourceAccessLevel || null,
            invitedByUid: invite.invitedByUid || null,
          },
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Invitation ${inviteDoc.id} accepted by ${uid || 'unknown'} for ${invite.email}`);

        res.json({ success: true });

      } catch (error) {
        console.error('Accept invitation POST error:', error);
        res.status(500).json({ error: 'Failed to accept invitation', message: error.message });
      }
      return;
    }

    // Other methods not allowed
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.status(405).json({ error: 'Method not allowed. Use GET or POST.' });
  });
