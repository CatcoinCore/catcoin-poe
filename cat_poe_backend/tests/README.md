# Test Suite for Daily Ledger Aggregation

Comprehensive test coverage for the session completion and daily ledger aggregation system.

## Setup

### 1. Install Test Dependencies

```bash
pip install -r requirements-test.txt
```

### 2. Create Test Database

```sql
CREATE DATABASE catcoin_poe_test;
```

### 3. Update Test Database URL

Edit `tests/conftest.py` if your test database credentials differ:
```python
TEST_DATABASE_URL = "postgresql+asyncpg://postgres:password@localhost/catcoin_poe_test"
```

## Running Tests

### Run All Tests
```bash
pytest
```

### Run Specific Test File
```bash
pytest tests/test_session_completion.py
```

### Run Specific Test Class
```bash
pytest tests/test_session_completion.py::TestSessionCompletion
```

### Run Specific Test
```bash
pytest tests/test_session_completion.py::TestSessionCompletion::test_complete_expired_session
```

### Run with Coverage
```bash
pytest --cov=. --cov-report=html
```

### Run Verbose
```bash
pytest -v
```

### Run Fast Tests Only (skip integration)
```bash
pytest -m "not integration"
```

## Test Structure

### `conftest.py`
- Test fixtures
- Database setup/teardown
- Test user creation
- Test session creation

### `test_session_completion.py`
- Session completion logic
- Daily ledger aggregation
- Ledger-session mappings
- Balance verification

**Test Classes:**
- `TestSessionCompletion` - Core completion logic
- `TestDailyLedgerAggregation` - Daily aggregation behavior
- `TestLedgerSessionMapping` - Junction table functionality
- `TestBalanceVerification` - Balance accuracy

### `test_integration.py`
- Login session cleanup
- Stats endpoint cleanup
- EarningsManager utilities
- Edge cases and error scenarios

**Test Classes:**
- `TestLoginSessionCleanup` - Login triggers
- `TestStatsSessionCleanup` - Stats fetch triggers
- `TestEarningsManager` - Helper methods
- `TestEdgeCases` - Edge cases

## Test Coverage

### Core Functionality
- ✅ Expired sessions are completed
- ✅ Earnings calculated correctly
- ✅ User balance updated
- ✅ Idempotent completion (no duplicates)
- ✅ Active sessions not completed

### Daily Aggregation
- ✅ Creates daily ledger entries
- ✅ Aggregates multiple sessions
- ✅ Separates BASE and REFERRAL_BOOST
- ✅ Date-based grouping

### Ledger-Session Mapping
- ✅ Creates mapping entries
- ✅ Links to correct ledger
- ✅ Enforces unique constraint

### Balance Verification
- ✅ Balance equals ledger sum
- ✅ Accurate calculations

### Integration
- ✅ Login cleanup
- ✅ Stats cleanup
- ✅ Reward entry creation
- ✅ Withdrawal entry creation
- ✅ Earnings breakdown

### Edge Cases
- ✅ Nonexistent user
- ✅ Zero duration session
- ✅ Concurrent completions

## Expected Test Results

All tests should pass. Example output:

```
================================ test session starts =================================
platform win32 -- Python 3.11.x, pytest-7.x.x, pluggy-1.x.x
collected 20 items

tests/test_session_completion.py::TestSessionCompletion::test_complete_expired_session PASSED
tests/test_session_completion.py::TestSessionCompletion::test_complete_session_calculates_earnings_correctly PASSED
tests/test_session_completion.py::TestSessionCompletion::test_idempotent_completion PASSED
tests/test_session_completion.py::TestSessionCompletion::test_active_sessions_not_completed PASSED
tests/test_session_completion.py::TestDailyLedgerAggregation::test_creates_daily_ledger_entry PASSED
tests/test_session_completion.py::TestDailyLedgerAggregation::test_aggregates_multiple_sessions PASSED
tests/test_session_completion.py::TestDailyLedgerAggregation::test_separate_entries_for_base_and_boost PASSED
tests/test_session_completion.py::TestLedgerSessionMapping::test_creates_mapping_entries PASSED
tests/test_session_completion.py::TestLedgerSessionMapping::test_mapping_links_to_ledger PASSED
tests/test_session_completion.py::TestLedgerSessionMapping::test_session_unique_constraint PASSED
tests/test_session_completion.py::TestBalanceVerification::test_balance_equals_ledger_sum PASSED
tests/test_integration.py::TestEarningsManager::test_create_reward_entry PASSED
tests/test_integration.py::TestEarningsManager::test_create_withdrawal_entry PASSED
tests/test_integration.py::TestEarningsManager::test_calculate_earnings_breakdown PASSED
tests/test_integration.py::TestEdgeCases::test_complete_sessions_for_nonexistent_user PASSED
tests/test_integration.py::TestEdgeCases::test_zero_duration_session PASSED
tests/test_integration.py::TestEdgeCases::test_concurrent_completions PASSED

============================== 20 passed in 5.32s =================================
```

## Continuous Integration

Add to your CI/CD pipeline:

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: password
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        pip install -r requirements-test.txt
    
    - name: Run tests
      run: pytest --cov
```

## Troubleshooting

### Database Connection Issues
- Ensure test database exists: `CREATE DATABASE catcoin_poe_test;`
- Check credentials in `conftest.py`
- Verify PostgreSQL is running

### Import Errors
- Make sure you're in the backend directory
- Install all dependencies: `pip install -r requirements.txt -r requirements-test.txt`

### Async Errors
- Ensure `pytest-asyncio` is installed
- Check `pytest.ini` has `asyncio_mode = auto`

### Test Database Not Clean
- Tests should clean up automatically
- If issues persist, drop and recreate: 
  ```sql
  DROP DATABASE catcoin_poe_test;
  CREATE DATABASE catcoin_poe_test;
  ```
