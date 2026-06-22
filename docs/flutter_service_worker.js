'use strict';

// =============================================================================
// NDU Project — Custom Flutter Service Worker (docs/ deployment)
// =============================================================================
// See web/flutter_service_worker.js for full documentation.
// =============================================================================

const _NDU_RAW_STAMP = 'NDU_BUILD_STAMP';
const NDU_BUILD_STAMP =
  (_NDU_RAW_STAMP && _NDU_RAW_STAMP !== 'NDU_BUILD_STAMP')
    ? _NDU_RAW_STAMP
    : 'dev-local';

const CACHE_NAME = 'ndu-flutter-app-v' + NDU_BUILD_STAMP;

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log('[NDU SW] Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
          return Promise.resolve();
        })
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  const isNavigation = event.request.mode === 'navigate';

  event.respondWith(
    fetch(event.request)
      .then((response) => {
        if (response && response.status === 200 && response.type === 'basic') {
          const responseClone = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseClone).catch((e) => {
              console.warn('[NDU SW] Cache put failed for', event.request.url, e);
            });
          });
        }
        return response;
      })
      .catch(() => {
        if (isNavigation) {
          return caches.match('index.html').then((r) => r || caches.match(event.request));
        }
        return caches.match(event.request);
      })
  );
});

self.addEventListener('message', (event) => {
  if (event.data === 'ndu-skip-waiting') {
    self.skipWaiting();
  }
});
