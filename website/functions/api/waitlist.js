// POST /api/waitlist: adds an email to the travary.app waiting list (D1).
//
// Accepts JSON from the site's waiting-list card, or a plain form post from
// /early-access (no JavaScript), which is redirected to /early-access/joined.
// Nothing is ever returned about who else is on the list: a repeat sign-up
// gets the same "you're on the list" answer as a new one.
//
// Bindings (website/wrangler.toml): DB, the D1 database "travary-waitlist".
// Secret: RATE_SALT (salts the per-visitor hashes; set with
// `wrangler pages secret put RATE_SALT --project-name travary`).

const ALLOWED_ORIGINS = [
  "https://travary.app",
  "https://www.travary.app",
  "https://travary.pages.dev",
];
const PLATFORMS = ["", "iphone", "android"];
const PER_HOUR = 5; // sign-ups from one visitor in an hour
const EMAIL = /^[^\s@<>()[\]\\,;:"]{1,64}@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$/;

export async function onRequestPost({ request, env }) {
  const isJson = (request.headers.get("content-type") || "").includes("application/json");
  const reply = (status, body) => {
    if (isJson) {
      return new Response(JSON.stringify(body), {
        status,
        headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" },
      });
    }
    const to = new URL(body.ok ? "/early-access/joined" : "/early-access", request.url);
    if (!body.ok) to.searchParams.set("error", body.error || "1");
    return Response.redirect(to.toString(), 303);
  };

  const origin = request.headers.get("origin");
  const local = origin && /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
  const preview = origin && /^https:\/\/[a-z0-9-]+\.travary\.pages\.dev$/.test(origin);
  if (origin && !ALLOWED_ORIGINS.includes(origin) && !local && !preview) {
    return reply(403, { ok: false, error: "origin" });
  }

  let data = {};
  try {
    data = isJson ? await request.json() : Object.fromEntries(await request.formData());
  } catch {
    return reply(400, { ok: false, error: "format" });
  }

  // The honeypot: people never see this field, form-filling bots do. Pretend
  // it worked so they don't learn anything.
  if (String(data.company || "").trim()) return reply(200, { ok: true });
  // Filled in faster than a person could.
  const opened = Number(data.t || 0);
  if (opened && Date.now() - opened < 1500) return reply(200, { ok: true });

  const email = String(data.email || "").trim().toLowerCase();
  if (email.length > 254 || !EMAIL.test(email)) return reply(400, { ok: false, error: "email" });
  const platform = PLATFORMS.includes(String(data.platform || "")) ? String(data.platform || "") : "";
  let source = String(data.source || "").slice(0, 200);
  if (!source.startsWith("/")) source = "";

  if (!env.DB) return reply(503, { ok: false, error: "unavailable" });

  // A per-visitor limit, from a salted hash of the IP that can't be turned
  // back into it. The salt changes every day, and old rows are deleted.
  const now = Math.floor(Date.now() / 1000);
  const ip = request.headers.get("cf-connecting-ip") || "";
  const day = new Date().toISOString().slice(0, 10);
  const ipHash = ip ? await sha256(`${env.RATE_SALT || "travary"}:${day}:${ip}`) : "";
  if (ipHash) {
    const recent = await env.DB.prepare("SELECT COUNT(*) AS n FROM attempts WHERE ip_hash = ? AND at > ?")
      .bind(ipHash, now - 3600)
      .first();
    if (recent && recent.n >= PER_HOUR) return reply(429, { ok: false, error: "busy" });
  }

  const statements = [
    env.DB.prepare(
      `INSERT INTO waitlist (email, platform, source) VALUES (?, ?, ?)
       ON CONFLICT(email) DO UPDATE SET platform = CASE WHEN excluded.platform <> '' THEN excluded.platform ELSE waitlist.platform END`,
    ).bind(email, platform, source),
    env.DB.prepare("DELETE FROM attempts WHERE at < ?").bind(now - 86400),
  ];
  if (ipHash) statements.push(env.DB.prepare("INSERT INTO attempts (ip_hash, at) VALUES (?, ?)").bind(ipHash, now));
  try {
    await env.DB.batch(statements);
  } catch (e) {
    console.error("waitlist write failed", e && e.message); // never log the address
    return reply(500, { ok: false, error: "unavailable" });
  }
  return reply(200, { ok: true });
}

export function onRequest() {
  return new Response("Method not allowed", { status: 405, headers: { allow: "POST" } });
}

async function sha256(text) {
  const bytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return [...new Uint8Array(bytes)].map((b) => b.toString(16).padStart(2, "0")).join("");
}
