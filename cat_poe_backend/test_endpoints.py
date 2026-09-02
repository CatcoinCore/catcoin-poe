import asyncio
import aiohttp
import json
import os
import sys

BASE_URL = os.getenv("TEST_API_BASE_URL", "http://127.0.0.1:8000").strip()


async def test_endpoints():
    user = os.getenv("TEST_ADMIN_USER", "").strip()
    password = os.getenv("TEST_ADMIN_PASSWORD", "").strip()
    if not user or not password:
        print(
            "Set TEST_ADMIN_USER and TEST_ADMIN_PASSWORD (no defaults; see CHANGE_SUMMARY.md).",
            file=sys.stderr,
        )
        sys.exit(1)

    async with aiohttp.ClientSession() as session:
        # 1. Login as admin (same account you use in production / staging)
        print("\n--- 1. Login as admin ---")
        login_data = {"username": user, "password": password}
        async with session.post(f"{BASE_URL}/auth/login", data=login_data) as resp:
            if resp.status != 200:
                print(f"Login failed: {await resp.text()}")
                return
            token_data = await resp.json()
            access_token = token_data["access_token"]
            headers = {"Authorization": f"Bearer {access_token}"}
            print("Login successful.")

        # 2. Test Admin Config
        print("\n--- 2. Test Admin Config ---")
        async with session.get(f"{BASE_URL}/v1/config/") as resp:
            print(f"GET /v1/config/ status: {resp.status}")
            print(await resp.json())

        # 3. Test Admin Missions (CRUD)
        print("\n--- 3. Test Admin Missions ---")
        # Create
        new_mission = {
            "code": "TEST_MISSION",
            "title": "Test Mission",
            "description": "This is a test.",
            "type": "OTHER",
            "reward_amount": 5.0,
            "is_active": True
        }
        async with session.post(f"{BASE_URL}/v1/admin/missions/", json=new_mission, headers=headers) as resp:
            print(f"POST /v1/admin/missions/ status: {resp.status}")
            if resp.status == 200:
                print("Created mission.")
            else:
                print(await resp.text())

        # List
        async with session.get(f"{BASE_URL}/v1/admin/missions/", headers=headers) as resp:
            print(f"GET /v1/admin/missions/ status: {resp.status}")
            missions = await resp.json()
            print(f"Found {len(missions)} missions.")

        # Delete
        async with session.delete(f"{BASE_URL}/v1/admin/missions/TEST_MISSION", headers=headers) as resp:
            print(f"DELETE /v1/admin/missions/TEST_MISSION status: {resp.status}")

        # 4. Test Payout History
        print("\n--- 4. Test Payout History ---")
        async with session.get(f"{BASE_URL}/v1/payouts/", headers=headers) as resp:
            print(f"GET /v1/payouts/ status: {resp.status}")
            payouts = await resp.json()
            print(f"Found {len(payouts)} payouts.")

if __name__ == "__main__":
    asyncio.run(test_endpoints())
