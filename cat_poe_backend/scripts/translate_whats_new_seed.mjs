/**
 * Rewrite seed_data/default_whats_new.json: fill every locale from translations.en
 * via Google Translate (unofficial translate.googleapis.com helper used by browsers).
 *
 * Uses only Node builtins (no npm). Deduplicates strings across releases.
 *
 * Usage (from repo root or cat_poe_backend):
 *   node cat_poe_backend/scripts/translate_whats_new_seed.mjs
 *   node cat_poe_backend/scripts/translate_whats_new_seed.mjs --dry-run
 *
 * Outputs are machine translations — proofread sensitive release notes before shipping.
 */

import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");
const SEED_JSON = path.join(ROOT, "seed_data", "default_whats_new.json");

/** App locale codes -> Google `tl=` subtag */
const GTX_TL_BY_APP = {
  ar: "ar",
  es: "es",
  fr: "fr",
  gu: "gu",
  hi: "hi",
  id: "id",
  ja: "ja",
  ko: "ko",
  ms: "ms",
  or: "or",
  ru: "ru",
  ta: "ta",
  te: "te",
  vi: "vi",
  zh: "zh-CN",
};

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function collectUniqueEn(rows) {
  const set = new Set();
  for (const r of rows) {
    const en = r?.translations?.en;
    if (!en) continue;
    const dl = String(en.date_label ?? "").trim();
    if (dl) set.add(dl);
    for (const note of en.notes ?? []) {
      const s = String(note ?? "").trim();
      if (s) set.add(s);
    }
  }
  return [...set].sort();
}

async function gtxTranslate(text, tl) {
  const u =
    "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=" +
    encodeURIComponent(tl) +
    "&dt=t&q=" +
    encodeURIComponent(text);
  const res = await fetch(u, {
    headers: {
      "User-Agent": "Mozilla/5.0 (compatible; whats-new-i18n/1.0)",
    },
  });
  if (!res.ok) {
    throw new Error(`HTTP ${res.status}`);
  }
  const data = await res.json();
  if (!data?.[0]) return text;
  return data[0].map((part) => (Array.isArray(part) ? part[0] : "")).join("");
}

async function buildMap(uniqueTexts, appLangCodes, sleepMs, verbose) {
  /** english -> lang -> translated */
  const cmap = new Map(uniqueTexts.map((t) => [t, new Map([["en", t]])]));
  let n = 0;
  const total = uniqueTexts.length * appLangCodes.length;

  for (const app of [...appLangCodes].sort()) {
    const tl = GTX_TL_BY_APP[app];
    if (!tl) {
      console.warn("Skipping unknown locale code:", app);
      continue;
    }
    for (const text of uniqueTexts) {
      let out = text;
      for (let attempt = 1; attempt <= 4; attempt++) {
        try {
          out = await gtxTranslate(text, tl);
          break;
        } catch (e) {
          if (attempt === 4) {
            console.warn(
              "[warn] translate failed",
              app,
              text.slice(0, 52),
              String(e?.message ?? e),
            );
            out = text;
          } else {
            await sleep(400 * attempt);
          }
        }
      }
      cmap.get(text).set(app, out);
      n++;
      if (verbose && n % 50 === 0) console.error("...", n, "/", total);
      await sleep(Math.max(0, sleepMs));
    }
  }
  return cmap;
}

function applyMap(rows, cmap) {
  for (const r of rows) {
    const tr = r.translations;
    if (!tr || typeof tr !== "object") continue;

    const en = tr.en ?? {};
    const enDate = String(en.date_label ?? "").trim();
    const enNotes = (en.notes ?? [])
      .map((x) => String(x ?? "").trim())
      .filter(Boolean);

    tr.en = { date_label: enDate, notes: [...enNotes] };

    for (const appLang of Object.keys(tr)) {
      if (appLang === "en") continue;
      const tlDate = cmap.get(enDate)?.get(appLang) ?? enDate;
      const tnotes = enNotes.map((n) => cmap.get(n)?.get(appLang) ?? n);

      const prev =
        typeof tr[appLang] === "object" && tr[appLang] !== null ? tr[appLang] : {};
      tr[appLang] = Object.assign(prev, {
        date_label: tlDate,
        notes: tnotes,
      });
    }
  }
}

async function main() {
  const dryRun = process.argv.includes("--dry-run");
  const verbose = process.argv.includes("-v");
  const sleepMs = Number(
    (/--sleep-ms=(\d+)/.exec(process.argv.join(" ")) || [])[1] ?? "100",
  );

  const raw = await fs.readFile(SEED_JSON, "utf8");
  const rows = JSON.parse(raw);
  const uniq = collectUniqueEn(rows);
  const targets = Object.keys(GTX_TL_BY_APP);
  console.log(
    JSON.stringify({
      seed: SEED_JSON,
      releases: rows.length,
      uniqueStrings: uniq.length,
      targets: targets.length,
      translatorCallsApprox: uniq.length * targets.length,
      dryRun,
    }),
  );
  if (dryRun) {
    for (const s of uniq.slice(0, 30)) console.log(s);
    if (uniq.length > 30) console.log("… plus", uniq.length - 30, "lines");
    return;
  }

  const bak = `${SEED_JSON}.bak`;
  await fs.copyFile(SEED_JSON, bak);
  console.log("Backup:", bak);

  const cmap = await buildMap(uniq, targets, sleepMs, verbose);
  applyMap(rows, cmap);

  const tmp = `${SEED_JSON}.tmp`;
  await fs.writeFile(tmp, JSON.stringify(rows, null, 2) + "\n", "utf8");
  await fs.rename(tmp, SEED_JSON);
  console.log("Wrote:", SEED_JSON);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
