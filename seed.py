import os
from decimal import Decimal

from dotenv import load_dotenv
import psycopg
from werkzeug.security import generate_password_hash

load_dotenv()

ADMIN_EMAIL = "karl.wikell@gmail.com"
ADMIN_PASSWORD = "DV1703"

TEMP_USER_EMAIL = "hej.hej@hej.hej"
TEMP_USER_PASSWORD = "DV1703"


def get_conn() -> psycopg.Connection:
    dsn = os.getenv("DATABASE_URL")
    if not dsn:
        raise SystemExit("DATABASE_URL is not set.")
    return psycopg.connect(dsn)


def upsert_user(conn, email: str, password: str, role: str) -> int:
    pw_hash = generate_password_hash(password)
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO users (email, password_hash, role)
            VALUES (%s, %s, %s)
            ON CONFLICT (email)
            DO UPDATE SET password_hash = EXCLUDED.password_hash, role = EXCLUDED.role
            RETURNING id;
            """,
            (email, pw_hash, role),
        )
        return cur.fetchone()[0]


def upsert_customer_for_user(conn, user_id: int, full_name: str, email: str, phone: str | None):
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO customers (full_name, email, phone, user_id)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (email)
            DO UPDATE SET full_name=EXCLUDED.full_name, phone=EXCLUDED.phone, user_id=EXCLUDED.user_id
            RETURNING id;
            """,
            (full_name, email, phone, user_id),
        )
        return cur.fetchone()[0]


def upsert_category(conn, display_name: str, daily_rate: Decimal) -> int:
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO categories (display_name, daily_rate)
            VALUES (%s, %s)
            ON CONFLICT (display_name)
            DO UPDATE SET daily_rate=EXCLUDED.daily_rate
            RETURNING id;
            """,
            (display_name, daily_rate),
        )
        return cur.fetchone()[0]


def upsert_tent_category(conn, category_id: int, capacity: int, season_rating: int,
                         build_time: int, setup: Decimal, teardown: Decimal,
                         area: Decimal | None = None):
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO tent_categories (
              category_id, capacity, season_rating, estimated_build_time_minutes,
              construction_cost, deconstruction_cost, floor_area_m2
            )
            VALUES (%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (category_id)
            DO UPDATE SET capacity=EXCLUDED.capacity, season_rating=EXCLUDED.season_rating,
              estimated_build_time_minutes=EXCLUDED.estimated_build_time_minutes,
              construction_cost=EXCLUDED.construction_cost, deconstruction_cost=EXCLUDED.deconstruction_cost,
              floor_area_m2=EXCLUDED.floor_area_m2;
            """,
            (category_id, capacity, season_rating, build_time, setup, teardown, area),
        )


def upsert_furn_category(conn, category_id: int, kind: str, weight: Decimal | None, notes: str | None):
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO furnishing_categories (category_id, furnishing_kind, weight_kg, notes)
            VALUES (%s,%s,%s,%s)
            ON CONFLICT (category_id)
            DO UPDATE SET furnishing_kind=EXCLUDED.furnishing_kind, weight_kg=EXCLUDED.weight_kg, notes=EXCLUDED.notes;
            """,
            (category_id, kind, weight, notes),
        )


def insert_units(conn, category_id: int, sku_prefix: str, count: int):
    with conn.cursor() as cur:
        for n in range(1, count + 1):
            sku = f"{sku_prefix}-{n:02d}"
            cur.execute(
                """
                INSERT INTO items (category_id, sku, is_active)
                VALUES (%s, %s, TRUE)
                ON CONFLICT (sku) DO UPDATE SET category_id=EXCLUDED.category_id, is_active=TRUE;
                """,
                (category_id, sku),
            )


def main():
    conn = get_conn()
    try:
        with conn.transaction():
            upsert_user(conn, ADMIN_EMAIL, ADMIN_PASSWORD, "admin")
            temp_uid = upsert_user(conn, TEMP_USER_EMAIL, TEMP_USER_PASSWORD, "customer")
            upsert_customer_for_user(conn, temp_uid, "Temp Customer", TEMP_USER_EMAIL, None)

            # Furnishings
            cat = upsert_category(conn, "Table", Decimal("80"))
            upsert_furn_category(conn, cat, "table", None, "Table for about 6 people")
            insert_units(conn, cat, "FURN-TABLE", 2)

            cat = upsert_category(conn, "Chair", Decimal("20"))
            upsert_furn_category(conn, cat, "chair", None, None)
            insert_units(conn, cat, "FURN-CHAIR", 6)

            cat = upsert_category(conn, "Bench set", Decimal("249"))
            upsert_furn_category(conn, cat, "bench_set", None, "Good for large events")
            insert_units(conn, cat, "FURN-BENCHSET", 2)

            # Tents (one unit each)
            cat = upsert_category(conn, "Tält 6×6 m", Decimal("1399"))
            upsert_tent_category(conn, cat, 45, 5, 45, Decimal("799.50"), Decimal("799.50"), Decimal("36.0"))
            insert_units(conn, cat, "TENT-6X6", 1)

            cat = upsert_category(conn, "Tält 8×4 m", Decimal("1099"))
            upsert_tent_category(conn, cat, 40, 4, 45, Decimal("699.50"), Decimal("699.50"), Decimal("32.0"))
            insert_units(conn, cat, "TENT-8X4", 1)

            cat = upsert_category(conn, "Tält 6×10 m", Decimal("2099"))
            upsert_tent_category(conn, cat, 80, 5, 60, Decimal("1199.50"), Decimal("1199.50"), Decimal("60.0"))
            insert_units(conn, cat, "TENT-6X10", 1)

        print("Seed done.")
    finally:
        conn.close()


if __name__ == "__main__":
    main()