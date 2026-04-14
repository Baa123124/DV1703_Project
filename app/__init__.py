import os

from dotenv import load_dotenv
from flask import Flask
from werkzeug.middleware.proxy_fix import ProxyFix

from .db import init_db, close_db
from .routes import bp as routes_bp
from .auth import bp as auth_bp


def _env_flag(name, default=False):
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _env_int(name, default):
    value = os.getenv(name)
    if value is None or value.strip() == "":
        return default
    return int(value)


def create_app():
    load_dotenv()

    app_env = (os.getenv("APP_ENV") or "development").strip().lower()
    preferred_url_scheme = os.getenv("PREFERRED_URL_SCHEME") or (
        "https" if app_env == "production" else "http"
    )
    secret_key = (os.getenv("SECRET_KEY") or "").strip()
    if not secret_key:
        raise RuntimeError("SECRET_KEY must be set before the app can start.")

    pending_booking_hold_minutes = _env_int("PENDING_BOOKING_HOLD_MINUTES", 30)
    if pending_booking_hold_minutes <= 0:
        raise RuntimeError("PENDING_BOOKING_HOLD_MINUTES must be greater than 0.")

    max_active_pending_bookings = _env_int(
        "MAX_ACTIVE_PENDING_BOOKINGS_PER_CUSTOMER",
        3,
    )
    if max_active_pending_bookings <= 0:
        raise RuntimeError("MAX_ACTIVE_PENDING_BOOKINGS_PER_CUSTOMER must be greater than 0.")

    app = Flask(__name__)
    app.config.update(
        SECRET_KEY=secret_key,
        PREFERRED_URL_SCHEME=preferred_url_scheme,
        SESSION_COOKIE_HTTPONLY=True,
        SESSION_COOKIE_SAMESITE=os.getenv("SESSION_COOKIE_SAMESITE", "Lax"),
        SESSION_COOKIE_SECURE=_env_flag(
            "SESSION_COOKIE_SECURE",
            default=preferred_url_scheme == "https",
        ),
        PENDING_BOOKING_HOLD_MINUTES=pending_booking_hold_minutes,
        MAX_ACTIVE_PENDING_BOOKINGS_PER_CUSTOMER=max_active_pending_bookings,
    )

    if _env_flag("TRUST_PROXY_HEADERS", default=False):
        app.wsgi_app = ProxyFix(
            app.wsgi_app,
            x_for=_env_int("PROXY_FIX_X_FOR", 1),
            x_proto=_env_int("PROXY_FIX_X_PROTO", 1),
            x_host=_env_int("PROXY_FIX_X_HOST", 1),
            x_port=_env_int("PROXY_FIX_X_PORT", 1),
        )

    init_db(app)
    app.teardown_appcontext(close_db)

    app.register_blueprint(auth_bp)
    app.register_blueprint(routes_bp)

    return app
