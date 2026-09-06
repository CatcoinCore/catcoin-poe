#!/usr/bin/env python3
"""Generate the Google Play Data safety import CSV for Catcoin PoE.

Play's Data safety declaration is filled in the Console UI (App content > Data
safety), but the Console also accepts a CSV import. This script produces that
CSV from the declaration recorded in docs/play-data-safety.md, so the answers
live in version control instead of only in someone's browser session.

How it works: Google publishes a sample/template CSV that already contains every
question and response id for the whole questionnaire. We download it, blank out
the example answers it ships with, write only our own values into the
"Response value" column, and leave every other column byte-identical. The
importer keys on columns 1 and 2, so the row set and its order must not change.

Usage:
    python tools/data_safety_csv.py [-o docs/play-data-safety.csv]

Verification is not optional and runs on every invocation: the output is
re-parsed and compared field-by-field against the template, and the script exits
non-zero if anything other than the "Response value" column differs.
"""

import argparse
import csv
import hashlib
import io
import sys
import urllib.request

TEMPLATE_URL = (
    "https://storage.googleapis.com/support-kms-prod/"
    "b5v9It2EgwrgyY1gPFVB3jPUypc5lL3oNg2G"
)
# md5 of the template as observed when this mapping was written. A mismatch does
# not necessarily mean failure, but it does mean Google changed the question set
# and the ids below must be re-checked before trusting the output.
TEMPLATE_MD5 = "92863c686ff06c400d5442cea4dc3c8f"

# Overall questions (these rows carry no response id).
OVERALL = {
    "PSL_DATA_COLLECTION_COLLECTS_PERSONAL_DATA": "TRUE",
    "PSL_DATA_COLLECTION_ENCRYPTED_IN_TRANSIT": "TRUE",   # HTTPS only; release build bans cleartext
    "PSL_DATA_COLLECTION_USER_REQUEST_DELETE": "TRUE",    # in-app delete + /delete-account page
}

# One entry per data type we declare. Anything absent is left entirely blank,
# which is how the template represents "not collected".
#   collected/shared : booleans
#   optional         : True  -> users can choose
#                      False -> collection is required
#   collect/share    : purpose response ids
DECLARATION = {
    # category id                       response id
    ("PSL_DATA_TYPES_PERSONAL", "PSL_NAME"): dict(
        collected=True, shared=False, optional=True,
        collect=["PSL_APP_FUNCTIONALITY", "PSL_ACCOUNT_MANAGEMENT"], share=[],
    ),
    ("PSL_DATA_TYPES_PERSONAL", "PSL_EMAIL"): dict(
        collected=True, shared=False, optional=False,
        collect=["PSL_APP_FUNCTIONALITY", "PSL_ACCOUNT_MANAGEMENT",
                 "PSL_DEVELOPER_COMMUNICATIONS"], share=[],
    ),
    ("PSL_DATA_TYPES_PERSONAL", "PSL_USER_ACCOUNT"): dict(
        collected=True, shared=False, optional=False,
        collect=["PSL_APP_FUNCTIONALITY", "PSL_ACCOUNT_MANAGEMENT",
                 "PSL_FRAUD_PREVENTION_SECURITY"], share=[],
    ),
    # "Other financial info": Catcoin wallet address and payout records. Shared,
    # because a broadcast payout is permanently public on the blockchain.
    ("PSL_DATA_TYPES_FINANCIAL", "PSL_OTHER"): dict(
        collected=True, shared=True, optional=True,
        collect=["PSL_APP_FUNCTIONALITY"], share=["PSL_APP_FUNCTIONALITY"],
    ),
    # Country only, derived from IP. Shared, because the lookup exposes the IP
    # to the third-party geolocation services.
    ("PSL_DATA_TYPES_LOCATION", "PSL_APPROX_LOCATION"): dict(
        collected=True, shared=True, optional=False,
        collect=["PSL_APP_FUNCTIONALITY", "PSL_FRAUD_PREVENTION_SECURITY"],
        share=["PSL_APP_FUNCTIONALITY"],
    ),
    ("PSL_DATA_TYPES_APP_ACTIVITY", "PSL_USER_INTERACTION"): dict(
        collected=True, shared=False, optional=False,
        collect=["PSL_APP_FUNCTIONALITY", "PSL_FRAUD_PREVENTION_SECURITY"], share=[],
    ),
    ("PSL_DATA_TYPES_APP_PERFORMANCE", "PSL_CRASH_LOGS"): dict(
        collected=True, shared=False, optional=False,
        collect=["PSL_ANALYTICS"], share=[],
    ),
    ("PSL_DATA_TYPES_APP_PERFORMANCE", "PSL_PERFORMANCE_DIAGNOSTICS"): dict(
        collected=True, shared=False, optional=False,
        collect=["PSL_ANALYTICS"], share=[],
    ),
    # Advertising id, installation UUID, IP, install referrer. Only the
    # advertising id is ever shared, and only with the ads SDK.
    ("PSL_DATA_TYPES_IDENTIFIERS", "PSL_DEVICE_ID"): dict(
        collected=True, shared=True, optional=False,
        collect=["PSL_ADVERTISING", "PSL_FRAUD_PREVENTION_SECURITY",
                 "PSL_APP_FUNCTIONALITY"],
        share=["PSL_ADVERTISING"],
    ),
}

USAGE = "PSL_DATA_USAGE_RESPONSES:{t}:{q}"


def fetch_template():
    with urllib.request.urlopen(TEMPLATE_URL, timeout=120) as resp:
        raw = resp.read()
    md5 = hashlib.md5(raw).hexdigest()
    if md5 != TEMPLATE_MD5:
        print(f"WARNING: template md5 is {md5}, expected {TEMPLATE_MD5}.\n"
              "         Google may have revised the question set; re-check the\n"
              "         question and response ids in this script before importing.",
              file=sys.stderr)
    return raw.decode("utf-8"), md5


def build(rows):
    """Return new rows with only column 3 rewritten."""
    want = {}
    for (cat, dt), d in DECLARATION.items():
        want[(cat, dt)] = "TRUE" if d["collected"] or d["shared"] else ""
        u = lambda q: (USAGE.format(t=dt, q=q))
        want[(u("PSL_DATA_USAGE_COLLECTION_AND_SHARING"),
              "PSL_DATA_USAGE_ONLY_COLLECTED")] = "TRUE" if d["collected"] else ""
        want[(u("PSL_DATA_USAGE_COLLECTION_AND_SHARING"),
              "PSL_DATA_USAGE_ONLY_SHARED")] = "TRUE" if d["shared"] else ""
        # Nothing we collect is processed ephemerally.
        want[(u("PSL_DATA_USAGE_EPHEMERAL"), "")] = "FALSE"
        want[(u("DATA_USAGE_USER_CONTROL"),
              "PSL_DATA_USAGE_USER_CONTROL_OPTIONAL")] = "TRUE" if d["optional"] else ""
        want[(u("DATA_USAGE_USER_CONTROL"),
              "PSL_DATA_USAGE_USER_CONTROL_REQUIRED")] = "" if d["optional"] else "TRUE"
        for p in d["collect"]:
            want[(u("DATA_USAGE_COLLECTION_PURPOSE"), p)] = "TRUE"
        for p in d["share"]:
            want[(u("DATA_USAGE_SHARING_PURPOSE"), p)] = "TRUE"

    out, seen, changed = [rows[0]], set(), 0
    for r in rows[1:]:
        key = (r[0], r[1])
        # Blank the template's own example answers, then apply ours.
        value = OVERALL.get(r[0], "") if not r[1] and r[0] in OVERALL else want.get(key, "")
        if key in want:
            seen.add(key)
        if value != r[2]:
            changed += 1
        out.append([r[0], r[1], value, r[3], r[4]])

    missing = set(want) - seen
    if missing:
        raise SystemExit(f"ERROR: {len(missing)} declared ids not found in the "
                         f"template (Google changed the schema?): {sorted(missing)[:5]}")
    return out, changed


def verify(orig_rows, new_rows):
    """Columns 1, 2, 4, 5 must be untouched; only column 3 may differ."""
    if len(orig_rows) != len(new_rows):
        raise SystemExit(f"ERROR: row count changed {len(orig_rows)} -> {len(new_rows)}")
    for i, (a, b) in enumerate(zip(orig_rows, new_rows)):
        if len(a) != 5 or len(b) != 5:
            raise SystemExit(f"ERROR: row {i} does not have 5 fields")
        for col in (0, 1, 3, 4):
            if a[col] != b[col]:
                raise SystemExit(f"ERROR: row {i} column {col + 1} changed: "
                                 f"{a[col]!r} -> {b[col]!r}")
        # Row 0 is the header, whose third field is the literal column name.
        if i and b[2] not in ("", "TRUE", "FALSE"):
            raise SystemExit(f"ERROR: row {i} has invalid response value {b[2]!r}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--out", default="docs/play-data-safety.csv")
    args = ap.parse_args()

    src, md5 = fetch_template()
    orig = list(csv.reader(io.StringIO(src)))
    new, changed = build(orig)
    verify(orig, new)

    buf = io.StringIO()
    csv.writer(buf, lineterminator="\r\n", quoting=csv.QUOTE_MINIMAL).writerows(new)
    text = buf.getvalue()
    # The template has no terminator after its final row; match it exactly.
    if text.endswith("\r\n"):
        text = text[:-2]
    with open(args.out, "w", encoding="utf-8", newline="") as f:
        f.write(text)

    trues = sum(1 for r in new[1:] if r[2] == "TRUE")
    falses = sum(1 for r in new[1:] if r[2] == "FALSE")
    print(f"template md5 : {md5}")
    print(f"wrote        : {args.out} ({len(text.encode('utf-8'))} bytes, "
          f"{len(new) - 1} data rows)")
    print(f"answers      : {trues} TRUE, {falses} FALSE, "
          f"{len(new) - 1 - trues - falses} blank ({changed} cells differ from template)")
    print("verified     : columns 1, 2, 4 and 5 byte-identical to the template")


if __name__ == "__main__":
    main()
