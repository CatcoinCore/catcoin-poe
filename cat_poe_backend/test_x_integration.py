import asyncio
import os
import httpx
from dotenv import load_dotenv

# Load env
load_dotenv()

BEARER_TOKEN = os.getenv("X_BEARER_TOKEN")
COMMUNITY_USERNAME = os.getenv("X_COMMUNITY_USERNAME")

print(f"Loaded Config:")
print(f"  Bearer Token: {BEARER_TOKEN[:10]}..." if BEARER_TOKEN else "  Bearer Token: MISSING")
print(f"  Community User: {COMMUNITY_USERNAME}")

if not BEARER_TOKEN:
    print("❌ Error: Missing Bearer Token")
    exit(1)

HEADERS = {
    "Authorization": f"Bearer {BEARER_TOKEN}",
    "Content-Type": "application/json"
}

async def test_user_lookup(username):
    print(f"\n🔍 Testing User Lookup for: {username}")
    url = f"https://api.twitter.com/2/users/by/username/{username}"
    
    async with httpx.AsyncClient() as client:
        resp = await client.get(url, headers=HEADERS)
        if resp.status_code == 200:
            data = resp.json()
            user_id = data.get("data", {}).get("id")
            print(f"✅ User Found: ID={user_id}, Name={data.get('data', {}).get('name')}")
            return user_id, data
        else:
            print(f"❌ User Lookup Failed: {resp.status_code} - {resp.text}")
            return None, None

async def test_community_lookup():
    # Attempt to lookup a user following the owner as a proxy for verification
    # Since we can't easily check 'community membership' purely via API without User Context in some cases,
    # we verify the 'Follow' logic which is our current implementation.
    
    owner_username = os.getenv("X_TEST_OWNER_USERNAME", "YOUR_X_USERNAME")
    # Example applicant — high-follower account to test the negative case (unlikely to follow owner_username)
    # And we can try to find a user who DOES follow if possible, or just verify the API calls work.
    applicant_username = "ElonMusk" 
    
    print(f"\n🧪 Testing Logic: Does '{applicant_username}' follow '{owner_username}'?")
    
    # 1. Get IDs
    owner_id, _ = await test_user_lookup(owner_username)
    applicant_id, _ = await test_user_lookup(applicant_username)
    
    if not owner_id or not applicant_id:
        print("❌ Skipping Follow Check due to lookup failure.")
        return

    # 2. Check Following of Applicant
    url = f"https://api.twitter.com/2/users/{applicant_id}/following"
    params = {"max_results": 10} # Check first 10 for verified check (likely false)
    
    print(f"  Checking {url}...")
    
    async with httpx.AsyncClient() as client:
        resp = await client.get(url, headers=HEADERS, params=params)
        
        if resp.status_code == 200:
            data = resp.json()
            follows = data.get("data", [])
            print(f"  Fetched {len(follows)} following accounts.")
            
            is_following = any(u["id"] == owner_id for u in follows)
            if is_following:
                print(f"✅ RESULT: {applicant_username} FOLLOWS {owner_username}")
            else:
                print(f"ℹ️ RESULT: {applicant_username} DOES NOT follow {owner_username} (in first 10 results)")
        else:
            print(f"❌ Follow Check Failed: {resp.status_code} - {resp.text}")

async def main():
    print("🚀 Starting X API Integration Test")
    
    # 1. Verify Owner Exists
    if COMMUNITY_USERNAME:
        await test_user_lookup(COMMUNITY_USERNAME)
    else:
        print("⚠️ No X_COMMUNITY_USERNAME configured.")
        
    # 2. Run logic test
    await test_community_lookup()
    
    # 3. Test Retweet Logic (Static Test with random tweet)
    # We can't verify retweet easily without a known retweeter.
    # But we can verify the endpoint is accessible.
    print("\n🔍 Testing Retweet Endpoint Access (Dry Run)")
    # Using a random tweet ID (e.g. from X official account) to see if we have access
    # Tweet: https://x.com/X/status/1888278496464732646 (Example)
    # Let's use a recent Tweet ID from Elon or X to check if we can read retweets.
    # Actually let's use a very old famous tweet. Jack's first tweet? 20.
    test_tweet_id = "20" 
    url = f"https://api.twitter.com/2/tweets/{test_tweet_id}/retweeted_by"
    
    async with httpx.AsyncClient() as client:
        resp = await client.get(url, headers=HEADERS)
        if resp.status_code == 200:
             print(f"✅ Retweet Endpoint Access: OK ({len(resp.json().get('data', []))} retweeters fetched)")
        else:
             print(f"❌ Retweet Endpoint Failed: {resp.status_code} - {resp.text}")

if __name__ == "__main__":
    asyncio.run(main())
