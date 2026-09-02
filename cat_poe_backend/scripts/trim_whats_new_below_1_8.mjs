import fs from "node:fs";

const p = new URL("../seed_data/default_whats_new.json", import.meta.url);
const rows = JSON.parse(fs.readFileSync(p, "utf8"));

function parseSemver(label) {
  const m = /Version\s+(\d+)\.(\d+)\.(\d+)/.exec(label || "");
  return m ? [Number(m[1]), Number(m[2]), Number(m[3])] : null;
}

function gte(a, b) {
  for (let i = 0; i < 3; i++) {
    if (a[i] > b[i]) return true;
    if (a[i] < b[i]) return false;
  }
  return true;
}

const floor = parseSemver("Version 1.8.0");
const filtered = rows.filter((r) => {
  const v = parseSemver(r.version);
  return v && gte(v, floor);
});

fs.writeFileSync(p, JSON.stringify(filtered, null, 2) + "\n", "utf8");
console.log(`${rows.length} -> ${filtered.length} (kept >= 1.8.0)`);
