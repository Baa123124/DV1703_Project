from flask import Blueprint, request, render_template, redirect, url_for, flash, session
from werkzeug.security import generate_password_hash, check_password_hash

from .db import query
from .sql import (
    SQL_CREATE_USER, SQL_GET_USER_BY_EMAIL,
    SQL_LINK_CUSTOMER_TO_USER, SQL_CREATE_CUSTOMER
)

bp = Blueprint("auth", __name__, url_prefix="/auth")

@bp.get("/login")
def login_form():
    return render_template("login.html")

@bp.post("/login")
def login():
    email = request.form.get("email", "").strip().lower()
    password = request.form.get("password", "")

    user = query(SQL_GET_USER_BY_EMAIL, (email,), one=True)
    if not user or not check_password_hash(user["password_hash"], password):
        flash("Invalid email or password.", "error")
        return redirect(url_for("auth.login_form"))

    session.clear()
    session["user_id"] = user["id"]
    session["role"] = user["role"]
    flash("Logged in.", "success")
    return redirect(url_for("routes.home"))

@bp.get("/register")
def register_form():
    return render_template("register.html")

@bp.post("/register")
def register():
    full_name = request.form.get("full_name", "").strip()
    email = request.form.get("email", "").strip().lower()
    phone = request.form.get("phone", "").strip() or None
    password = request.form.get("password", "")

    if not full_name or not email or not password:
        flash("Name, email and password are required.", "error")
        return redirect(url_for("auth.register_form"))

    pw_hash = generate_password_hash(password)

    try:
        user = query(SQL_CREATE_USER, (email, pw_hash, "customer"), one=True, commit=True)

        # If admin already created a customer with same email, link it
        linked = query(SQL_LINK_CUSTOMER_TO_USER, (user["id"], email), one=True, commit=True)

        # Otherwise create a new customer profile linked to this user
        if not linked:
            query(SQL_CREATE_CUSTOMER, (full_name, email, phone, user["id"]), one=True, commit=True)

    except Exception:
        flash("Registration failed (email may already exist).", "error")
        return redirect(url_for("auth.register_form"))

    session.clear()
    session["user_id"] = user["id"]
    session["role"] = user["role"]
    flash("Account created.", "success")
    return redirect(url_for("routes.home"))

@bp.get("/logout")
def logout():
    session.clear()
    flash("Logged out.", "success")
    return redirect(url_for("routes.home"))