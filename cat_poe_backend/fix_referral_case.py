import asyncio
from sqlalchemy import text
from database import AsyncSessionLocal


async def fix_referral_case():
    print("Running fix_referral_case...")
    async with AsyncSessionLocal() as db:
        # Raw SQL: avoid loading full ORM rows (older DBs may lack newer columns).
        result = await db.execute(
            text(
                """
                SELECT id, username, referred_by
                FROM users
                WHERE referred_by IS NOT NULL
                """
            )
        )
        rows = result.mappings().all()

        fixed_count = 0
        for row in rows:
            ref = row["referred_by"]
            if ref is None:
                continue
            lowered = ref.lower()
            if ref != lowered:
                print(
                    f"Fixing referred_by for user {row['username']} (ID: {row['id']}) "
                    f"from '{ref}' to '{lowered}'"
                )
                await db.execute(
                    text("UPDATE users SET referred_by = :ref WHERE id = :id"),
                    {"ref": lowered, "id": row["id"]},
                )
                fixed_count += 1

        if fixed_count > 0:
            await db.commit()
            print(f"Successfully fixed lowercase casing for {fixed_count} users' referred_by codes.")
        else:
            print("No users needed referral code case fixing.")


if __name__ == "__main__":
    asyncio.run(fix_referral_case())
