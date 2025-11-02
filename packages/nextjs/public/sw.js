if (!self.define) {
  let e,
    s = {};
  const n = (n, a) => (
    (n = new URL(n + ".js", a).href),
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
  self.define = (a, i) => {
    const t =
      e ||
      ("document" in self ? document.currentScript.src : "") ||
      location.href;
    if (s[t]) return;
    let c = {};
    const r = (e) => n(e, t),
      l = { module: { uri: t }, exports: c, require: r };
    s[t] = Promise.all(a.map((e) => l[e] || r(e))).then((e) => (i(...e), c));
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
        {
          url: "/Logo-sin-texto.png",
          revision: "7fbf40dd5ec3cdec627b28490dec1430",
        },
        {
          url: "/Logo_Sin_Texto_Transparente.png",
          revision: "e1015ed1b3bc6467b6d76194dbe66d8e",
        },
        { url: "/Profile.svg", revision: "7ec057e52553d10cbcbfa1558c731aec" },
        {
          url: "/Starklotto.png",
          revision: "28f2c14b1e65406102932aa7c1b61060",
        },
        {
          url: "/_next/app-build-manifest.json",
          revision: "bb0b4ba27f16bc2877076316c2bfdd85",
        },
        {
          url: "/_next/static/chunks/1186-9a65c2a5586b201c.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/1218-eb34d217f148215b.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/1684-dc4632b38f8aec56.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/2077-0faa45e0724c5fa6.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/2200-57c1f5c2ae1dad70.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/2347.ef36ce4322b451d1.js",
          revision: "ef36ce4322b451d1",
        },
        {
          url: "/_next/static/chunks/2564-5a8dcdfb20abd6a8.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/277-4b92422e0dd77f4b.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/2878-bb61f0752e5f06e6.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/2f0b94e8-009c4fe7d09feb3b.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/3063-392cf10d902d1d57.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/30a37ab2-c194af7319be38d5.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/4026-0c1450ede9e9d058.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/4139-ae1bd859311056aa.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/4191-17511b5bb8d710a2.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/4277-23d3626bb2535746.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/473f56c0-6b03c6907205fb07.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/4bd1b696-29c1d99d049afc50.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/5274-4fc2df354ce7ef88.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/5470-88842a1e3eb51b04.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/5728.12b88c9a7cf9f3d8.js",
          revision: "12b88c9a7cf9f3d8",
        },
        {
          url: "/_next/static/chunks/6047-230155c320ecccab.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/6281-88eea553f9a87ab0.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/658-5fd6cdc383acd9d5.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/6874-3389db82a2c367e3.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/6885-085169be9377ee78.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/7022-4eb19c5647273d0b.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/70646a03-49307dd85cd81a56.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/7248-f5f3aca7ad687091.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/8225-e9e280387ece4bd2.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/8252-125ae14c1f773066.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/8260-a2d6da7ba3d8f3da.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/8844-f28ae56012058f65.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/930-63713162fb98c1f9.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/9608-7ebebc96817e5764.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/972.9dee389435e21097.js",
          revision: "9dee389435e21097",
        },
        {
          url: "/_next/static/chunks/app/_not-found/page-e021c69819b6c202.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/about-us/page-733cc13964489540.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/admin-lottery/page-0872504be0c5ce86.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/admin/layout-b34a32a6c44d9c2f.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/admin/page-ba3501461696b75a.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/api/price/route-d7ff5854924f6fdc.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/configure/page-9db3d8831e9168bf.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/contact-us/page-62ade46c57388c09.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/dapp/buy-tickets/page-e78b023de6169ef5.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/dapp/claim/page-aeeca46d691088bd.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/dapp/dashboard/page-586fd77169bd0750.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/dapp/layout-f80554f204e1d958.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/dapp/mint/page-134c618992e23663.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/dapp/page-41d42d77a83ebacb.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/dapp/unmint/page-da4152c53b71bace.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/debug/page-1142d1559c7b206d.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/how-it-works/page-03189833d8fe55ad.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/i18n-demo/page-a15b2b017158ab1e.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/jackpot-report/page-9b71ed7bb679fffc.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/layout-a098e52d49134f15.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/not-found-5095b03fcdaa1009.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/page-2a76d79592010369.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/play/confirmation/page-cd1c54eaca96a4c4.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/play/page-2a4a57e2265e5e69.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/prizes/page-accf0412f40674e5.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/profile/page-eb4046598a37c38b.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/results/%5BdrawId%5D/page-c28ef5663ff02cc1.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/app/results/page-18e303c64cc09a13.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/e6909d18-d1e7bf26fe24aa96.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/framework-fc63273ed5a51da5.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/main-a460c7fac429e573.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/main-app-e4c6a0453a83baa7.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/pages/_app-5d1abe03d322390c.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/pages/_error-3b2a1d523de49635.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/chunks/polyfills-42372ed130431b0a.js",
          revision: "846118c33b2c0e922d7b3a7676f81f6f",
        },
        {
          url: "/_next/static/chunks/webpack-c8b3617e853d3c50.js",
          revision: "iCaUWjtmr8nS2ABz6lyYO",
        },
        {
          url: "/_next/static/css/a3548ace7fb40a91.css",
          revision: "a3548ace7fb40a91",
        },
        {
          url: "/_next/static/iCaUWjtmr8nS2ABz6lyYO/_buildManifest.js",
          revision: "f45e51bfddb1d656d7abd0bfc4679fa5",
        },
        {
          url: "/_next/static/iCaUWjtmr8nS2ABz6lyYO/_ssgManifest.js",
          revision: "b6652df95db52feb4daf4eca35380933",
        },
        {
          url: "/blast-icon-color.svg",
          revision: "d949ffbc94b7c50e2e4fcf2b1daf1607",
        },
        {
          url: "/debug-icon.svg",
          revision: "62ce54a2ddb8d11cb25c891c9adbdbea",
        },
        {
          url: "/debug-image.png",
          revision: "34c4ca2676dd59ff24d6338faa1af371",
        },
        {
          url: "/explorer-icon.svg",
          revision: "f6413b9b86d870f77edeb18891f6b3d5",
        },
        {
          url: "/gradient-s.svg",
          revision: "1966c9867618efad27716a8591d9ade0",
        },
        { url: "/jackpot.svg", revision: "481b6e2e5e5fa92a5dc041f8803acb47" },
        { url: "/logo.ico", revision: "0359e607e29a3d3b08095d84a9d25c39" },
        { url: "/logo.svg", revision: "a497d49f3c5cf63fe06eda59345d5ec1" },
        { url: "/manifest.json", revision: "781788f3e2bc4b2b176b5d8c425d7475" },
        {
          url: "/overlay-blur-blue.svg",
          revision: "2ae16f575d0e2bf12ecaf14e6fe63439",
        },
        {
          url: "/overlay-blur-purple.svg",
          revision: "128571dc5c25ff9b1c452211584ba3f4",
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
          revision: "f8853deea695e7491b012b31a0e6ed82",
        },
        {
          url: "/starklotto-main-home.png",
          revision: "a5ac0d6b3535aa95802af961927381c4",
        },
        { url: "/strk-svg.svg", revision: "ebece79312b65a26a672c5fc6acb29b4" },
        { url: "/trophy.svg", revision: "e9348e094665c925720fdf316722bfb1" },
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
              state: a,
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
