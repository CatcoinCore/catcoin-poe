import asyncio
import httpx
import os
import json
import sys

# Configuration (no default credentials)
BASE_URL = os.getenv("API_URL", "http://localhost:8000").strip()
USERNAME = os.getenv("TEST_USER", "").strip()
PASSWORD = os.getenv("TEST_PASS", "").strip()


async def main():
    if not USERNAME or not PASSWORD:
        print("Set TEST_USER and TEST_PASS for wallet API checks.", file=sys.stderr)
        sys.exit(1)

    print(f"🔍 Testing Wallet Management API at {BASE_URL}")
    print("==============================================")

    async with httpx.AsyncClient(base_url=BASE_URL, timeout=10.0) as client:
        # 1. Login
        print("\n🔑 1. Logging in...")
        try:
            response = await client.post("/token", data={"username": USERNAME, "password": PASSWORD})
            if response.status_code != 200:
                print(f"❌ Login failed: {response.text}")
                # Try creating user if login fails (optional)
                return
            token_data = response.json()
            access_token = token_data["access_token"]
            headers = {"Authorization": f"Bearer {access_token}"}
            print("✅ Login successful")
        except Exception as e:
            print(f"❌ Error during login: {e}")
            return

        # 2. Add Manual Wallet
        print("\n➕ 2. Adding Manual Wallet...")
        manual_wallet_data = {
            "catcoin_address": "CATMANUAL123456789",
            "source": "MANUAL",
            "is_primary": False
        }
        resp = await client.post("/wallets", json=manual_wallet_data, headers=headers)
        if resp.status_code == 200:
            print("✅ Manual Wallet Added:", resp.json()["id"])
            manual_wallet_id = resp.json()["id"]
        else:
            print(f"❌ Failed to add manual wallet: {resp.text}")

        # 3. Add Generated Wallet
        print("\n➕ 3. Adding Generated Wallet...")
        generated_wallet_data = {
            "catcoin_address": "CATGENERATED987654321",
            "source": "GENERATED",
            "is_primary": False
        }
        resp = await client.post("/wallets", json=generated_wallet_data, headers=headers)
        if resp.status_code == 200:
            print("✅ Generated Wallet Added:", resp.json()["id"])
            gen_wallet_id = resp.json()["id"]
        else:
            print(f"❌ Failed to add generated wallet: {resp.text}")

        # 4. List Wallets
        print("\n📜 4. Listing Wallets...")
        resp = await client.get("/wallets", headers=headers)
        if resp.status_code == 200:
            wallets = resp.json()
            print(f"✅ Found {len(wallets)} wallets")
            for w in wallets:
                print(f"   - {w['id']} | {w['catcoin_address']} | {w.get('source')} | Primary: {w.get('is_primary')}")
        else:
            print(f"❌ Failed to list wallets: {resp.text}")

        # 5. Set Primary Wallet
        print(f"\n⭐ 5. Setting Generated Wallet ({gen_wallet_id}) as Primary...")
        resp = await client.put(f"/wallets/{gen_wallet_id}/primary", headers=headers)
        if resp.status_code == 200:
            print("✅ Set Primary Successful")
        else:
            print(f"❌ Failed to set primary: {resp.text}")

        # 6. Verify Primary Change
        print("\n🔍 6. Verifying Primary Status...")
        resp = await client.get("/wallets", headers=headers)
        wallets = resp.json()
        primary_wallet = next((w for w in wallets if w['is_primary']), None)
        if primary_wallet and primary_wallet['id'] == gen_wallet_id:
            print("✅ Correct wallet is primary")
        else:
            print(f"❌ Incorrect primary wallet: {primary_wallet['id'] if primary_wallet else 'None'}")

        # 7. Delete Wallet
        print(f"\n🗑️ 7. Deleting Manual Wallet ({manual_wallet_id})...")
        resp = await client.delete(f"/wallets/{manual_wallet_id}", headers=headers)
        if resp.status_code == 204:
            print("✅ Deletion Successful")
        else:
            print(f"❌ Failed to delete: {resp.text}")

        # Cleaning up
        if 'gen_wallet_id' in locals():
            await client.delete(f"/wallets/{gen_wallet_id}", headers=headers)
            print("🧹 Cleanup: Deleted generated wallet")

if __name__ == "__main__":
    asyncio.run(main())
