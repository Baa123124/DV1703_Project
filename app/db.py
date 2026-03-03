import os
import psycopg
from psycopg.rows import dict_row
from flask import g

def _connect():
    dsn = os.getenv("DATABASE_URL")
    if not dsn:
        raise RuntimeError("DATABASE_URL is not set (see .env.example).")
    return psycopg.connect(dsn, row_factory=dict_row)

def get_db():
    if "db" not in g:
        g.db = _connect()
    return g.db

def close_db(exc=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()

def init_db(app):
    @app.cli.command("ping-db")
    def ping_db():
        conn = _connect()
        with conn.cursor() as cur:
            cur.execute("SELECT 1;")
        conn.close()
        print("OK")

def query(sql, params=None, *, one=False, commit=False):
    conn = get_db()
    with conn.cursor() as cur:
        cur.execute(sql, params or ())
        if cur.description is None:
            if commit:
                conn.commit()
            return None
        result = cur.fetchone() if one else cur.fetchall()
    if commit:
        conn.commit()
    return result

def execute(sql, params=None):
    conn = get_db()
    with conn.cursor() as cur:
        cur.execute(sql, params or ())
    conn.commit()

def tx(fn):
    conn = get_db()
    try:
        with conn.cursor() as cur:
            result = fn(cur)
        conn.commit()
        return result
    except Exception:
        conn.rollback()
        raise
