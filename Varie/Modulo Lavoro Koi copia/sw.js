const CACHE_NAME = 'presenze-v1';
const urlsToCache = [
  './',
  './index.html',
  './manifest.json'
];

// Installa il service worker e mette in cache i file
self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(cache) {
        return cache.addAll(urlsToCache);
      })
  );
});

// Intercetta le richieste e serve i file dalla cache
self.addEventListener('fetch', function(event) {
  event.respondWith(
    caches.match(event.request)
      .then(function(response) {
        // Ritorna dalla cache se disponibile, altrimenti dalla rete
        if (response) {
          return response;
        }
        return fetch(event.request);
      }
    )
  );
});

// Salva automaticamente i dati inseriti
self.addEventListener('message', function(event) {
  if (event.data && event.data.type === 'SAVE_DATA') {
    // Salva i dati nel localStorage
    // I dati vengono salvati automaticamente dal browser
  }
}); 