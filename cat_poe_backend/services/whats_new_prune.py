"""Trim stored What's New payloads by minimum semver (e.g. drop pre-1.8.0)."""
from __future__ import annotations

import re
from typing import Any, List, Tuple

_VERSION_RE = re.compile(r"(?:Version\s+)?(\d+)\.(\d+)\.(\d+)")

WhatsNewFloor = Tuple[int, int, int]


def extract_semver(version_label: Any) -> Tuple[int, int, int] | None:
    if version_label is None:
        return None
    m = _VERSION_RE.search(str(version_label).strip())
    if not m:
        return None
    return int(m[1]), int(m[2]), int(m[3])


def semver_gte(v: Tuple[int, int, int], floor: WhatsNewFloor) -> bool:
    for a, b in zip(v, floor):
        if a > b:
            return True
        if a < b:
            return False
    return True


def prune_whats_new_below(
    raw: Any,
    floor: WhatsNewFloor = (1, 8, 0),
) -> List[Any]:
    """
    Preserve list order (newest first). Entries without a parseable version are kept.
    """
    if not isinstance(raw, list):
        return []
    out: List[Any] = []
    for item in raw:
        if not isinstance(item, dict):
            continue
        label = item.get("version")
        parsed = extract_semver(label)
        if parsed is None:
            out.append(item)
            continue
        if semver_gte(parsed, floor):
            out.append(item)
    return out


DEFAULT_WHATS_NEW_MIN_VERSION: WhatsNewFloor = (1, 8, 0)
