/* 계룡산 삭도 기록 — 서비스워커(설치/오프라인 셸). 배포 시 CACHE 버전만 올리면 갱신됨. */
const CACHE = "sakdo-shell-v2";
const SHELL = [
  "./", "./index.html", "./config.js", "./manifest.webmanifest",
  "./icons/icon-192.png", "./icons/icon-512.png", "./icons/icon-180.png",
  "https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js",
  "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.min.js"
];

self.addEventListener("install", (e) => {
  self.skipWaiting();
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL).catch(() => {})));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys()
      .then((ks) => Promise.all(ks.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;
  let url;
  try { url = new URL(req.url); } catch (_) { return; }

  // Supabase(데이터·실시간)는 항상 네트워크 — 캐시하지 않음
  if (url.hostname.endsWith("supabase.co")) return;

  // HTML 문서는 네트워크 우선 → 항상 최신 배포 반영, 오프라인이면 캐시로 폴백
  const accept = req.headers.get("accept") || "";
  if (req.mode === "navigate" || accept.includes("text/html")) {
    e.respondWith(
      fetch(req).then((r) => {
        const cp = r.clone();
        caches.open(CACHE).then((c) => c.put("./index.html", cp));
        return r;
      }).catch(() => caches.match("./index.html"))
    );
    return;
  }

  // 그 외 정적 자원(아이콘·CDN 스크립트·config)은 캐시 우선, 없으면 네트워크 후 저장
  e.respondWith(
    caches.match(req).then((c) =>
      c || fetch(req).then((r) => {
        const cp = r.clone();
        caches.open(CACHE).then((ca) => ca.put(req, cp));
        return r;
      }).catch(() => c)
    )
  );
});
