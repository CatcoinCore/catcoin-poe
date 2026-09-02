"""Server-side time boost slot state: random session slots, cooldowns, reconciliation."""
from __future__ import annotations

import json
import random
from datetime import datetime
from typing import Any, Dict, List, Optional

DEFAULT_EXTENSION_MINUTES = [120, 180, 240, 300, 360]


def extension_minutes_from_config(time_extension_slots_json: Optional[str]) -> List[int]:
    if not time_extension_slots_json:
        return list(DEFAULT_EXTENSION_MINUTES)
    try:
        parsed = json.loads(time_extension_slots_json)
        if isinstance(parsed, list) and parsed:
            return [int(x) for x in parsed]
    except (json.JSONDecodeError, TypeError, ValueError):
        pass
    return list(DEFAULT_EXTENSION_MINUTES)


def extension_hours_sorted(minutes_list: List[int]) -> List[int]:
    return sorted({m // 60 for m in minutes_list if m > 0})


def new_random_slots_state(extension_minutes: List[int]) -> Dict[str, Any]:
    """Exactly two random distinct hour values from configured extension slots (when possible)."""
    hours_sorted = extension_hours_sorted(extension_minutes)
    if len(hours_sorted) >= 2:
        slots = random.sample(hours_sorted, 2)
    elif len(hours_sorted) == 1:
        slots = [hours_sorted[0], hours_sorted[0]]
    else:
        slots = [2, 3]
    return {"slots": slots, "cooldowns": {}, "inactive_hours": []}


def load_state(raw: Optional[str]) -> Optional[Dict[str, Any]]:
    if not raw:
        return None
    try:
        d = json.loads(raw)
        if not isinstance(d, dict):
            return None
        return d
    except (json.JSONDecodeError, TypeError):
        return None


def dump_state(state: Dict[str, Any]) -> str:
    return json.dumps(state, separators=(",", ":"), sort_keys=True)


def parse_iso_utc_naive(s: str) -> datetime:
    s = s.replace("Z", "+00:00")
    dt = datetime.fromisoformat(s)
    if dt.tzinfo is not None:
        dt = dt.replace(tzinfo=None)
    return dt


def prune_cooldowns(cooldowns: Dict[str, str], now: datetime) -> Dict[str, str]:
    out: Dict[str, str] = {}
    for k, iso in cooldowns.items():
        try:
            end = parse_iso_utc_naive(iso)
            if end > now:
                out[k] = iso
        except (ValueError, TypeError):
            continue
    return out


def reconcile_time_boost_state(
    state: Dict[str, Any],
    remaining_minutes: int,
    extension_minutes: List[int],
    now: datetime,
) -> Dict[str, Any]:
    """
    Apply cooldown expiry, session max, scenario 3 (drop oversized boosters when a smaller
    slot still fills remaining headroom), and scenario 4 (replace both boosters when none fit).
    """
    state = {
        "slots": [int(x) for x in (state.get("slots") or [])],
        "cooldowns": dict(state.get("cooldowns") or {}),
        "inactive_hours": [int(x) for x in (state.get("inactive_hours") or [])],
    }
    state["cooldowns"] = prune_cooldowns(state["cooldowns"], now)
    slots = state["slots"]

    if remaining_minutes <= 0:
        state["inactive_hours"] = sorted(set(slots))
        return state

    # Scenario 4: no slot fits in remaining time. Wait until every current slot is off cooldown,
    # then replace with the smallest configured extension >= remaining. While waiting, oversized
    # slots that are already off cooldown are inactive so the user cannot partially extend before
    # the lineup switches to a fitting booster.
    if slots and all(h * 60 > remaining_minutes for h in slots):
        waiting_on_cd = any(str(h) in state["cooldowns"] for h in slots)
        if waiting_on_cd:
            off_cd_oversized = [
                h for h in slots if str(h) not in state["cooldowns"]
            ]
            state["inactive_hours"] = sorted(set(off_cd_oversized))
            return state
        fitting = [m for m in extension_minutes if m >= remaining_minutes]
        if fitting:
            chosen_m = min(fitting)
            new_h = chosen_m // 60
            state["slots"] = [new_h]
            state["cooldowns"] = {}
            state["inactive_hours"] = []
        return state

    # Scenario 3: at least one slot fits remaining; oversized slots are inactive (not offered).
    has_fit = any(h * 60 <= remaining_minutes for h in slots)
    if has_fit:
        inactive = {h for h in slots if h * 60 > remaining_minutes}
        state["inactive_hours"] = sorted(inactive)
    else:
        state["inactive_hours"] = []

    return state
