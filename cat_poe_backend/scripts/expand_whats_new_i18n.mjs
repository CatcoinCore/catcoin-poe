/**
 * Rewrites whats_new_json seed: each release uses translations.{lang}.{date_label,notes}.
 * Copies English bodies into every supported app language until you replace with real translations.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const LANGS = [
  "ar",
  "en",
  "es",
  "fr",
  "gu",
  "hi",
  "id",
  "ja",
  "ko",
  "ms",
  "or",
  "ru",
  "ta",
  "te",
  "vi",
  "zh",
];

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const jsonPath = path.join(__dirname, "..", "seed_data", "default_whats_new.json");

const rows = JSON.parse(fs.readFileSync(jsonPath, "utf8"));
if (!Array.isArray(rows)) throw new Error("Expected array");

for (const r of rows) {
  const enBlock = r.translations?.en
    ? { ...r.translations.en }
    : { date_label: r.date_label ?? "", notes: Array.isArray(r.notes) ? [...r.notes] : [] };
  const translations = {};
  for (const l of LANGS) {
    translations[l] = {
      date_label: enBlock.date_label ?? "",
      notes: Array.isArray(enBlock.notes) ? [...enBlock.notes] : [],
    };
  }
  delete r.date_label;
  delete r.notes;
  r.translations = translations;
}

fs.writeFileSync(jsonPath, JSON.stringify(rows, null, 2) + "\n", "utf8");
console.log("Wrote", rows.length, "releases to", jsonPath);
