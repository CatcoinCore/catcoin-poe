"""Resolve localized snippets stored on admin_config (announcements, what's new)."""
from __future__ import annotations

from typing import Any, Dict, List, Optional

# Mirrors cat_poe AppLocalizations.supportedLocales (language code only).
APP_SUPPORTED_LANGUAGE_CODES: frozenset[str] = frozenset(
    {
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
    }
)


def normalize_language_code(lang: Optional[str]) -> str:
    if not lang:
        return "en"
    code = str(lang).strip().split("-")[0].split("_")[0].lower()
    if code in APP_SUPPORTED_LANGUAGE_CODES:
        return code
    return "en"


def _dig_str_map(raw: Any) -> Dict[str, str]:
    """Coerce SQLAlchemy / JSONB / dict payloads to str->str."""
    if raw is None:
        return {}
    if isinstance(raw, dict):
        out: Dict[str, str] = {}
        for k, v in raw.items():
            if k is None:
                continue
            key = str(k).strip().split("-")[0].split("_")[0].lower()
            if v is None:
                continue
            s = str(v).strip()
            if s != "":
                out[key] = v if isinstance(v, str) else s
        return out
    return {}


def resolved_global_push_message(
    *,
    legacy_column: Optional[str],
    messages_by_lang: Any,
    lang: str,
) -> Optional[str]:
    """Announcement markdown for UI: prefer localized map, then legacy VARCHAR (treated as en)."""
    want = normalize_language_code(lang)
    m = _dig_str_map(messages_by_lang)

    cand: Optional[str] = None
    if m:
        cand = m.get(want) or m.get("en")
        if cand is None:
            cand = next(iter(m.values()))
    if cand is not None and str(cand).strip():
        return str(cand)

    lv = legacy_column if isinstance(legacy_column, str) else None
    if lv is not None and lv.strip():
        return lv

    return None


def _block_from_translations_leaf(raw: Any) -> tuple[str, List[str]]:
    if not isinstance(raw, dict):
        return "", []
    dl = raw.get("date_label")
    date_label = str(dl).strip() if dl is not None else ""
    notes_raw = raw.get("notes")
    notes: List[str] = []
    if isinstance(notes_raw, list):
        for n in notes_raw:
            if n is None:
                continue
            s = str(n).strip()
            if s:
                notes.append(str(n))
    return date_label, notes


def resolved_whats_new_entry(entry: Dict[str, Any], lang: str) -> tuple[str, str, List[str]]:
    """
    Stored row is either legacy {version, date_label, notes[]}
    or {version, translations: {LANG: {date_label, notes}}}.
    Fallback order: wanted lang -> en -> first available translation -> legacy body.
    """
    want = normalize_language_code(lang)
    version_raw = entry.get("version")
    version = str(version_raw) if version_raw is not None else ""

    translations = entry.get("translations")
    if isinstance(translations, dict):
        order = [want, "en"]
        seen: List[str] = []
        blocks: Dict[str, tuple[str, List[str]]] = {}
        for lk, blk in translations.items():
            if lk is None:
                continue
            k = str(lk).strip().split("-")[0].split("_")[0].lower()
            if k not in blocks:
                blocks[k] = _block_from_translations_leaf(blk)
        for k in order:
            if k in blocks:
                dl, nt = blocks[k]
                if dl or nt:
                    return version, dl, nt
        for _k, tup in sorted(blocks.items()):
            dl, nt = tup
            if dl or nt:
                return version, dl, nt

    legacy_notes = entry.get("notes")
    dl0 = entry.get("date_label")
    date_label = str(dl0).strip() if dl0 is not None else ""
    notes: List[str] = []
    if isinstance(legacy_notes, list):
        for n in legacy_notes:
            if n is None:
                continue
            s = str(n).strip()
            if s:
                notes.append(str(n))
    return version, date_label, notes


def whats_new_public_rows(raw_list: Any, lang: str) -> List[dict[str, Any]]:
    """List of resolved dicts for WhatsNewReleaseItem serialization."""
    if not isinstance(raw_list, list):
        return []
    out: List[dict[str, Any]] = []
    for item in raw_list:
        if not isinstance(item, dict):
            continue
        v, d, n = resolved_whats_new_entry(item, lang)
        out.append({"version": v, "date_label": d, "notes": n})
    return out
