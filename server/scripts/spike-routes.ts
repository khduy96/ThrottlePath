// Phase 0 spike: verify Google Routes API with TWO_WHEELER for home -> work,
// and generate Google Maps navigation links to test on an Android phone.
//
// Run (Node >= 23.6 runs TypeScript directly; no packages needed):
//   node server/scripts/spike-routes.ts            # 4 Routes API calls
//   node server/scripts/spike-routes.ts --dry-run  # print requests, 0 calls
//
// Inputs:
//   - server/scripts/spike.local.json  (copy spike.example.json; gitignored)
//   - ROUTES_API_KEY from the environment or server/.dev.vars (gitignored)
//
// Cost: each real call is billed as "Compute Routes Enterprise" (two-wheeled
// routing): 1,000 free calls per month. This script makes exactly 4 calls.

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

type LatLng = { lat: number; lng: number };

type SpikeConfig = {
  home: LatLng;
  work: LatLng;
  // Up to 3 points the route should pass through (e.g. a bridge, a main road).
  waypoints: LatLng[];
};

type Scenario = {
  name: string;
  intermediates: LatLng[];
  departureOffsetMin: number | null; // null = leave now (field omitted)
};

type RouteResult = {
  scenario: string;
  ok: boolean;
  minutes?: number;
  staticMinutes?: number;
  distanceM?: number;
  error?: string;
};

const ENDPOINT = "https://routes.googleapis.com/directions/v2:computeRoutes";
const FIELD_MASK = "routes.duration,routes.staticDuration,routes.distanceMeters";
const MAX_CALLS = 4;

const scriptDir = dirname(fileURLToPath(import.meta.url));
const serverDir = join(scriptDir, "..");

function loadConfig(): SpikeConfig {
  const path = join(scriptDir, "spike.local.json");
  if (!existsSync(path)) {
    throw new Error(
      `Missing ${path}. Copy spike.example.json to spike.local.json and fill in your coordinates.`,
    );
  }
  const cfg = JSON.parse(readFileSync(path, "utf8")) as SpikeConfig;
  for (const [label, p] of [["home", cfg.home], ["work", cfg.work]] as const) {
    if (!isLatLng(p)) throw new Error(`spike.local.json: "${label}" must be {"lat": number, "lng": number}`);
  }
  if (!Array.isArray(cfg.waypoints) || cfg.waypoints.length > 3 || !cfg.waypoints.every(isLatLng)) {
    throw new Error('spike.local.json: "waypoints" must be an array of 0-3 {"lat","lng"} points');
  }
  return cfg;
}

function isLatLng(p: unknown): p is LatLng {
  const v = p as LatLng;
  return !!v && typeof v.lat === "number" && typeof v.lng === "number"
    && Math.abs(v.lat) <= 90 && Math.abs(v.lng) <= 180;
}

function loadApiKey(): string {
  if (process.env.ROUTES_API_KEY) return process.env.ROUTES_API_KEY;
  const devVars = join(serverDir, ".dev.vars");
  if (existsSync(devVars)) {
    for (const line of readFileSync(devVars, "utf8").split(/\r?\n/)) {
      const m = line.match(/^\s*ROUTES_API_KEY\s*=\s*"?([^"\s]+)"?\s*$/);
      if (m) return m[1];
    }
  }
  throw new Error("ROUTES_API_KEY not found in the environment or server/.dev.vars");
}

// "1234s" or "3.5s" -> minutes
export function parseDurationMinutes(d: string): number {
  const m = /^(\d+(?:\.\d+)?)s$/.exec(d);
  if (!m) throw new Error(`Unexpected duration format: ${d}`);
  return Number(m[1]) / 60;
}

function buildBody(cfg: SpikeConfig, s: Scenario): Record<string, unknown> {
  const body: Record<string, unknown> = {
    origin: { location: { latLng: { latitude: cfg.home.lat, longitude: cfg.home.lng } } },
    destination: { location: { latLng: { latitude: cfg.work.lat, longitude: cfg.work.lng } } },
    travelMode: "TWO_WHEELER",
    routingPreference: "TRAFFIC_AWARE",
    languageCode: "vi",
    regionCode: "VN",
  };
  if (s.intermediates.length > 0) {
    body.intermediates = s.intermediates.map((p) => ({
      location: { latLng: { latitude: p.lat, longitude: p.lng } },
      via: true,
    }));
  }
  if (s.departureOffsetMin !== null) {
    // Past times are only allowed for TRANSIT, so always send a future time.
    body.departureTime = new Date(Date.now() + s.departureOffsetMin * 60_000).toISOString();
  }
  return body;
}

async function callRoutes(apiKey: string, body: Record<string, unknown>): Promise<Omit<RouteResult, "scenario">> {
  const res = await fetch(ENDPOINT, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": apiKey,
      "X-Goog-FieldMask": FIELD_MASK,
    },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  if (!res.ok) return { ok: false, error: `HTTP ${res.status}: ${text.slice(0, 400)}` };
  const json = JSON.parse(text) as {
    routes?: { duration?: string; staticDuration?: string; distanceMeters?: number }[];
  };
  const r = json.routes?.[0];
  if (!r?.duration) return { ok: false, error: `No route returned: ${text.slice(0, 400)}` };
  return {
    ok: true,
    minutes: parseDurationMinutes(r.duration),
    staticMinutes: r.staticDuration ? parseDurationMinutes(r.staticDuration) : undefined,
    distanceM: r.distanceMeters,
  };
}

export function buildNavigationUrl(destination: LatLng, waypoints: LatLng[]): string {
  const params = new URLSearchParams({
    api: "1",
    destination: `${destination.lat},${destination.lng}`,
    travelmode: "two-wheeler",
    dir_action: "navigate",
  });
  if (waypoints.length > 0) {
    params.set("waypoints", waypoints.map((p) => `${p.lat},${p.lng}`).join("|"));
  }
  return `https://www.google.com/maps/dir/?${params.toString()}`;
}

function writeNavLinksPage(cfg: SpikeConfig): string {
  const links = [
    { label: "Đến công ty (không waypoint)", url: buildNavigationUrl(cfg.work, []) },
    { label: `Đến công ty qua ${cfg.waypoints.length} waypoint`, url: buildNavigationUrl(cfg.work, cfg.waypoints) },
    { label: "Về nhà (không waypoint)", url: buildNavigationUrl(cfg.home, []) },
    { label: `Về nhà qua ${cfg.waypoints.length} waypoint (đảo thứ tự)`, url: buildNavigationUrl(cfg.home, [...cfg.waypoints].reverse()) },
  ];
  const items = links
    .map((l) => `<li><a href="${l.url.replace(/&/g, "&amp;")}">${l.label}</a><br><small>${l.url.replace(/&/g, "&amp;")}</small></li>`)
    .join("\n");
  const html = `<!doctype html><html lang="vi"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Thử link dẫn đường</title>
<style>body{font:18px system-ui;margin:16px}li{margin:0 0 20px}a{font-size:22px}small{word-break:break-all;color:#666}</style>
</head><body><h1>Thử link dẫn đường</h1>
<p>Mở từng link trên điện thoại Android. Kiểm tra: vào thẳng chế độ dẫn đường, đúng chế độ xe máy, đi qua đúng waypoint.</p>
<ol>${items}</ol></body></html>`;
  const out = join(scriptDir, "nav-links.local.html");
  writeFileSync(out, html, "utf8");
  for (const l of links) console.log(`  ${l.label}\n    ${l.url}`);
  return out;
}

async function main(): Promise<void> {
  const dryRun = process.argv.includes("--dry-run");
  const cfg = loadConfig();

  const scenarios: Scenario[] = [
    { name: "now, 0 via", intermediates: [], departureOffsetMin: null },
    { name: `now, ${cfg.waypoints.length} via`, intermediates: cfg.waypoints, departureOffsetMin: null },
    { name: "+30 min, 0 via", intermediates: [], departureOffsetMin: 30 },
    { name: `+30 min, ${cfg.waypoints.length} via`, intermediates: cfg.waypoints, departureOffsetMin: 30 },
  ];
  if (scenarios.length > MAX_CALLS) throw new Error("Too many scenarios for the call budget");

  console.log("Navigation links (no API cost):");
  const page = writeNavLinksPage(cfg);
  console.log(`  -> also written to ${page}\n`);

  if (dryRun) {
    for (const s of scenarios) console.log(`[dry-run] ${s.name}\n${JSON.stringify(buildBody(cfg, s), null, 2)}\n`);
    console.log("Dry run: 0 Routes API calls made.");
    return;
  }

  const apiKey = loadApiKey();
  const results: RouteResult[] = [];
  for (const s of scenarios) {
    results.push({ scenario: s.name, ...(await callRoutes(apiKey, buildBody(cfg, s))) });
  }

  console.log(`Routes API, TWO_WHEELER + TRAFFIC_AWARE, ${results.length} calls:`);
  console.table(results.map((r) => ({
    scenario: r.scenario,
    ok: r.ok,
    minutes: r.minutes?.toFixed(1),
    noTrafficMin: r.staticMinutes?.toFixed(1),
    km: r.distanceM !== undefined ? (r.distanceM / 1000).toFixed(2) : undefined,
  })));
  for (const r of results.filter((x) => !x.ok)) console.log(`ERROR ${r.scenario}: ${r.error}`);
  console.log("Gửi bảng trên (và các dòng ERROR nếu có) cho agent. Bạn có thể bỏ tọa độ trước khi gửi.");
}

main().catch((e: unknown) => {
  console.error(e instanceof Error ? e.message : e);
  process.exit(1);
});
