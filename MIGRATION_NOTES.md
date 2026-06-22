# NDU-Test → Ndu_Project Migration Notes

**Date:** June 2026
**Source repo:** https://github.com/CHAMA18/NDU-Test.git
**Target repo:** https://github.com/CHAMA18/Ndu_Project.git
**Version after migration:** `1.0.0+3` (build_number `3`)

---

## 1. What was migrated and why

The NDU-Test repository is the **compiled Flutter web build** (deployed to GitHub Pages), not a separate JavaScript codebase. Its `main.dart.js` is the dart2js output of the Ndu_Project Flutter app. Therefore "migrating changes from NDU-Test to Ndu_Project" means: **back-porting the deployment-layer and runtime-config improvements that were made directly in the NDU-Test deployment back into the Ndu_Project source**, so that future `flutter build web` outputs include them automatically.

A diff of NDU-Test vs Ndu_Project's `web/` source folder revealed four gaps:

| # | Gap | Impact |
|---|-----|--------|
| 1 | `web/env-config.js` was missing entirely | No way to inject API keys at deploy time without recompiling |
| 2 | `web/index.html` was the stock Flutter template | No loading spinner (white screen for ~2s), no cache prevention, no env-config loader |
| 3 | `web/flutter_service_worker.js` used the stock "unregister on every boot" pattern | PWA/offline support broken; service worker never caches anything |
| 4 | `version.json` build_number was `1` (NDU-Test had `2`) | Stale version reported to users |

A fifth, deeper gap was found by inspecting the Dart source: even if `env-config.js` existed, **no Dart code read `window.__NDU_ENV`**, so the env-config was dead weight. This migration adds the missing Dart-side loader and wires it into `ApiKeyManager`.

All other features referenced in NDU-Test's commit history (Claude/Anthropic AI, dark/light theming, Portfolio Metrics Dashboard, CSV import, voice/mic input, edit modals) were already present in the Ndu_Project source — confirmed by grepping `lib/`.

---

## 2. Files added

| File | Purpose |
|------|---------|
| `web/env-config.js` | Runtime environment config template — loaded by `index.html` before Flutter boots. Populates `window.__NDU_ENV` with `ANTHROPIC_API_KEY`, `FIREBASE_API_KEY`, `BUILD_STAMP`. |
| `web/flutter_service_worker.js` | Custom versioned service worker. Network-first with cache fallback (offline support), versioned `CACHE_NAME` for clean cache rotation, `skipWaiting` + `clients.claim` for instant activation. |
| `env-config.js` (repo root) | Same as `web/env-config.js`, for deployments that serve from repo root. |
| `docs/env-config.js` | Same, for GitHub Pages deployments served from `docs/`. |
| `lib/services/env_config_loader.dart` | Conditional-export interface for the EnvConfigLoader. Selects web vs stub impl based on `dart.library.html`. |
| `lib/services/env_config_loader_stub.dart` | Non-web stub — returns nulls so mobile/desktop code uses compile-time config. |
| `lib/services/env_config_loader_web.dart` | Web implementation — reads `window.__NDU_ENV` via `dart:js_interop` (works with dart2js AND dart2wasm). Includes key masking in debug logs. |
| `scripts/stamp_build_version.py` | Post-build version stamper. Replaces every `NDU_BUILD_STAMP` placeholder in `build/web/` with the current epoch seconds. |
| `scripts/build_web.sh` | Convenience wrapper: runs `flutter build web` then invokes the stamper. |
| `MIGRATION_NOTES.md` | This file. |

## 3. Files modified

| File | Change |
|------|--------|
| `web/index.html` | Rewrote with: cache-prevention meta tags, dark-themed loading spinner (`#0f172a` bg, blue spinner, NDU Project brand), `env-config.js` loader (runs before Flutter), inline aggressive cache-busting script (kills SWs, nukes caches, force-redirects with `?_ndu=<stamp>` param), `?v=NDU_BUILD_STAMP` on every asset URL. |
| `index.html` (repo root) | Same rewrite as `web/index.html` but with `base href="/"` for root-served deployments. |
| `docs/index.html` | Same rewrite for GitHub Pages (`docs/`) deployment. |
| `flutter_service_worker.js` (root) | Replaced stock "unregister on activate" pattern with the versioned-cache network-first SW. |
| `docs/flutter_service_worker.js` | Same. |
| `lib/main.dart` | Added `import env_config_loader.dart` + `import api_config_secure.dart`. Calls `await EnvConfigLoader.load()` before `ApiKeyManager.initializeApiKey()`. If env-config supplied an Anthropic key, it's set via `ApiKeyManager.setApiKey()`; otherwise the Cloud Function proxy is used (logged for diagnostics). |
| `pubspec.yaml` | Bumped `version: 1.0.0+2` → `1.0.0+3`. |
| `version.json` (root) | `build_number: "1"` → `"3"`. |
| `docs/version.json` | `build_number: "1"` → `"3"`. |

## 4. Files NOT modified (and why)

- `lib/services/api_key_manager.dart` — already has `setApiKey()`; the new `main.dart` flow calls it. No change needed.
- `lib/services/api_config_secure.dart` — already exposes `baseUrl` (Cloud Function proxy URL) and `model` (Claude Sonnet 4). No change needed.
- `lib/services/openai_service_secure.dart` — already wired to call the Cloud Function proxy. No change needed.
- `lib/theme.dart`, `lib/screens/settings_screen.dart` — dark/light theming already present.
- `lib/screens/portfolio_dashboard_screen.dart`, `lib/services/portfolio_service.dart`, `lib/models/portfolio_model.dart` — Portfolio dashboard already present.
- `lib/utils/csv_import_helper.dart`, `lib/widgets/csv_import_dialog.dart`, `lib/widgets/csv_table_import_button.dart` — CSV import already present.
- `lib/services/voice_input_service.dart`, `lib/widgets/voice_text_field.dart` — Voice input already present.
- Root-level `main.dart.js`, `flutter.js`, `flutter_bootstrap.js`, `canvaskit/`, `icons/` — these are binary build artifacts that can only be regenerated by running `flutter build web`. They will be refreshed the next time the project is built and deployed. See §7 below.

---

## 5. Architecture: how env-config flows end-to-end

```
┌─────────────────────────────────────────────────────────────────┐
│ DEPLOY TIME                                                      │
│                                                                  │
│  1. Operator fills in env-config.js with deploy-time secrets     │
│     (or leaves ANTHROPIC_API_KEY empty to use the proxy)         │
│                                                                  │
│  2. scripts/build_web.sh runs:                                   │
│       flutter build web                                          │
│       python scripts/stamp_build_version.py                      │
│         → replaces NDU_BUILD_STAMP → <epoch> in:                 │
│             build/web/index.html                                 │
│             build/web/env-config.js                              │
│             build/web/flutter_service_worker.js                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ RUNTIME — browser loads index.html                               │
│                                                                  │
│  1. <script src="env-config.js"> executes → window.__NDU_ENV     │
│     is populated with ANTHROPIC_API_KEY, FIREBASE_API_KEY,       │
│     BUILD_STAMP.                                                 │
│                                                                  │
│  2. Inline cache-bust script runs:                               │
│       • kills all existing service workers                       │
│       • nukes all Cache API entries                              │
│       • if ?_ndu=<stamp> missing or stale, redirects with it     │
│         (forces fresh fetch of HTML + JS from origin)            │
│                                                                  │
│  3. <script src="flutter_bootstrap.js" async> loads — Flutter    │
│     engine boots, main.dart.js evaluates, Dart main() runs.      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ RUNTIME — Dart main() in lib/main.dart                           │
│                                                                  │
│  Firebase.initializeApp(...)                                     │
│  await EnvConfigLoader.load()        ← reads window.__NDU_ENV    │
│  ApiKeyManager.initializeApiKey()                                │
│  if EnvConfigLoader.hasAnthropicKey:                             │
│    ApiKeyManager.setApiKey(EnvConfigLoader.anthropicApiKey!)     │
│  else:                                                           │
│    use Cloud Function proxy (SecureAPIConfig.baseUrl)            │
│  runApp(MyApp())                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**API key priority order (highest → lowest):**
1. `window.__NDU_ENV.ANTHROPIC_API_KEY` (deploy-time override via env-config.js)
2. Per-user key set via the Settings screen (stored in Firestore `users/{uid}.claudeApiKey`)
3. Cloud Function proxy at `https://us-central1-ndu-d3f60.cloudfunctions.net/claudeProxy` (server-side key, never exposed to the client — **this is the default and recommended mode**)

---

## 6. Cache-busting strategy

The combination of three mechanisms guarantees that every new deployment is picked up instantly, with no user action required:

| Layer | Mechanism | What it prevents |
|-------|-----------|------------------|
| HTTP | `Cache-Control: no-cache, no-store, must-revalidate` meta tags | Browser HTTP cache holding stale HTML |
| URL | `?v=<stamp>` on every asset URL (favicon, manifest, icons, env-config.js, flutter_bootstrap.js) | Browser reusing cached assets from a previous deploy |
| JS | Inline script that kills all service workers + nukes Cache API + force-redirects with `?_ndu=<stamp>` | Stale service worker serving old `main.dart.js` from Cache API |
| SW | Versioned `CACHE_NAME = 'ndu-flutter-app-v<stamp>'` + delete-all-old-caches on activate | New SW activation immediately purging previous version's cache |

**Why not just use Flutter's default service worker?**
Flutter's default SW calls `self.registration.unregister()` on every activate. This means: (a) PWA install / offline mode never works (the SW is gone before it can cache anything), and (b) the browser falls back to plain HTTP cache, which for `main.dart.js` can be hours stale. The versioned SW in this migration gives us: instant updates + working offline + clean cache rotation.

**Why the `?_ndu=<stamp>` redirect?**
Even with `Cache-Control: no-cache`, some CDNs and corporate proxies ignore the header and serve stale HTML. The redirect forces a URL change, which CDNs/proxies cannot ignore — they must fetch fresh from origin.

---

## 7. How to deploy after this migration

```bash
# 1. (One-time) fill in env-config.js with your deploy-time secrets.
#    For production, LEAVE ANTHROPIC_API_KEY empty to use the Cloud
#    Function proxy. Only set FIREBASE_API_KEY if you need to override
#    the compiled-in value.
$EDITOR web/env-config.js

# 2. Build + stamp in one step
./scripts/build_web.sh --base-href /NDU-Test/

# 3. Deploy build/web/ to your hosting provider
#    For Firebase Hosting:
firebase deploy --only hosting

#    For GitHub Pages (NDU-Test repo):
cp -r build/web/* /path/to/NDU-Test/
cd /path/to/NDU-Test && git add . && git commit -m "Deploy: <message>" && git push

# 4. (Optional) sync the docs/ folder too if you serve from docs/
cp -r build/web/* docs/
```

**Local development:**
```bash
flutter run -d chrome
# env-config.js loads with empty keys → Cloud Function proxy is used.
# The cache-bust script detects 'dev-local' mode and skips the redirect
# loop, so hot-reload works normally.
```

---

## 8. Verification checklist

After pulling this migration, verify each piece works:

- [ ] `flutter pub get` completes without errors
- [ ] `flutter analyze` shows no new warnings vs. pre-migration baseline
- [ ] `flutter run -d chrome` boots the app; loading spinner appears for ~1s before Flutter renders
- [ ] Browser console shows: `[NDU] Killed service worker: ...` (if any old SWs existed) and `EnvConfigLoader: loaded __NDU_ENV (anthropic=none, firebase=none, build=dev-local)`
- [ ] `flutter build web` succeeds
- [ ] `python3 scripts/stamp_build_version.py --dry-run` reports 3 files would be stamped
- [ ] After deploy, visiting the site appends `?_ndu=<stamp>` to the URL on first load
- [ ] Settings screen → AI Integrations still works (Cloud Function proxy responds)
- [ ] Dark/light theme toggle in Settings still works
- [ ] Portfolio dashboard renders charts
- [ ] CSV import button on any data table still opens the import dialog
- [ ] Voice/mic icon on any text field still triggers speech-to-text

---

## 9. What this migration does NOT do

- Does not regenerate `main.dart.js` / `flutter.js` / `canvaskit/` — those are binary build artifacts that require `flutter build web` to regenerate. Run §7 to refresh them.
- Does not change the Claude model (`claude-sonnet-4-20250514` is still the default in `api_config_secure.dart`).
- Does not change the Cloud Function proxy URL.
- Does not migrate any data — this is purely a code/deployment migration.
- Does not touch Firebase config (`firebase_options.dart`, `firebase.json`, `firestore.rules`).
- Does not modify the iOS/Android native shells — only web deployment + Dart runtime config.

---

## 10. Rollback

If anything breaks, revert this migration with:

```bash
git revert <migration-commit-sha>
```

The migration is a single atomic commit, so revert is clean. Pre-migration state:
- `web/index.html` = stock Flutter template (no spinner, no cache-bust)
- `web/env-config.js` = did not exist
- `web/flutter_service_worker.js` = did not exist
- `lib/services/env_config_loader*.dart` = did not exist
- `lib/main.dart` = no EnvConfigLoader call
- `pubspec.yaml` version = `1.0.0+2`

After rollback, `flutter build web` produces the pre-migration output and the app works exactly as before.
