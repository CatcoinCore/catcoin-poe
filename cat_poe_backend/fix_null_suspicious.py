import asyncio
from sqlalchemy import text
from database import AsyncSessionLocal


async def main():
    async with AsyncSessionLocal() as db:
        # Emergency migration check for missing columns
        try:
            new_columns = [
                ("country_source", "VARCHAR(10)"),
                ("total_earnings", "FLOAT DEFAULT 0.0"),
                ("can_withdraw_mining", "BOOLEAN DEFAULT TRUE"),
                ("can_withdraw_referrals", "BOOLEAN DEFAULT TRUE"),
                ("can_withdraw_missions", "BOOLEAN DEFAULT TRUE"),
                ("can_withdraw_games", "BOOLEAN DEFAULT TRUE"),
                ("can_withdraw_game_boosts", "BOOLEAN DEFAULT FALSE"),
            ]

            for col_name, col_def in new_columns:
                res = await db.execute(
                    text(
                        "SELECT column_name FROM information_schema.columns "
                        "WHERE table_name='users' AND column_name=:c"
                    ),
                    {"c": col_name},
                )
                if not res.first():
                    print(f"Adding missing {col_name} column to users table...")
                    await db.execute(
                        text(f"ALTER TABLE users ADD COLUMN {col_name} {col_def}")
                    )
                    await db.commit()

        except Exception as e:
            print(f"Migration check failed (might already be fixed): {e}")

        # Use raw SQL so we do not require every ORM-mapped column to exist on older DBs.
        result = await db.execute(
            text(
                """
                SELECT id, country_source, ip_address, device_id, is_suspicious
                FROM users
                """
            )
        )
        all_users = result.mappings().all()

        fixed_count = 0
        deleted_logs_count = 0
        migrated_source_count = 0

        for row in all_users:
            uid = row["id"]
            country_source = row["country_source"]
            ip_address = row["ip_address"]
            device_id = row["device_id"]
            is_suspicious = row["is_suspicious"]

            if (
                not country_source
                and ip_address
                and ip_address not in ("null", "None", "", "N/A", "127.0.0.1")
            ):
                await db.execute(
                    text("UPDATE users SET country_source = 'IP' WHERE id = :id"),
                    {"id": uid},
                )
                migrated_source_count += 1

            if not is_suspicious:
                continue

            logs_result = await db.execute(
                text(
                    """
                    SELECT id, activity_type, evidence
                    FROM suspicious_activities
                    WHERE user_id = :uid
                    """
                ),
                {"uid": uid},
            )
            logs = logs_result.mappings().all()

            fraud_valid = False

            for log in logs:
                invalid_log = False
                if log["activity_type"] == "IP_FARMING":
                    if "IP address" in log["evidence"] and (
                        not ip_address
                        or ip_address in ("null", "None", "", "N/A", "127.0.0.1")
                    ):
                        invalid_log = True

                if log["activity_type"] == "MULTIPLE_ACCOUNTS_DEVICE":
                    if "Device ID" in log["evidence"] and (
                        not device_id
                        or device_id in ("null", "None", "", "N/A")
                    ):
                        invalid_log = True

                if invalid_log:
                    await db.execute(
                        text("DELETE FROM suspicious_activities WHERE id = :id"),
                        {"id": log["id"]},
                    )
                    deleted_logs_count += 1
                else:
                    fraud_valid = True

            if not fraud_valid:
                await db.execute(
                    text("UPDATE users SET is_suspicious = false WHERE id = :id"),
                    {"id": uid},
                )
                fixed_count += 1

        await db.commit()
        print(
            f"Summary: Migrated {migrated_source_count} country sources, "
            f"Unmarked {fixed_count} users, Deleted {deleted_logs_count} invalid logs."
        )


if __name__ == "__main__":
    asyncio.run(main())
