import asyncio
import httpx

async def main():
    target_id = "catcoins"
    url = f"https://api.coingecko.com/api/v3/simple/price?ids={target_id}&vs_currencies=usd"
    headers = {"User-Agent": "CatcoinPoE/1.0"}
    
    print(f"Fetching: {url}")
    try:
        async with httpx.AsyncClient(timeout=10.0, headers=headers) as client:
            response = await client.get(url)
            print(f"Status Code: {response.status_code}")
            print(f"Response Body: {response.text}")
    except Exception as e:
        print(f"Error: {e}")

asyncio.run(main())
