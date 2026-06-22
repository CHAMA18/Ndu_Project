// =============================================================================
// NDU Project — Runtime Environment Configuration (root deployment)
// =============================================================================
// See web/env-config.js for full documentation. This is the same file, placed
// at the repo root so that deployments serving from "/" (instead of a
// sub-path) pick it up correctly.
// =============================================================================

window.__NDU_ENV = window.__NDU_ENV || {};

// Anthropic Claude API key — OPTIONAL. Leave empty to use the Cloud Function
// proxy (recommended for production so the key stays server-side).
window.__NDU_ENV.ANTHROPIC_API_KEY = '';

// Firebase web API key — OPTIONAL. Leave empty to use the value compiled into
// firebase_options.dart.
window.__NDU_ENV.FIREBASE_API_KEY = '';

// Deployment build stamp — written by scripts/stamp_build_version.py.
window.__NDU_ENV.BUILD_STAMP = 'NDU_BUILD_STAMP';
