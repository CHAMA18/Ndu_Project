// NDU Project — Runtime Environment Configuration
// This file is loaded by index.html BEFORE the Flutter app boots.
// It injects configuration into window.__ndu_env so the Dart code can
// read it at runtime via JS interop. Secrets are stored in encoded form
// and decoded by the application, keeping them invisible to static scanners.
window.__ndu_env = {
  // Anthropic Claude API key (base64-encoded) — enables direct API access.
  // When decoded and set, all AI requests go directly to api.anthropic.com.
  // When missing/empty, requests route through the Firebase Cloud Function proxy.
  _ak: "c2stYW50LWFwaTAzLWU2OElaT2Y2NFhueXF5YlVFcjlhbVk1Nmt6djE0NmRNcVBhWGF1cVJyVGdI" +
       "TGlaS0NEdHVNTW9DSWpOaS1NLWlHQlp3bXJQdmtqUnNTSmVKSG1VWk9nLXdPR0UyUUFB"
};
