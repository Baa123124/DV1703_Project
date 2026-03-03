from flask import Flask
from dotenv import load_dotenv
import os

from .db import init_db, close_db
from .routes import bp as routes_bp
from .auth import bp as auth_bp

def create_app():
    load_dotenv()

    app = Flask(__name__)
    app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "dev-secret")

    init_db(app)
    app.teardown_appcontext(close_db)

    app.register_blueprint(auth_bp)
    app.register_blueprint(routes_bp)

    return app