import httpx
import logging
import asyncio
from typing import Optional
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

import models

logger = logging.getLogger(__name__)

class PriceService:
    def __init__(self):
        self._cached_price_usd: Optional[float] = None
        self._last_fetch_time: Optional[datetime] = None
        self._cache_ttl = timedelta(minutes=5)  # Cache for 5 minutes

    async def get_cat_price_usd(self, db: AsyncSession) -> float:
        """
        Returns the CAT price in standard USD as a float.
        Checks AdminConfig for overrides first.
        Falls back to CoinGecko cached price.
        """
        # 1. Check Admin Override & ID
        result = await db.execute(select(models.AdminConfig).where(models.AdminConfig.id == 1))
        config = result.scalars().first()
        
        target_id = "catcoins"
        if config:
            target_id = config.coingecko_coin_id or "catcoins"
            if config.use_manual_cat_price:
                # manual_cat_price_usdt is an int representing micro-USDT
                return config.manual_cat_price_usdt / 1_000_000.0

        # 2. Check Cache
        now = datetime.utcnow()
        if self._cached_price_usd and self._last_fetch_time:
            if now - self._last_fetch_time < self._cache_ttl:
                return self._cached_price_usd

        # 3. Fetch sequentially from APIs
        headers = {"User-Agent": "CatcoinPoE/1.0"}
        async with httpx.AsyncClient(timeout=10.0, headers=headers) as client:
            # Try CoinGecko
            try:
                url = f"https://api.coingecko.com/api/v3/simple/price?ids={target_id}&vs_currencies=usd"
                response = await client.get(url)
                response.raise_for_status()
                data = response.json()
                if target_id in data and 'usd' in data[target_id]:
                    usd_price = float(data[target_id]['usd'])
                    self._cached_price_usd = usd_price
                    self._last_fetch_time = now
                    return self._cached_price_usd
            except Exception as e:
                logger.warning(f"Failed to fetch CAT price from CoinGecko: {e}")
                
            # Try Chainz Cryptoid Fallback
            if target_id in ["catcoin", "catcoins"]:
                try:
                    url = "https://chainz.cryptoid.info/cat/api.dws?q=ticker.usd"
                    response = await client.get(url)
                    response.raise_for_status()
                    usd_price = float(response.text.strip())
                    self._cached_price_usd = usd_price
                    self._last_fetch_time = now
                    return self._cached_price_usd
                except Exception as e:
                    logger.warning(f"Failed to fetch CAT price from Chainz: {e}")

                # Try NonKYC Fallback
                try:
                    url = "https://nonkyc.io/api/v2/ticker/CAT_USDT"
                    response = await client.get(url)
                    response.raise_for_status()
                    data = response.json()
                    if 'last_price' in data:
                        usd_price = float(data['last_price'])
                        self._cached_price_usd = usd_price
                        self._last_fetch_time = now
                        return self._cached_price_usd
                except Exception as e:
                    logger.error(f"Failed to fetch CAT price from NonKYC: {e}")
        
        # 4. Final Fallback (If network failed and no override set)
        if self._cached_price_usd:
             return self._cached_price_usd
             
        # Ultimate fallback of $0.05 if everything fails on absolute first boot
        return 0.05

price_service = PriceService()
