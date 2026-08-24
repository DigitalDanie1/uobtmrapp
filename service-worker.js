const CACHE_NAME = "banking-assignment-demo-v4";

const APP_SHELL = [
  "./",
  "./index.html",
  "./index.html?app=1",
  "./closest-original-demo.html",
  "./manifest.json",
  "./closest-manifest.json",
  "./assets/pwa-icon-180.png",
  "./assets/pwa-icon-192.png",
  "./assets/pwa-icon-512.png",
  "./assets/closest-icon-180.png",
  "./assets/closest-icon-192.png",
  "./assets/closest-icon-512.png",
  "./assets/closest-intro.png",
  "./assets/brand-uob-tmrw-extracted.png",
  "./assets/quick-paynow-icon-sharp-crisp.png",
  "./assets/quick-transfer-icon-sharp-crisp.png",
  "./assets/quick-scan-icon-sharp-crisp.png",
  "./assets/tool-estatements-trimmed-crisp.png",
  "./assets/tool-limits-trimmed-crisp.png",
  "./assets/tool-apply-trimmed-crisp.png",
  "./assets/tool-fx-icon-badge-sharp-crisp.png",
  "./assets/promo-money-trip-fixed.png",
  "./assets/nav-home-trimmed-crisp.png",
  "./assets/nav-accounts-trimmed-crisp.png",
  "./assets/nav-wealth-trimmed-crisp.png",
  "./assets/nav-rewards-trimmed-crisp.png",
  "./assets/nav-services-trimmed-crisp.png"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return;

  const requestURL = new URL(event.request.url);
  if (requestURL.origin !== self.location.origin) return;

  if (event.request.mode === "navigate") {
    event.respondWith(
      fetch(event.request)
        .then((response) => {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
          return response;
        })
        .catch(() => caches.match(event.request).then((cached) => cached || caches.match("./index.html?app=1")))
    );
    return;
  }

  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) return cached;
      return fetch(event.request).then((response) => {
        if (response.ok) {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
        }
        return response;
      });
    })
  );
});
