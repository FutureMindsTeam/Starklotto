if (!self.define) {
  let e,
    s = {};
  const n = (n, i) => (
    (n = new URL(n + ".js", i).href),
    s[n] ||
      new Promise((s) => {
        if ("document" in self) {
          const e = document.createElement("script");
          ((e.src = n), (e.onload = s), document.head.appendChild(e));
        } else ((e = n), importScripts(n), s());
      }).then(() => {
        let e = s[n];
        if (!e) throw new Error(`Module ${n} didn’t register its module`);
        return e;
      })
  );
  self.define = (i, a) => {
    const c =
      e ||
      ("document" in self ? document.currentScript.src : "") ||
      location.href;
    if (s[c]) return;
    let t = {};
    const r = (e) => n(e, c),
      o = { module: { uri: c }, exports: t, require: r };
    s[c] = Promise.all(i.map((e) => o[e] || r(e))).then((e) => (a(...e), t));
  };
}
define(["./workbox-4754cb34"], function (e) {
  "use strict";
  (importScripts(),
    self.skipWaiting(),
    e.clientsClaim(),
    e.precacheAndRoute(
      [
        { url: "/Andres.jpeg", revision: "d60720c95c1fd3d82dc681b4fe7a6977" },
        { url: "/David.jpeg", revision: "ed9364b636205805087b76f5d2bc92a1" },
        {
          url: "/FutureMindsLogo.png",
          revision: "5d1b117ea1cd8acec1db5384a7e93290",
        },
        { url: "/Jeff.jpeg", revision: "db1b90dc9668178b88891f1290659583" },
        { url: "/Joseph.jpeg", revision: "6a30f4063a312f5e19e6ec54ae833831" },
        { url: "/Kim.png", revision: "afe82c70a85aab93417aaff6cf74179b" },
        { url: "/Profile.svg", revision: "9dfb050b88a739a1984bfd6ace9bcfd6" },
        {
          url: "/Starklotto.png",
          revision: "28f2c14b1e65406102932aa7c1b61060",
        },
        {
          url: "/_next/app-build-manifest.json",
          revision: "ed3412ae1e9aa9f8ed86189180f23992",
        },
        {
          url: "/_next/static/EBvwG1hAziehwJ3W-P5ng/_buildManifest.js",
          revision: "ceeea5f99e37b1d0702b09eb364bf5e8",
        },
        {
          url: "/_next/static/EBvwG1hAziehwJ3W-P5ng/_ssgManifest.js",
          revision: "b6652df95db52feb4daf4eca35380933",
        },
        {
          url: "/_next/static/chunks/1224-4be3c0cbb0cc5922.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/1515-54ed9f47d86a50a8.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/1684-dc4632b38f8aec56.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/2347.3ebab643c29426da.js",
          revision: "3ebab643c29426da",
        },
        {
          url: "/_next/static/chunks/2696-577dbd439905c1c1.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/2f0b94e8-009c4fe7d09feb3b.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/3063-5b2d8b81633aa1b8.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/327-cc75d1b7e4708c73.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/3746-a1187857af06072c.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/3824-508bc92cfdfc3e8e.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/4046-ccda7714e0d4974c.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/472.04a8725c923ee78b.js",
          revision: "04a8725c923ee78b",
        },
        {
          url: "/_next/static/chunks/473f56c0-74b1e06785d940e9.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/4793-393b41742bb636a7.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/4bd1b696-29c1d99d049afc50.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/5419-50b1c05912da4127.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/5889-a39f0e2ce7fca59c.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/6399-d6c8317e5d0d01a0.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/6635-ffadd7d6910632bd.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/6874-6cd0f4c38cc25668.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/70646a03-267950ab7c7230ee.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/8260-a2d6da7ba3d8f3da.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/8596-a5a8e5e1d2b6df42.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/8944-f976f02e74f6b6de.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/9341.c34d444181fc794f.js",
          revision: "c34d444181fc794f",
        },
        {
          url: "/_next/static/chunks/940-1b27a26a9a7577bd.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/972.40aa2ad74a666ad5.js",
          revision: "40aa2ad74a666ad5",
        },
        {
          url: "/_next/static/chunks/9850-78bfb46ad63cf87f.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/_not-found/page-fd37104fb73075c7.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/about-us/page-0b2dbd70d6dd7aa7.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/admin/layout-5cbf8126ee98fa7f.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/admin/page-9787ddf958425645.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/api/price/route-ec6708877b92f2cd.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/buy-tickets/page-2076da7381e9ac47.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/configure/page-151fb61b32f84563.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/contact-us/page-feff237ee83156bd.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/debug/page-d3be0f5dffc356e4.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/how-it-works/page-cb7cc6cc5279beee.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/jackpot-report/page-d2f1aeecb95fd989.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/layout-142d259bf39ed0af.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/page-6e56957591ae67a4.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/play/confirmation/page-24cb4c8a1f9df7ff.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/play/page-6a86d894e8b5d300.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/prizes/page-970ce886025a196d.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/profile/page-b598bd275b5c36e2.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/app/swap/page-f8af3486fc06fa47.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/e6909d18-2792831708caa34e.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/framework-c054b661e612b06c.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/main-197ffb449a46e464.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/main-app-37e4431ec34ff6d6.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/pages/_app-b6f79e9ed92d84d6.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/pages/_error-f7865bb9e588bf6e.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/chunks/polyfills-42372ed130431b0a.js",
          revision: "846118c33b2c0e922d7b3a7676f81f6f",
        },
        {
          url: "/_next/static/chunks/webpack-275c5cdd86d043f6.js",
          revision: "EBvwG1hAziehwJ3W-P5ng",
        },
        {
          url: "/_next/static/css/24c43de7ddce538c.css",
          revision: "24c43de7ddce538c",
        },
        {
          url: "/blast-icon-color.svg",
          revision: "f455c22475a343be9fcd764de7e7147e",
        },
        {
          url: "/debug-icon.svg",
          revision: "25aadc709736507034d14ca7aabcd29d",
        },
        {
          url: "/debug-image.png",
          revision: "34c4ca2676dd59ff24d6338faa1af371",
        },
        {
          url: "/explorer-icon.svg",
          revision: "84507da0e8989bb5b7616a3f66d31f48",
        },
        {
          url: "/gradient-s.svg",
          revision: "c003f595a6d30b1b476115f64476e2cf",
        },
        { url: "/jackpot.svg", revision: "bbec739248166cab31c91ceea72e8d97" },
        { url: "/logo.ico", revision: "0359e607e29a3d3b08095d84a9d25c39" },
        { url: "/logo.svg", revision: "962a8546ade641ef7ad4e1b669f0548c" },
        { url: "/manifest.json", revision: "781788f3e2bc4b2b176b5d8c425d7475" },
        {
          url: "/overlay-blur-blue.svg",
          revision: "a2f37f4e955befd9a2ab180179d480df",
        },
        {
          url: "/overlay-blur-purple.svg",
          revision: "c32bb92e9825bc05d28c335590eba7d9",
        },
        {
          url: "/rpc-version.png",
          revision: "cf97fd668cfa1221bec0210824978027",
        },
        {
          url: "/scaffold-config.png",
          revision: "1ebfc244c31732dc4273fe292bd07596",
        },
        {
          url: "/sn-symbol-gradient.png",
          revision: "908b60a4f6b92155b8ea38a009fa7081",
        },
        {
          url: "/starkcompass-icon.svg",
          revision: "eccc2ece017ee9e73e512996b74e49ac",
        },
        {
          url: "/starklotto-main-home.png",
          revision: "a5ac0d6b3535aa95802af961927381c4",
        },
        { url: "/strk-svg.svg", revision: "29c25d68f984f9b3eae9eec84711dc94" },
        { url: "/trophy.svg", revision: "ed1faa0e010232768ef763ce1bdeff5f" },
        {
          url: "/voyager-icon.svg",
          revision: "06663dd5ba2c49423225a8e3893b45fe",
        },
      ],
      { ignoreURLParametersMatching: [] },
    ),
    e.cleanupOutdatedCaches(),
    e.registerRoute(
      "/",
      new e.NetworkFirst({
        cacheName: "start-url",
        plugins: [
          {
            cacheWillUpdate: async ({
              request: e,
              response: s,
              event: n,
              state: i,
            }) =>
              s && "opaqueredirect" === s.type
                ? new Response(s.body, {
                    status: 200,
                    statusText: "OK",
                    headers: s.headers,
                  })
                : s,
          },
        ],
      }),
      "GET",
    ),
    e.registerRoute(
      /^https:\/\/fonts\.(?:gstatic)\.com\/.*/i,
      new e.CacheFirst({
        cacheName: "google-fonts-webfonts",
        plugins: [
          new e.ExpirationPlugin({ maxEntries: 4, maxAgeSeconds: 31536e3 }),
        ],
      }),
      "GET",
    ),
    e.registerRoute(
      /^https:\/\/fonts\.(?:googleapis)\.com\/.*/i,
      new e.StaleWhileRevalidate({
        cacheName: "google-fonts-stylesheets",
        plugins: [
          new e.ExpirationPlugin({ maxEntries: 4, maxAgeSeconds: 604800 }),
        ],
      }),
      "GET",
    ),
    e.registerRoute(
      /\.(?:eot|otf|ttc|ttf|woff|woff2|font.css)$/i,
      new e.StaleWhileRevalidate({
        cacheName: "static-font-assets",
        plugins: [
          new e.ExpirationPlugin({ maxEntries: 4, maxAgeSeconds: 604800 }),
        ],
      }),
      "GET",
    ),
    e.registerRoute(
      /\.(?:jpg|jpeg|gif|png|svg|ico|webp)$/i,
      new e.StaleWhileRevalidate({
        cacheName: "static-image-assets",
        plugins: [
          new e.ExpirationPlugin({ maxEntries: 64, maxAgeSeconds: 86400 }),
        ],
      }),
      "GET",
    ),
    e.registerRoute(
      /\/_next\/image\?url=.+$/i,
      new e.StaleWhileRevalidate({
        cacheName: "next-image",
        plugins: [
          new e.ExpirationPlugin({ maxEntries: 64, maxAgeSeconds: 86400 }),
        ],
      }),
      "GET",
    ),
    e.registerRoute(
      /\.(?:mp3|wav|ogg)$/i,
      new e.CacheFirst({
        cacheName: "static-audio-assets",
        plugins: [
          new e.RangeRequestsPlugin(),
          new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 86400 }),
        ],
      }),
      "GET",
    ),
    e.registerRoute(
      /\.(?:mp4)$/i,
      new e.CacheFirst({
        cacheName: "static-video-assets",
        plugins: [
          new e.RangeRequestsPlugin(),
          new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 86400 }),
        ],
      }),
      "GET",
    ),
    e.registerRoute(
      /\.(?:js)$/i,
      new e.StaleWhileRevalidate({
        cacheName: "static-js-assets",
        plugins: [
          new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 86400 }),
        ],
      }),
      "GET",
    ),
    e.registerRoute(
      /\.(?:css|less)$/i,
      new e.StaleWhileRevalidate({
        cacheName: "static-style-assets",
        plugins: [
          new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 86400 }),
        ],
      }),
      "GET",
    ),
    e.registerRoute(
      /\/_next\/data\/.+\/.+\.json$/i,
      new e.StaleWhileRevalidate({
        cacheName: "next-data",
        plugins: [
          new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 86400 }),
        ],
      }),
      "GET",
    ),
    e.registerRoute(
      /\.(?:json|xml|csv)$/i,
      new e.NetworkFirst({
        cacheName: "static-data-assets",
        plugins: [
          new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 86400 }),
        ],
      }),
      "GET",
    ),
    e.registerRoute(
      ({ url: e }) => {
        if (!(self.origin === e.origin)) return !1;
        const s = e.pathname;
        return !s.startsWith("/api/auth/") && !!s.startsWith("/api/");
      },
      new e.NetworkFirst({
        cacheName: "apis",
        networkTimeoutSeconds: 10,
        plugins: [
          new e.ExpirationPlugin({ maxEntries: 16, maxAgeSeconds: 86400 }),
        ],
      }),
      "GET",
    ),
    e.registerRoute(
      ({ url: e }) => {
        if (!(self.origin === e.origin)) return !1;
        return !e.pathname.startsWith("/api/");
      },
      new e.NetworkFirst({
        cacheName: "others",
        networkTimeoutSeconds: 10,
        plugins: [
          new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 86400 }),
        ],
      }),
      "GET",
    ),
    e.registerRoute(
      ({ url: e }) => !(self.origin === e.origin),
      new e.NetworkFirst({
        cacheName: "cross-origin",
        networkTimeoutSeconds: 10,
        plugins: [
          new e.ExpirationPlugin({ maxEntries: 32, maxAgeSeconds: 3600 }),
        ],
      }),
      "GET",
    ));
});
