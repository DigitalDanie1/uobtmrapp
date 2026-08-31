const CACHE_PREFIX = "banking-demo-";
const CACHE_NAME = `${CACHE_PREFIX}v90`;
const APP_START = "./index.html?app=1&viewer=1&v=90";

const APP_SHELL = [
  "./",
  APP_START,
  "./manifest.json?v=90",
  "./assets/brand-uob-tmrw-extracted.png",
  "./assets/merchant-insight-art-20260824.png",
  "./assets/closest-icon-180.png",
  "./assets/closest-icon-192.png",
  "./assets/closest-icon-512.png",
  "./assets/closest-intro.png",
  "./assets/auth-loading-fixed-20260824.png",
  "./assets/quick-paynow-icon-sharp-crisp.png",
  "./assets/quick-transfer-icon-sharp-crisp.png",
  "./assets/quick-scan-icon-sharp-crisp.png",
  "./assets/tool-estatements-trimmed-crisp.png",
  "./assets/tool-limits-trimmed-crisp.png",
  "./assets/tool-apply-trimmed-crisp.png",
  "./assets/tool-fx-icon-badge-sharp-crisp.png",
  "./assets/nav-home-trimmed-crisp.png",
  "./assets/nav-accounts-trimmed-crisp.png",
  "./assets/nav-wealth-trimmed-crisp.png",
  "./assets/nav-rewards-trimmed-crisp.png",
  "./assets/nav-services-trimmed-crisp.png",
  "./assets/bottom-nav-reference-20260824.png",
  "./assets/tab-accounts-20260824.jpg",
  "./assets/tab-wealth-20260824.jpg",
  "./assets/tab-rewards-20260824.jpg",
  "./assets/tab-services-20260824.jpg"
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
      .then((keys) => Promise.all(
        keys
          .filter((key) => key.startsWith(CACHE_PREFIX) && key !== CACHE_NAME)
          .map((key) => caches.delete(key))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET") return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  if (request.mode === "navigate") {
    event.respondWith(
      fetch(request)
        .then((response) => {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
          return response;
        })
        .catch(async () => {
          return (await caches.match(request)) ||
            (await caches.match(APP_START)) ||
            (await caches.match("./"));
        })
    );
    return;
  }

  event.respondWith(
    caches.match(request).then((cached) => {
      const network = fetch(request)
        .then((response) => {
          if (response.ok) {
            const copy = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
          }
          return response;
        })
        .catch(() => cached);
      return cached || network;
    })
  );
});
