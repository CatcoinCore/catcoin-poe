"""Unit tests for time boost slot reconciliation."""
from datetime import datetime, timedelta

import pytest

from services import time_boost_state as tbs


def _now():
    return datetime(2026, 4, 14, 12, 0, 0)


@pytest.mark.parametrize(
    "remaining,slots,ext_mins,expect_slots,expect_inactive",
    [
        # Scenario 3: 19h used, 5h headroom — keep 5h usable, mark 6h inactive
        (300, [5, 6], [120, 180, 240, 300, 360], [5, 6], [6]),
        # Scenario 4: 22h used, 2h headroom — replace with single 2h slot
        (120, [5, 3], [120, 180, 240, 300, 360], [2], []),
        # Both fit — no inactive
        (400, [5, 6], [120, 180, 240, 300, 360], [5, 6], []),
        # Maxed — all inactive
        (0, [5, 6], [120, 180, 240, 300, 360], [5, 6], [5, 6]),
    ],
)
def test_reconcile_scenarios(remaining, slots, ext_mins, expect_slots, expect_inactive):
    state = {"slots": list(slots), "cooldowns": {}, "inactive_hours": []}
    out = tbs.reconcile_time_boost_state(state, remaining, ext_mins, _now())
    assert out["slots"] == expect_slots
    assert sorted(out["inactive_hours"]) == sorted(expect_inactive)


def test_scenario4_inactivates_off_cooldown_while_waiting():
    state = {
        "slots": [5, 3],
        "cooldowns": {"5": "2099-01-01T00:00:00"},
        "inactive_hours": [],
    }
    out = tbs.reconcile_time_boost_state(state, 120, [120, 180, 240, 300, 360], _now())
    assert out["slots"] == [5, 3]
    assert out["inactive_hours"] == [3]


def test_scenario4_replaces_after_all_cooldowns_cleared():
    state = {
        "slots": [5, 3],
        "cooldowns": {},
        "inactive_hours": [],
    }
    out = tbs.reconcile_time_boost_state(state, 120, [120, 180, 240, 300, 360], _now())
    assert out["slots"] == [2]
    assert out["cooldowns"] == {}


def test_prune_cooldowns():
    now = _now()
    past = (now - timedelta(hours=1)).isoformat()
    future = (now + timedelta(hours=1)).isoformat()
    pruned = tbs.prune_cooldowns({"3": past, "5": future}, now)
    assert pruned == {"5": future}


def test_new_random_slots_two_distinct_when_possible():
    ext = [120, 180, 240, 300, 360]
    seen = set()
    for _ in range(50):
        st = tbs.new_random_slots_state(ext)
        assert len(st["slots"]) == 2
        seen.add(tuple(sorted(st["slots"])))
    # High probability we saw at least two different pairs
    assert len(seen) >= 2
