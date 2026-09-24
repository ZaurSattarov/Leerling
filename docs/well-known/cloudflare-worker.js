// Cloudflare Worker — plak dit in workers.dev dashboard of wrangler
// Route: klantio.com/.well-known/assetlinks.json
//
// Stap 1: ga naar https://dash.cloudflare.com → Workers & Pages → Create Worker
// Stap 2: plak deze code
// Stap 3: voeg een route toe: klantio.com/.well-known/assetlinks.json
// Stap 4: vervang de SHA256 fingerprint hieronder met jouw release-keystore fingerprint
//         (keytool -list -v -keystore release.jks -alias jouw-alias → regel "SHA256: ...")

const ASSET_LINKS = [
  {
    relation: ["delegate_permission/common.handle_all_urls"],
    target: {
      namespace: "android_app",
      package_name: "com.klantio.leerling",
      sha256_cert_fingerprints: [
        "VERVANG_DIT_MET_JOUW_SHA256_FINGERPRINT"
      ]
    }
  }
];

export default {
  async fetch(request) {
    const url = new URL(request.url);
    if (url.pathname === "/.well-known/assetlinks.json") {
      return new Response(JSON.stringify(ASSET_LINKS, null, 2), {
        headers: {
          "Content-Type": "application/json",
          "Cache-Control": "public, max-age=3600"
        }
      });
    }
    return new Response("Not Found", { status: 404 });
  }
};
