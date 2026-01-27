# main.py — CORRECTED VERSION
import os
import uuid
import math
import json  
import razorpay
from twilio.rest import Client
import random
import hmac
import hashlib
import requests
from datetime import datetime, timedelta,timezone
from fastapi import Request,FastAPI,APIRouter, HTTPException, Depends, UploadFile, File, Form, status,Body,Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.security import OAuth2PasswordBearer
import urllib.parse
from jose import jwt, JWTError
from datetime import datetime
from database import get_db_connection
from psycopg2.extras import RealDictCursor
from security import create_access_token, get_password_hash, verify_password
from security import SECRET_KEY, ALGORITHM
from pydantic import BaseModel
from typing import Optional, List
from pydantic import Field
from models import UserCreate, UserLogin, AddressCreate, B2CRegister, OrderCreate , PhoneRequest, VerifyOtpRequest,normalize_phone, ResetPasswordRequest ,CreatePaymentRequest,VerifyPaymentRequest,NotificationOut    
from dotenv import load_dotenv
from dotenv import load_dotenv



UPLOAD_FOLDER = "uploads"
BASE_UPLOAD_DIR = os.path.join(UPLOAD_FOLDER, "business", "app")
GST_DIR = os.path.join(BASE_UPLOAD_DIR, "gst")
LICENSE_DIR = os.path.join(BASE_UPLOAD_DIR, "license")

os.makedirs(GST_DIR, exist_ok=True)
os.makedirs(LICENSE_DIR, exist_ok=True)
ZONE_LOCAL = "local"
ZONE_ZONAL = "zonal"
ZONE_NATIONAL = "national"
DELHIVERY_SURFACE_RATE_CARD = {
    ZONE_LOCAL: {
        "slabs": [
            (0.5, 45),
            (1, 65),
            (5, 95),
            (10, 120),
        ],
        "extra_per_kg": 12
    },
    ZONE_ZONAL: {
        "slabs": [
            (0.5, 50),
            (1, 70),
            (5, 110),
            (10, 150),
        ],
        "extra_per_kg": 15
    },
    ZONE_NATIONAL: {
        "slabs": [
            (0.5, 60),
            (1, 85),
            (5, 130),
            (10, 180),
        ],
        "extra_per_kg": 20
    }
}


load_dotenv()
BASE_URL = os.getenv("BASE_URL", "http://localhost:8000")  # Fallback for local dev
TWILIO_ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID")
TWILIO_AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN")
TWILIO_VERIFY_SERVICE_SID = "VA0ba7f74076c233e8f8ca021f2668c245"  # You need to create this in Twilio Console
client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)

# Initialize RazorPay client
RAZORPAY_KEY_ID = os.getenv("RAZORPAY_KEY_ID")
RAZORPAY_KEY_SECRET = os.getenv("RAZORPAY_KEY_SECRET")
DELHIVERY_TOKEN = os.getenv("DELHIVERY_TOKEN")  # fallback if not in .env
DELHIVERY_PICKUP_PIN = os.getenv("DELHIVERY_PICKUP_PIN")
DELHIVERY_BASE_URL = os.getenv("DELHIVERY_BASE_URL", "https://track.delhivery.com")
razorpay_client = razorpay.Client(auth=(RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET))


otp_store = {}


app = FastAPI(title="backendapi")
app.mount("/uploads", StaticFiles(directory=UPLOAD_FOLDER), name="uploads")

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

# Ensure upload directories exist



def normalize_product_dates(product):
    """Normalize offer start/end fields to datetime when they are numeric or ISO strings."""
    keys = ("b2c_offer_start_date", "b2c_offer_end_date", "b2b_offer_start_date", "b2b_offer_end_date")
    for k in keys:
        v = product.get(k)
        if v is None:
            continue
        if isinstance(v, (int, float)):
            try:
                product[k] = datetime.fromtimestamp(v)
            except Exception:
                pass
        elif isinstance(v, str):
            try:
                product[k] = datetime.fromisoformat(v)
            except Exception:
                try:
                    ts = float(v)
                    product[k] = datetime.fromtimestamp(ts)
                except Exception:
                    pass


def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception

    except JWTError:
        raise credentials_exception

    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    cursor.execute("SELECT id FROM auth_users WHERE email = %s", (email,))
    user = cursor.fetchone()
    conn.close()

    if user is None:
        raise credentials_exception
    
    return user["id"] # Return the user_id
    

@app.post("/auth/send-verification")
async def send_verification(payload: PhoneRequest):
    phone = normalize_phone(payload.phone)  # 🔥 ADD THIS

    otp = str(random.randint(100000, 999999))
    otp_store[phone] = {
        "otp": otp,
        "expires_at": datetime.now() + timedelta(minutes=10),
        "verified": False
    }

    client.messages.create(
        body=f"Your verification code is: {otp}",
        from_=os.getenv("TWILIO_PHONE_NUMBER"),
        to=phone
    )

    return {"message": "OTP sent successfully"}


@app.post("/auth/verify-otp")
async def verify_otp(payload: VerifyOtpRequest):
    phone = normalize_phone(payload.phone)   # ✅ keep normalization
    otp = payload.otp

    # ✅ Decide OTP key safely
    if payload.type == "reset":
        key = f"reset_{phone}"
    else:
        key = phone  # signup / b2b signup

    if key not in otp_store:
        raise HTTPException(400, "No OTP requested for this phone")

    record = otp_store[key]

    if datetime.now() > record["expires_at"]:
        del otp_store[key]
        raise HTTPException(400, "OTP expired")

    if record["otp"] != otp:
        raise HTTPException(400, "Invalid OTP")

    record["verified"] = True
    return {
        "success": True,
        "message": "Phone verified successfully"
    }



@app.post("/auth/forgot-password/request")
async def forgot_password_request(payload: PhoneRequest):
    phone = normalize_phone(payload.phone)
    """Send OTP for password reset (check if phone exists in DB)"""
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    # Check if phone exists in auth_users
    cursor.execute("SELECT id FROM auth_users WHERE phone_number = %s", (phone,))
    if not cursor.fetchone():
        raise HTTPException(404, "Phone number not registered")
    
    # Send OTP (same logic as send_verification)
    otp = str(random.randint(100000, 999999))
    otp_store[f"reset_{phone}"] = {
        "otp": otp,
        "expires_at": datetime.now() + timedelta(minutes=10)
    }
    
    message = client.messages.create(
        body=f"Your password reset code is: {otp}",
        from_=os.getenv("TWILIO_PHONE_NUMBER"),
        to=phone
    )
    
    return {"success":  True, "message": "Reset OTP sent"}

@app.post("/auth/reset-password")
async def reset_password(payload: ResetPasswordRequest):
    phone = normalize_phone(payload.phone)
    email = payload.email.lower()
    otp = payload.otp
    new_password = payload.new_password

    key = f"reset_{phone}"

    if key not in otp_store:
        raise HTTPException(400, "No reset request found")

    record = otp_store[key]

    if datetime.now() > record["expires_at"]:
        del otp_store[key]
        raise HTTPException(400, "OTP expired")

    if record["otp"] != otp:
        raise HTTPException(400, "Invalid OTP")

    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    cursor.execute(
        "SELECT id FROM auth_users WHERE email = %s AND phone_number = %s",
        (email, phone)
    )
    user = cursor.fetchone()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="No account found for this email and phone number"
        )

    hashed_pw = get_password_hash(new_password[:72])

    cursor.execute(
        "UPDATE auth_users SET password_hash = %s WHERE id = %s",
        (hashed_pw, user["id"])
    )
    conn.commit()

    del otp_store[key]

    return {"success": True, "message": "Password reset successful"}


# ============================ AUTH ============================
@app.post("/auth/signup")
async def signup(user: UserCreate, user_type: str = "b2c"):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cursor.execute("SELECT id FROM auth_users WHERE email = %s", (user.email,))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Email already registered")

        # Validate required fields based on user type
        if user_type == "b2c" and not user.full_name:
            raise HTTPException(status_code=400, detail="Full name is required for B2C signup")

        user_id = str(uuid.uuid4())
        truncated_pw = (user.password or "")[:72]
        hashed_pw = get_password_hash(truncated_pw)

        # Use full_name for B2C, None for B2B
        full_name = user.full_name if user_type == "b2c" else None

        cursor.execute("""
            INSERT INTO auth_users 
            (id, email, password_hash, full_name, phone_number, raw_user_meta_data)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (user_id, user.email, hashed_pw, full_name, user.phone_number, "{}"))

        conn.commit()
        
        # Create token once with correct parameters
        token = create_access_token(
            {"sub": user.email}, 
            user_id=user_id,
            user_type=user_type
        )
        
        return {"access_token": token, "token_type": "bearer", "user_id": user_id}
    finally:
        cursor.close()
        conn.close()
        
@app.post("/auth/login")
async def login(form: UserLogin):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # First, check auth_users table
        cursor.execute("SELECT id, password_hash, email FROM auth_users WHERE email = %s", (form.email,))
        user = cursor.fetchone()
        
        if not user:
            raise HTTPException(401, "Incorrect email or password")
        
        # Verify password
        provided_pw = (form.password or "")[:72]
        if not verify_password(provided_pw, user["password_hash"]):
            raise HTTPException(401, "Incorrect email or password")
        
        # Determine if user is B2B or B2C
        user_type = "b2c"  # default
        
        # Check if user exists in b2b_applications
        cursor.execute("SELECT id, status FROM b2b_applications WHERE user_id = %s", (user["id"],))
        b2b_app = cursor.fetchone()
        
        if b2b_app:
            if b2b_app["status"] != "approved":
                raise HTTPException(403, f"B2B account is {b2b_app['status']}. Please wait for approval.")
            user_type = "b2b"
        
        # Create token with user type
        token = create_access_token({
            "sub": form.email,
            "user_id": user["id"],
            "user_type": user_type
        })
        
        return {
            "access_token": token,
            "token_type": "bearer",
            "user_type": user_type
        }
    finally:
        cursor.close()
        conn.close()

# ============================ B2C SIGNUP (Normal User) ============================
@app.post("/auth/register/b2c")
async def register_b2c(payload: B2CRegister):
    # This is for regular customer signup. It uses the same main signup logic.
    user_in = UserCreate(
        email=payload.email, password=payload.password,
        full_name=payload.full_name, phone_number=payload.phone_number,
    )
    
    # Call signup to create user
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # Check if email exists
        cursor.execute("SELECT id FROM auth_users WHERE email = %s", (payload.email,))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Email already registered")
            
        # Normalize phone number before OTP check
        phone = normalize_phone(payload.phone_number)

        otp_entry = otp_store.get(phone)
        if not otp_entry or not otp_entry.get("verified"):
            raise HTTPException(status_code=400, detail="Phone number not verified")
   

        user_id = str(uuid.uuid4())
        truncated_pw = (payload.password or "")[:72]
        hashed_pw = get_password_hash(truncated_pw)

            # Insert into auth_users table
        cursor.execute("""
       INSERT INTO auth_users 
       (id, email, password_hash, full_name, phone_number, raw_user_meta_data)
        VALUES (%s, %s, %s, %s, %s, %s)
       """, (user_id, payload.email, hashed_pw, payload.full_name, phone, "{}"))

        # Create address if provided
        address_id = None
        if payload.address:
            address_id = str(uuid.uuid4())
            cursor.execute("""
                INSERT INTO addresses (id, address, city, state,pincode, country, user_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (address_id, payload.address.address, payload.address.state,payload.address.city, 
                  payload.address.pincode, payload.address.country, user_id))

            cursor.execute("""
                INSERT INTO user_addresses (id, user_id, address_id, name, is_default)
                VALUES (gen_random_uuid(), %s, %s, %s, %s)
            """, (user_id, address_id, payload.address.name or "Home", payload.address.is_default or False))

        # Insert into b2c_applications table
        cursor.execute("""
            INSERT INTO b2c_applications 
            (id, full_name, phone_number, email, address_id)
            VALUES (%s, %s, %s, %s, %s)
        """, (user_id, payload.full_name, phone, payload.email, address_id))
        
        conn.commit()
        
        # Clean up OTP record after successful registration
        otp_store.pop(phone, None)

        
        # Create token with all required claims
        token = create_access_token(
            {"sub": payload.email}, 
            user_id=user_id,
            user_type="b2c"
        )
        
        return {
            "access_token": token, 
            "token_type": "bearer", 
            "user_id": user_id,
            "message": "B2C registration successful"
        }
        
    except Exception as e:
        if conn: conn.rollback()
        raise HTTPException(status_code=500, detail=f"Registration failed: {e}")
    finally:
        if cursor: cursor.close()
        if conn: conn.close()
# ============================ B2B SIGNUP WITH DOCUMENTS ============================
@app.post("/auth/register/b2b")
async def register_b2b(
    email: str = Form(...), 
    password: str = Form(...),
    business_name: str = Form(...), 
    gstin: str = Form(...),
    pan: str = Form(...), 
    phone_number: str = Form(...),
    address: str = Form(None), 
    gst_certificate: UploadFile = File(...),
    business_license: UploadFile = File(...)
):
    conn = None
    cursor = None

    try:
        # ✅ Normalize phone FIRST
        phone = normalize_phone(phone_number)

        # ✅ OTP VERIFICATION FIRST (before DB writes)
        otp_entry = otp_store.get(phone)
        if not otp_entry or not otp_entry.get("verified"):
            raise HTTPException(status_code=400, detail="Phone number not verified")

        conn = get_db_connection()
        cursor = conn.cursor()

        # ✅ Check if email already exists
        cursor.execute("SELECT id FROM auth_users WHERE email = %s", (email,))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Email already registered")

        # ✅ Create user
        user_id = str(uuid.uuid4())
        hashed_pw = get_password_hash(password[:72])

        cursor.execute("""
            INSERT INTO auth_users 
            (id, email, password_hash,full_name, phone_number, raw_user_meta_data)
            VALUES (%s, %s, %s, %s, %s,%s)
        """, (user_id, email, hashed_pw, business_name, phone, "{}"))

        # ✅ Save documents
        gst_filename = f"{user_id}_{gst_certificate.filename}"
        license_filename = f"{user_id}_{business_license.filename}"

        gst_fs_path = os.path.join(GST_DIR, gst_filename)
        license_fs_path = os.path.join(LICENSE_DIR, license_filename)

        with open(gst_fs_path, "wb") as f:
             f.write(await gst_certificate.read())

        with open(license_fs_path, "wb") as f:
             f.write(await business_license.read())

        gst_public_url = f"{BASE_URL}/uploads/business/app/gst/{gst_filename}"
        license_public_url = f"{BASE_URL}/uploads/business/app/license/{license_filename}"

        # ✅ Address handling
        address_id = None
        if address:
            addr_obj = json.loads(address)

            if addr_obj.get("address"):
                address_id = str(uuid.uuid4())
                cursor.execute("""
                    INSERT INTO addresses (id, address, city,state, pincode, country, user_id)
                    VALUES (%s, %s, %s, %s, %s, %s,%s)
                """, (
                    address_id,
                    addr_obj.get("address"),
                    addr_obj.get("city"),
                    addr_obj.get("state"),
                    addr_obj.get("pincode"),
                    addr_obj.get("country"),
                    user_id
                ))

                cursor.execute("""
                    INSERT INTO user_addresses (id, user_id, address_id, name, is_default)
                    VALUES (%s, %s, %s, %s, %s)
                """, (str(uuid.uuid4()), user_id, address_id, "Business Address", True))

        # ✅ Insert B2B application
        b2b_app_id = str(uuid.uuid4())
        now = datetime.now()

        cursor.execute("""
            INSERT INTO b2b_applications
            (id, user_id, business_name, gstin, pan, email, phone_number,
             gst_certificate_url, business_license_url, status, created_at, address_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            b2b_app_id,
            user_id,
            business_name,
            gstin,
            pan,
            email,
            phone,
            gst_public_url,
            license_public_url,
            "pending_approval",
            now,
            address_id
        ))

        conn.commit()

        # ✅ Remove OTP after success
        otp_store.pop(phone, None)

        # ✅ Create token
        token = create_access_token(
            {"sub": email},
            user_id=user_id,
            user_type="b2b"
        )

        return {
            "message": "B2B Application Submitted Successfully",
            "application_id": b2b_app_id,
            "user_id": user_id,
            "access_token": token,
            "token_type": "bearer"
        }

    except HTTPException:
        raise
    except Exception as e:
        if conn:
            conn.rollback()
        print("🔥 B2B REGISTER ERROR:", repr(e))
        raise HTTPException(status_code=500, detail="B2B registration failed")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

# ============================ ADDRESS CRUD ============================

@app.post("/users/addresses")
async def create_address(address: AddressCreate, current_user_id: str = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        address_id = str(uuid.uuid4())
        if address.is_default:
            cursor.execute("UPDATE user_addresses SET is_default = %s WHERE user_id = %s", (False, current_user_id))
        cursor.execute("""
            INSERT INTO addresses (id, address, city,state, pincode, country, user_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (address_id, address.address, address.city,address.state, address.pincode, address.country, current_user_id))
        cursor.execute("""
            INSERT INTO user_addresses (id, user_id, address_id, name, is_default)
            VALUES (gen_random_uuid(), %s, %s, %s, %s)
        """, (current_user_id, address_id, address.name, address.is_default))
        conn.commit()
        return {"message": "Address added", "address_id": address_id}
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@app.put("/users/addresses/{user_address_id}")
async def update_address(user_address_id: str, address: AddressCreate, current_user_id: str = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT address_id FROM user_addresses WHERE id = %s AND user_id = %s", (user_address_id, current_user_id))
        row = cursor.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Address not found")
        address_id = row[0]
        if address.is_default:
            cursor.execute("UPDATE user_addresses SET is_default = %s WHERE user_id = %s", (False, current_user_id))
        cursor.execute("""
            UPDATE addresses SET address = %s, city = %s, state = %s, pincode = %s, country = %s
            WHERE id = %s AND user_id = %s
        """, (address.address, address.city, address.state, address.pincode, address.country, address_id, current_user_id))
        cursor.execute("""
            UPDATE user_addresses SET name = %s, is_default = %s
            WHERE id = %s AND user_id = %s
        """, (address.name, address.is_default, user_address_id, current_user_id))
        conn.commit()
        return {"message": "Address updated"}
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@app.delete("/users/addresses/{user_address_id}")
async def delete_address(user_address_id: str, current_user_id: str = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM user_addresses WHERE id = %s AND user_id = %s", (user_address_id, current_user_id))
        conn.commit()
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Address not found or not owned by user")
        return {"message": "Deleted"}
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@app.get("/users/addresses")
async def list_addresses(current_user_id: str = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cursor.execute("""
            SELECT 
                ua.id AS user_address_id, ua.name, ua.is_default,
                a.id, a.address,a.state, a.city, a.pincode, a.country
            FROM user_addresses ua JOIN addresses a ON ua.address_id = a.id
            WHERE ua.user_id = %s ORDER BY ua.created_at DESC
        """, (current_user_id,))
        return {"data": cursor.fetchall()}
    finally:
        cursor.close()
        conn.close()

# ============================ USER PROFILE (GET /users/me) ============================

@app.get("/users/me")
async def get_me(token: str = Depends(oauth2_scheme)):
    """
    Returns the logged-in user's complete profile information.
    Detects B2B or B2C automatically based on the token payload.
    """
    # Validate token
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")
        user_id = payload.get("user_id")
        user_type = payload.get("user_type")
        if not email or not user_id:
            raise HTTPException(401, "Invalid token")
    except JWTError:
        raise HTTPException(401, "Invalid or expired token")

    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    try:
        user_info = {
            "user_id": user_id,
            "email": email,
            "user_type": user_type or "b2c"
        }

        if user_type == "b2b":
            # Fetch from b2b_applications table
            cursor.execute("""
                SELECT 
                    business_name,
                    email,
                    phone_number,
                    gstin,
                    pan,
                    created_at,
                    status
                FROM b2b_applications
                WHERE user_id = %s
                ORDER BY created_at DESC
                LIMIT 1
            """, (user_id,))
            row = cursor.fetchone()
            
            if row:
                user_info["full_name"] = row["business_name"]  # Use business name as display name
                user_info["business_name"] = row["business_name"]
                user_info["email"] = row["email"]
                user_info["phone_number"] = row["phone_number"]
                user_info["gstin"] = row["gstin"]
                user_info["pan"] = row["pan"]
                user_info["status"] = row["status"]
                user_info["created_at"] = row["created_at"]
                
                # Also get from auth_users for consistency
                cursor.execute("""
                    SELECT full_name, created_at as auth_created_at 
                    FROM auth_users 
                    WHERE id = %s
                """, (user_id,))
                auth_row = cursor.fetchone()
                if auth_row and auth_row["full_name"]:
                    user_info["full_name"] = auth_row["full_name"]  # Prefer personal name if available
                user_info["auth_created_at"] = auth_row["auth_created_at"] if auth_row else row["created_at"]
        
        else:
            # Fetch from b2c_applications table
            cursor.execute("""
                SELECT 
                    full_name,
                    email,
                    phone_number,
                    created_at
                FROM b2c_applications
                WHERE id = %s
            """, (user_id,))
            row = cursor.fetchone()
            
            if row:
                user_info["full_name"] = row["full_name"]
                user_info["email"] = row["email"]
                user_info["phone_number"] = row["phone_number"]
                user_info["created_at"] = row["created_at"]
                
                # Also get from auth_users for consistency
                cursor.execute("""
                    SELECT created_at as auth_created_at 
                    FROM auth_users 
                    WHERE id = %s
                """, (user_id,))
                auth_row = cursor.fetchone()
                user_info["auth_created_at"] = auth_row["auth_created_at"] if auth_row else row["created_at"]

        # If no data found in application tables, fallback to auth_users
        if not row:
            cursor.execute("""
                SELECT 
                    full_name,
                    email,
                    phone_number,
                    created_at as auth_created_at
                FROM auth_users 
                WHERE id = %s
            """, (user_id,))
            auth_data = cursor.fetchone()
            
            if auth_data:
                user_info["full_name"] = auth_data["full_name"] or email.split('@')[0]
                user_info["email"] = auth_data["email"]
                user_info["phone_number"] = auth_data["phone_number"]
                user_info["created_at"] = auth_data["auth_created_at"]
                user_info["auth_created_at"] = auth_data["auth_created_at"]
                
                # Set default values for B2B fields
                if user_type == "b2b":
                    user_info["gstin"] = ""
                    user_info["pan"] = ""
                    user_info["business_name"] = ""
        return user_info

    finally:
        cursor.close()
        conn.close()
# ============================ DELETE USER ACCOUNT ============================
@app.delete("/users/me")
async def delete_user(current_user_id: str = Depends(get_current_user)):
    """
    Deletes the user and all associated data in the system.
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # ---------------------- CHILD TABLES ----------------------
        # 1️⃣ Delete product reviews
        cursor.execute("DELETE FROM product_reviews WHERE user_id = %s", (current_user_id,))
            
        # 3️⃣ Delete orders & order items
        cursor.execute("SELECT id FROM orders WHERE customer = %s", (current_user_id,))
        order_ids = [row for row in cursor.fetchall()]
        if order_ids:
            cursor.execute(
                "DELETE FROM order_items WHERE order_id = ANY(%s)", (order_ids,)
            )
            cursor.execute(
                "DELETE FROM orders WHERE id = ANY(%s)", (order_ids,)
            )

        # 4️⃣ Delete user addresses mapping & addresses
        cursor.execute("DELETE FROM user_addresses WHERE user_id = %s", (current_user_id,))
        cursor.execute("DELETE FROM addresses WHERE user_id = %s", (current_user_id,))

        # 5️⃣ Delete B2B / B2C applications
        cursor.execute("DELETE FROM b2b_applications WHERE user_id = %s", (current_user_id,))
        cursor.execute("DELETE FROM b2c_applications WHERE id = %s", (current_user_id,))

        # 6️⃣ Delete any other dependent tables
        # Add more deletes here if you have wishlist, notifications, etc.

        # ---------------------- DELETE USER ----------------------
        cursor.execute("DELETE FROM auth_users WHERE id = %s", (current_user_id,))

        # Commit all deletes
        conn.commit()

        return {"message": "Account and all associated data deleted successfully"}

    except Exception as e:
        conn.rollback()
        print("🔥 DELETE USER ERROR:", repr(e))
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()


@app.put("/users/me")
async def update_user_profile(
    update_data: dict = Body(...),
    current_user_id: str = Depends(get_current_user)
):
    """
    Update user profile information.
    """
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # First check user type from token
        try:
            # Get token from header
            from fastapi import Request
            request = Request.scope.get("request")
            token = request.headers.get("authorization").split(" ")[1]
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            user_type = payload.get("user_type", "b2c")
        except:
            # Fallback: check if user exists in b2b_applications table
            cursor.execute("SELECT id FROM b2b_applications WHERE user_id = %s", (current_user_id,))
            b2b_app = cursor.fetchone()
            user_type = "b2b" if b2b_app else "b2c"
        
        # Update auth_users table
        auth_updates = []
        auth_values = []
        
        # Map update fields to database columns
        field_mapping = {
            'full_name': 'full_name',
            'phone_number': 'phone_number',
            
        }
        
        for field, db_field in field_mapping.items():
            if field in update_data:
                auth_updates.append(f"{db_field} = %s")
                auth_values.append(update_data[field])
        
        if auth_updates:
            auth_values.append(current_user_id)
            auth_query = f"UPDATE auth_users SET {', '.join(auth_updates)} WHERE id = %s"
            cursor.execute(auth_query, auth_values)
        
        # Update specific application table
        if user_type == "b2b":
            # Update b2b_applications table
            b2b_updates = []
            b2b_values = []
            
            b2b_fields = ['business_name', 'gstin', 'pan', 'phone_number', 'email']
            for field in b2b_fields:
                if field in update_data:
                    b2b_updates.append(f"{field} = %s")
                    b2b_values.append(update_data[field])
            
            if b2b_updates:
                b2b_values.append(current_user_id)
                b2b_query = f"UPDATE b2b_applications SET {', '.join(b2b_updates)} WHERE user_id = %s"
                cursor.execute(b2b_query, b2b_values)
        else:
            # Update b2c_applications table
            b2c_updates = []
            b2c_values = []
            
            b2c_fields = ['full_name', 'phone_number', 'email']
            for field in b2c_fields:
                if field in update_data:
                    b2c_updates.append(f"{field} = %s")
                    b2c_values.append(update_data[field])
            
            if b2c_updates:
                b2c_values.append(current_user_id)
                b2c_query = f"UPDATE b2c_applications SET {', '.join(b2c_updates)} WHERE id = %s"
                cursor.execute(b2c_query, b2c_values)
        
        conn.commit()
        
        return {"message": "Profile updated successfully"}
        
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Update failed: {e}")
    finally:
        cursor.close()
        conn.close()
# ============================ PRODUCT ENDPOINTS (View Only) ============================

# Get all products with filtering
@app.get("/products")
async def get_products(
    category: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    status: Optional[str] = "Published",
    limit: int = 50,
    offset: int = 0,
    user_type: Optional[str] = None  # b2c or b2b
):
    """
    Get products with filtering. User type determines which price to show.
    """
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
   
    try:
        # Base query - REMOVED 'rating, reviews' as they don't exist in products table
        query = """
            SELECT 
                id, name, colors,brand_name,category, description, status, stock, image,
                created_at, updated_at,
                b2c_price, b2b_price, 
                b2c_active_offer, b2b_active_offer,
                b2c_offer_price, b2b_offer_price,
                b2c_discount, b2b_discount,
                b2c_offer_start_date, b2c_offer_end_date,sgst,
                cgst,b2b_offer_start_date, b2b_offer_end_date,
                compare_at_price ,info,
                weight, length, breadth, return_policy,height,hsn
                -- rating, reviews REMOVED: These columns don't exist in products table
            FROM products WHERE 1=1
        """
        params = []
        
        # Apply filters
        if category and category.lower() != "all":
            query += " AND category = %s"
            params.append(category)
        
        if min_price is not None:
            if user_type == "b2c":
                query += " AND b2c_price >= %s"
            else:
                query += " AND b2b_price >= %s"
            params.append(min_price)
        
        if max_price is not None:
            if user_type == "b2c":
                query += " AND b2c_price <= %s"
            else:
                query += " AND b2b_price <= %s"
            params.append(max_price)
        
        if status:
            query += " AND status = %s"
            params.append(status)
        
        # Add pagination
        query += " ORDER BY created_at DESC LIMIT %s OFFSET %s"
        params.extend([limit, offset])
        
        cursor.execute(query, params)
        products = cursor.fetchall()
        
        # Get review counts for each product
        for product in products:
            # Get review count from product_reviews table
            cursor.execute("""
                SELECT 
                    COUNT(*) as review_count,
                    AVG(rating) as avg_rating
                FROM product_reviews 
                WHERE product_id = %s
            """, (product["id"],))
            review_stats = cursor.fetchone()
            
            # Add rating and reviews to product dynamically
            product["reviews"] = review_stats["review_count"] if review_stats else 0
            product["rating"] = round(review_stats["avg_rating"], 2) if review_stats and review_stats["avg_rating"] else 0
            
            # Calculate current price based on user type and active offers
            current_time = datetime.now()
            normalize_product_dates(product)
            
            if user_type == "b2c":
                # Check if offer is active
                is_offer_active = (
                    product["b2c_active_offer"] and 
                    product["b2c_offer_price"] > 0 and
                    (product["b2c_offer_start_date"] is None or product["b2c_offer_start_date"] <= current_time) and
                    (product["b2c_offer_end_date"] is None or product["b2c_offer_end_date"] >= current_time)
                )
                
                if is_offer_active:
                    product["current_price"] = product["b2c_offer_price"]
                    if product["b2c_price"] > 0:
                        product["discount_percentage"] = round(
                            (product["b2c_price"] - product["b2c_offer_price"]) / product["b2c_price"] * 100, 2
                        )
                    else:
                        product["discount_percentage"] = 0
                else:
                    product["current_price"] = product["b2c_price"]
                    product["discount_percentage"] = product["b2c_discount"] or 0
                    
                product["original_price"] = product["b2c_price"]
                    
            else:  # b2b
                # Check if offer is active
                is_offer_active = (
                    product["b2b_active_offer"] and 
                    product["b2b_offer_price"] > 0 and
                    (product["b2b_offer_start_date"] is None or product["b2b_offer_start_date"] <= current_time) and
                    (product["b2b_offer_end_date"] is None or product["b2b_offer_end_date"] >= current_time)
                )
                
                if is_offer_active:
                    product["current_price"] = product["b2b_offer_price"]
                    if product["b2b_price"] > 0:
                        product["discount_percentage"] = round(
                            (product["b2b_price"] - product["b2b_offer_price"]) / product["b2b_price"] * 100, 2
                        )
                    else:
                        product["discount_percentage"] = 0
                else:
                    product["current_price"] = product["b2b_price"]
                    product["discount_percentage"] = product["b2b_discount"] or 0
                    
                product["original_price"] = product["b2b_price"]
        
        return {"products": products, "count": len(products)}
    
    finally:
        cursor.close()
        conn.close()
        
# Search products
@app.get("/products/search")
async def search_products(
    query: str,
    limit: int = 20,
    user_type: Optional[str] = None
):
    """
    Search products by name.
    """
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        search_term = f"%{query}%"
        sql_query = """
            SELECT 
                id, name, colors,brand_name, category, description, status, stock, image,
                created_at, updated_at,
                b2c_price, b2b_price, 
                b2c_active_offer, b2b_active_offer,
                b2c_offer_price, b2b_offer_price,
                b2c_discount, b2b_discount,
                b2c_offer_start_date, b2c_offer_end_date,sgst,
                cgst,b2b_offer_start_date, b2b_offer_end_date,
                weight, length, breadth, return_policy,height,hsn,
                compare_at_price,
                info
            FROM products 
            WHERE status = 'Active' 
            AND name ILIKE %s
            ORDER BY created_at DESC
            LIMIT %s
        """
        
        cursor.execute(sql_query, (search_term, limit))
        products = cursor.fetchall()
        
        # Get review counts and format prices
        current_time = datetime.now()
        for product in products:
            cursor.execute("""
                SELECT 
                    COUNT(*) as review_count,
                    AVG(rating) as avg_rating
                FROM product_reviews 
                WHERE product_id = %s
            """, (product["id"],))
            review_stats = cursor.fetchone()
            
            product["reviews"] = review_stats["review_count"] if review_stats else 0
            product["rating"] = round(review_stats["avg_rating"], 2) if review_stats and review_stats["avg_rating"] else 0
            normalize_product_dates(product)
            
            if user_type == "b2c":
                is_offer_active = (
                    product["b2c_active_offer"] and 
                    product["b2c_offer_price"] > 0 and
                    (product["b2c_offer_start_date"] is None or product["b2c_offer_start_date"] <= current_time) and
                    (product["b2c_offer_end_date"] is None or product["b2c_offer_end_date"] >= current_time)
                )
                
                if is_offer_active:
                    product["current_price"] = product["b2c_offer_price"]
                else:
                    product["current_price"] = product["b2c_price"]
            else:  # b2b
                is_offer_active = (
                    product["b2b_active_offer"] and 
                    product["b2b_offer_price"] > 0 and
                    (product["b2b_offer_start_date"] is None or product["b2b_offer_start_date"] <= current_time) and
                    (product["b2b_offer_end_date"] is None or product["b2b_offer_end_date"] >= current_time)
                )
                
                if is_offer_active:
                    product["current_price"] = product["b2b_offer_price"]
                else:
                    product["current_price"] = product["b2b_price"]
        
        return {"query": query, "results": products}
    
    finally:
        cursor.close()
        conn.close()
# Get single product
@app.get("/products/{product_id}")
async def get_product(product_id: str, user_type: Optional[str] = None):
    """
    Get a single product by ID.
    """
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        cursor.execute("""
            SELECT 
                id, name,colors,brand_name, category, description, status, stock, image,
                created_at, updated_at,
                b2c_price, b2b_price, 
                b2c_active_offer, b2b_active_offer,
                b2c_offer_price, b2b_offer_price,
                b2c_discount, b2b_discount,
                b2c_offer_start_date, b2c_offer_end_date,sgst,
                cgst,weight, length, breadth, return_policy,height,
                b2b_offer_start_date, b2b_offer_end_date,
                hsn,
                compare_at_price,info
            FROM products WHERE id = %s
        """, (product_id,))
        product = cursor.fetchone()
        
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")
        
        # Get review stats
        cursor.execute("""
            SELECT 
                COUNT(*) as review_count,
                AVG(rating) as avg_rating
            FROM product_reviews 
            WHERE product_id = %s
        """, (product_id,))
        review_stats = cursor.fetchone()
        
        product["reviews"] = review_stats["review_count"] if review_stats else 0
        product["rating"] = round(review_stats["avg_rating"], 2) if review_stats and review_stats["avg_rating"] else 0
        
        # Format response based on user_type
        current_time = datetime.now()
        normalize_product_dates(product)
        
        if user_type == "b2c":
            # Check if offer is active
            is_offer_active = (
                product["b2c_active_offer"] and 
                product["b2c_offer_price"] > 0 and
                (product["b2c_offer_start_date"] is None or product["b2c_offer_start_date"] <= current_time) and
                (product["b2c_offer_end_date"] is None or product["b2c_offer_end_date"] >= current_time)
            )
            
            if is_offer_active:
                product["current_price"] = product["b2c_offer_price"]
                if product["b2c_price"] > 0:
                    product["discount_percentage"] = round(
                        (product["b2c_price"] - product["b2c_offer_price"]) / product["b2c_price"] * 100, 2
                    )
                else:
                    product["discount_percentage"] = 0
            else:
                product["current_price"] = product["b2c_price"]
                product["discount_percentage"] = product["b2c_discount"] or 0
                
            product["original_price"] = product["b2c_price"]
            
        else:  # b2b
            # Check if offer is active
            is_offer_active = (
                product["b2b_active_offer"] and 
                product["b2b_offer_price"] > 0 and
                (product["b2b_offer_start_date"] is None or product["b2b_offer_start_date"] <= current_time) and
                (product["b2b_offer_end_date"] is None or product["b2b_offer_end_date"] >= current_time)
            )
            
            if is_offer_active:
                product["current_price"] = product["b2b_offer_price"]
                if product["b2b_price"] > 0:
                    product["discount_percentage"] = round(
                        (product["b2b_price"] - product["b2b_offer_price"]) / product["b2b_price"] * 100, 2
                    )
                else:
                    product["discount_percentage"] = 0
            else:
                product["current_price"] = product["b2b_price"]
                product["discount_percentage"] = product["b2b_discount"] or 0
                
            product["original_price"] = product["b2b_price"]
        
        return product
    
    finally:
        cursor.close()
        conn.close()

# ============================ RATING & REVIEW ENDPOINTS ============================

class ReviewCreate(BaseModel):
    rating: float = Field(..., ge=1, le=5)  # Rating between 1 and 5
    comment: Optional[str] = None

@app.post("/products/{product_id}/review")
async def add_review(
    product_id: str,
    review: ReviewCreate,
    current_user_id: str = Depends(get_current_user)
):
    """
    Add a review/rating to a product.
    """
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Check if product exists
        cursor.execute("SELECT id FROM products WHERE id = %s", (product_id,))
        product = cursor.fetchone()
        
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")
        
        # Check if user has already reviewed this product
        cursor.execute("""
            SELECT id FROM product_reviews 
            WHERE product_id = %s AND user_id = %s
        """, (product_id, current_user_id))
        
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="You have already reviewed this product")
        
        # Insert review
        review_id = str(uuid.uuid4())
        cursor.execute("""
            INSERT INTO product_reviews 
            (id, product_id, user_id, rating, comment, created_at)
            VALUES (%s, %s, %s, %s, %s, NOW())
        """, (review_id, product_id, current_user_id, review.rating, review.comment))
        
        # Calculate new average rating and review count
        cursor.execute("""
            SELECT 
                COUNT(*) as review_count,
                AVG(rating) as avg_rating
            FROM product_reviews 
            WHERE product_id = %s
        """, (product_id,))
        review_stats = cursor.fetchone()
        
        new_review_count = review_stats["review_count"] if review_stats else 0
        new_average_rating = round(review_stats["avg_rating"], 2) if review_stats and review_stats["avg_rating"] else 0
        
        # Note: Your products table doesn't have 'rating' and 'reviews' columns
        # If you want to store these in products table, you need to add them
        # For now, we'll just return the stats
        
        conn.commit()
        
        return {
            "message": "Review added successfully",
            "review_id": review_id,
            "new_rating": new_average_rating,
            "total_reviews": new_review_count
        }
    
    finally:
        cursor.close()
        conn.close()

@app.get("/products/{product_id}/reviews")
async def get_product_reviews(
    product_id: str,
    limit: int = 10,
    offset: int = 0
):
    """
    Get reviews for a specific product.
    """
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Check if product exists
        cursor.execute("SELECT id FROM products WHERE id = %s", (product_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Product not found")
        
        # Get reviews with user information
        query = """
            SELECT 
                pr.id, pr.rating, pr.comment, pr.created_at,
                au.email, au.full_name
            FROM product_reviews pr
            LEFT JOIN auth_users au ON pr.user_id = au.id::text
            WHERE pr.product_id = %s
            ORDER BY pr.created_at DESC
            LIMIT %s OFFSET %s
        """
        
        cursor.execute(query, (product_id, limit, offset))
        reviews = cursor.fetchall()
        
        # Get total count and average rating
        cursor.execute("""
            SELECT 
                COUNT(*) as total,
                AVG(rating) as avg_rating
            FROM product_reviews 
            WHERE product_id = %s
        """, (product_id,))
        stats = cursor.fetchone()
        
        return {
            "reviews": reviews,
            "total": stats["total"] if stats else 0,
            "average_rating": round(stats["avg_rating"], 2) if stats and stats["avg_rating"] else 0,
            "limit": limit,
            "offset": offset
        }
    
    finally:
        cursor.close()
        conn.close()
class ReviewUpdate(BaseModel):
    rating: float = Field(..., ge=1, le=5)
    comment: Optional[str] = None


@app.put("/reviews/{review_id}")
async def update_review(
    review_id: str,
    review: ReviewUpdate,
    current_user_id: str = Depends(get_current_user)
):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    try:
        cursor.execute("""
            SELECT id FROM product_reviews
            WHERE id = %s AND user_id = %s
        """, (review_id, current_user_id))

        if not cursor.fetchone():
            raise HTTPException(status_code=403, detail="Not allowed")

        cursor.execute("""
            UPDATE product_reviews
            SET rating = %s, comment = %s
            WHERE id = %s
        """, (review.rating, review.comment, review_id))

        conn.commit()
        return {"message": "Review updated successfully"}

    finally:
        cursor.close()
        conn.close()
@app.delete("/reviews/{review_id}")
async def delete_review(
    review_id: str,
    current_user_id: str = Depends(get_current_user)
):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    try:
        cursor.execute("""
            DELETE FROM product_reviews
            WHERE id = %s AND user_id = %s
        """, (review_id, current_user_id))

        if cursor.rowcount == 0:
            raise HTTPException(status_code=403, detail="Not allowed")

        conn.commit()
        return {"message": "Review deleted successfully"}

    finally:
        cursor.close()
        conn.close()
def get_shipping_zone(origin_pin: str, destination_pin: str) -> str:
    """
    Very simple zone logic:
    - Same first 3 digits → Local
    - Same first 2 digits → Zonal
    - Else → National
    """
    if origin_pin[:3] == destination_pin[:3]:
        return ZONE_LOCAL
    elif origin_pin[:2] == destination_pin[:2]:
        return ZONE_ZONAL
    else:
        return ZONE_NATIONAL           
def check_pincode_serviceability(pincode: str):
    url = f"{DELHIVERY_BASE_URL}/c/api/pin-codes/json/"  # pincode
    params = {"filter_codes": pincode}
    headers = {"Authorization": f"Token {DELHIVERY_TOKEN}"}

    res = requests.get(url, params=params, headers=headers, timeout=5)

    if res.status_code != 200:
        return {
            "serviceable": False,
            "reason": "Serviceability check failed"
        }

    data = res.json()
    pincodes = data.get("delivery_codes", [])

    if not pincodes:
        return {
            "serviceable": False,
            "reason": "NSZ (Non-serviceable pincode)"
        }

    pincode_info = pincodes[0].get("postal_code", {})
    remark = pincode_info.get("remarks", "")

    if remark.lower() == "embargo":
        return {
            "serviceable": False,
            "reason": "Temporarily unavailable (Embargo)"
        }

    return {
        "serviceable": True,
        "reason": "Serviceable"
    }
        

# ============================ SHIPPING ESTIMATION (DELHIVERY) ============================
@app.post("/shipping/delhivery/estimate")
async def calculate_shipping(payload: dict):
    
    # 1. DEFINE THIS FIRST so it can be used in the 'except' blocks below
    def calculate_mock_shipping(weight: float, zone: str) -> float:
        """
        Zone-based slab pricing aligned with Delhivery Surface B2C logic
        """
        rate_card = DELHIVERY_SURFACE_RATE_CARD.get(zone)
        if not rate_card:
            raise ValueError("Invalid shipping zone")

        # Slab pricing
        for slab_weight, price in rate_card["slabs"]:
            if weight <= slab_weight:
                return price

        # Incremental pricing after last slab (10 kg)
        last_slab_weight, last_slab_price = rate_card["slabs"][-1]
        extra_kg = math.ceil(weight - last_slab_weight)
        return last_slab_price + (extra_kg * rate_card["extra_per_kg"])

    # ---------------- BASIC VALIDATION ----------------
    if not DELHIVERY_TOKEN or not DELHIVERY_PICKUP_PIN:
        raise HTTPException(status_code=500, detail="Delhivery not configured")

    delivery_pin = payload.get("delivery_pincode") or payload.get("delivery_pin")
    if not delivery_pin:
        raise HTTPException(status_code=400, detail="Missing delivery pincode")

    items = payload.get("items", [])
    if not items:
        raise HTTPException(status_code=400, detail="No items in payload")
        
    serviceability = check_pincode_serviceability(str(delivery_pin))

    if not serviceability["serviceable"]:
        return {
            "shipping_available": False,
            "shipping_fee": None,
            "reason": serviceability["reason"]
        }
    # ---------------- WEIGHT CALCULATION ----------------
    total_weight = 0.0
    total_vol_weight = 0.0

    for item in items:
        try:
            qty = int(item.get("quantity", 1))
            weight = float(item.get("weight", 0)) * qty
            length = float(item.get("length", 0))
            breadth = float(item.get("breadth", 0))
            height = float(item.get("height", 0))

            vol_weight = (length * breadth * height) / 5000 * qty

            total_weight += weight
            total_vol_weight += vol_weight
        except Exception:
            raise HTTPException(status_code=400, detail="Invalid item data")

     # ---------------- CHARGEABLE WEIGHT (ECOMMERCE STANDARD) ----------------
    raw_weight = max(total_weight, total_vol_weight)
         # Delhivery / E-commerce rounding rules
    if raw_weight <= 0.5:
              chargeable_weight = 0.5
    elif raw_weight <= 1:
                chargeable_weight = 1
    else:
          chargeable_weight = math.ceil(raw_weight)  # ALWAYS round UP
    weight_in_grams = int(chargeable_weight * 1000)
   # ----------------- ZONE CALCULATION -----------------
    zone = get_shipping_zone(
    str(DELHIVERY_PICKUP_PIN),
    str(delivery_pin)
    )
    # ---------------- DELHIVERY API (STAGING) ----------------
    url = f"{DELHIVERY_BASE_URL}/api/kinko/v1/invoice/charges/.json"  
    params = {
        "md": "S", 
        "ss": "Delivered",
        "d_pin": str(delivery_pin),
        "o_pin": str(DELHIVERY_PICKUP_PIN),
        "cgm": weight_in_grams,
        "pt": "Pre-paid",
        "cl": "LogeswaranCSURFACE-B2C"
    }

    headers = {
        "Authorization": f"Token {DELHIVERY_TOKEN}",
        "Accept": "application/json"
    }

    # Initialize defaults
    shipping_fee = 0.0
    pricing_source = "delhivery"
    data = {}

    try:
        res = requests.get(url, params=params, headers=headers, verify=True, timeout=10)
        
        if res.status_code != 200:
            print(f"Delhivery API Error ({res.status_code}): {res.text}")
            shipping_fee = calculate_mock_shipping(chargeable_weight)
            pricing_source = "mock"
            data = {"error": "API Error", "details": res.text}
        else:
            data = res.json()
            # Extract fee from list response
            if isinstance(data, list) and data:
                 shipping_fee = float(data[0].get("total_amount", 0))
            elif isinstance(data, dict):
                 shipping_fee = float(data.get("charges", {}).get("total_amount", 0))
            # If API returned 0, use mock
            if shipping_fee <= 0:
                shipping_fee = calculate_mock_shipping(chargeable_weight, zone)
                pricing_source = "mock"

    except Exception as e:
        print(f"Exception during API call: {e}")
        shipping_fee = calculate_mock_shipping(chargeable_weight , zone)
        pricing_source = "mock"
        data = {"error": "Connection failed", "details": str(e)}

    # ---------------- FINAL RESPONSE ----------------
    return {
        "shipping_fee": shipping_fee,
        "chargeable_weight": chargeable_weight,
        "weight_in_grams": weight_in_grams,
        "pricing_source": pricing_source,
        "raw_response": data,
        "note": "Mock pricing applied as fallback" if pricing_source == "mock" else "Live pricing applied"
    }

# ============================ ORDER PLACEMENT ============================
def map_order_status_for_app(db_status: str) -> str:
    if db_status in ["Pending", "Confirmed", "Processing"]:
        return "Ordered"
    return db_status or "Ordered"
@app.post("/orders/place")
async def place_order_from_app(order_data: OrderCreate, current_user_id: str = Depends(get_current_user)):
    """
    Receives a complete order object from the Flutter app and saves it to the PostgreSQL 'orders' table.
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    created_order_items = []
    
    try:
        actual_order_status = "Pending"

        # Get user type from token
        actual_customer_type = order_data.customer_type or "b2c"


        # Extract order-level dimensions and HSN (use values from first product or calculate aggregate)
        hsn_code = ""
        total_weight = 0
        total_height = 0
        total_length = 0
        total_breadth = 0
        
        if order_data.products and len(order_data.products) > 0:
            # Get HSN from first product (or you can aggregate differently)
            hsn_code = getattr(order_data.products[0], "hsnCode", "")
            original_price = 0.0
            # Calculate totals for the entire order
            for product in order_data.products:
                total_weight += getattr(product, "weightKg", 0)
                total_height += getattr(product, "heightCm", 0)
                total_length += getattr(product, "lengthCm", 0)
                total_breadth += getattr(product, "breadthCm", 0)
                original_price += product.price  * product.quantity 

        # 1. Insert order with dimensions and HSN in separate columns
        cursor.execute("""
        INSERT INTO orders (
            order_id, customer, email, phone, amount, shipping_fee,
            state_gst_amount, central_gst_amount, sgst_percentage, cgst_percentage,
            items_count, customer_type, status, payment, payment_method, products,
            created_at, address, hsn, weight, height, length, breadth, city, state, pincode, original_price,customer_name
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING id
        """, (
            order_data.order_id,
            current_user_id,
            order_data.customer_email,
            order_data.phone,
            order_data.total_price,
            order_data.shipping_fee,
            order_data.state_gst_amount,
            order_data.central_gst_amount,
            order_data.sgst_percentage,  
            order_data.cgst_percentage,
            len(order_data.products),
            actual_customer_type,
            actual_order_status,
            order_data.payment_status,
            order_data.payment_method,
            '[]',  # Empty array initially
            datetime.strptime(order_data.placed_on, '%d/%m/%Y').strftime('%Y-%m-%d %H:%M:%S'),
            order_data.customer_address_text,
            hsn_code,
            total_weight,
            total_height,
            total_length,
            total_breadth,
            order_data.city,
            order_data.state,
            order_data.pincode,
            original_price,
            order_data.customer_name
        ))
        
        db_order_id = cursor.fetchone()[0]

        # 2. Insert each product (without dimensions in product JSON if not needed)
        for product in order_data.products:
            cursor.execute("""
            INSERT INTO order_items (
                order_id, product_name, image, unit_price, quantity, item_total
            ) VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING id
            """, (
                order_data.order_id,
                product.name,
                product.imageUrl,
                product.price,
                product.quantity,
                product.price * product.quantity
            ))
            
            product.order_item_id = cursor.fetchone()[0]

            created_order_items.append({ 
                "order_item_id": product.order_item_id,
                "colorHex": product.colorHex,
                "name": product.name,
                "imageUrl": product.imageUrl,
                "price": product.price,
                "quantity": product.quantity,
                "item_total": product.price * product.quantity,
            })

        # 3. Build products JSON
        items_json_string = json.dumps(created_order_items)

        # 4. Update orders row with real JSON
        cursor.execute("UPDATE orders SET products=%s WHERE id=%s", (items_json_string, db_order_id))

        # 5. Commit transaction
        conn.commit()

        return {
            "message": "Order saved successfully",
            "order_id": order_data.order_id,
            "user_id_saved_as_customer": current_user_id,
            "payment_status": order_data.payment_status,
            "created_order_items": created_order_items
        }

    except Exception as e:
        conn.rollback()
        print(f"Error saving order: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Failed to save order: {str(e)}")

    finally:
        cursor.close()
        conn.close()

@app.get("/orders/user/{user_email}")
async def get_orders_by_user(
    user_email: str,
    current_user_id: str = Depends(get_current_user)
):
    """
    Get all orders for a specific user by email.
    IMPORTANT: The email is stored in the 'phone' column due to data mapping issue.
    """
    import json
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    try:
        print(f"🔍 DEBUG: Looking for user with email '{user_email}'")
        
        # Search in phone column (where email is actually stored for av@gmail.com)
        cursor.execute("""
            SELECT * FROM orders 
            WHERE email = %s 
            ORDER BY created_at DESC
        """, (user_email,))
        orders = cursor.fetchall()
        
        print(f"🔍 DEBUG: Found {len(orders)} orders")
        
        formatted_orders = []

        for order in orders:
            print(f"🔍 DEBUG: Processing order ID: {order['id']}")
            print(f"🔍 DEBUG: Raw products data type: {type(order.get('products'))}")
            print(f"🔍 DEBUG: Raw products data: {order.get('products')}")
            
            items = []
            products_data = order.get('products')
            
            if products_data:
                try:
                    # Handle different JSON formats
                    if isinstance(products_data, str):
                        # Clean the string
                        cleaned = products_data.strip()
                        print(f"🔍 DEBUG: Cleaned string: {cleaned}")
                        
                        # Check if it's a JSON array string
                        if cleaned.startswith('[') and cleaned.endswith(']'):
                            # Direct JSON array
                            products_list = json.loads(cleaned)
                        elif cleaned.startswith('"[') and cleaned.endswith(']"'):
                            # Remove outer quotes first
                            inner = cleaned[1:-1]
                            products_list = json.loads(inner)
                        else:
                            # Try to parse as-is
                            products_list = json.loads(cleaned)
                    elif isinstance(products_data, list):
                        # Already a list
                        products_list = products_data
                    else:
                        products_list = []
                    
                    print(f"🔍 DEBUG: Parsed products_list type: {type(products_list)}")
                    print(f"🔍 DEBUG: Parsed products_list: {products_list}")
                    
                    # Process each product
                    for product_item in products_list:
                        try:
                            if isinstance(product_item, str):
                                # Parse the string JSON
                                product_dict = json.loads(product_item)
                            else:
                                product_dict = product_item
                            
                            print(f"🔍 DEBUG: Product dict: {product_dict}")
                            
                            # Extract product info with defaults
                            item_total = float(product_dict.get('price', 0)) * int(product_dict.get('quantity', 1))
                            
                            items.append({
                                'order_item_id': product_dict.get('order_item_id', 0),
                                'name': product_dict.get('name', 'Product'),
                                'imageUrl': product_dict.get('imageUrl', ''),
                                'price': float(product_dict.get('price', 0)),
                                'quantity': int(product_dict.get('quantity', 1)),
                                'item_total': item_total,
                                # Include additional fields for Flutter
                                'colorHex': product_dict.get('colorHex', 'FFFFFFFF'),
                                'hsnCode': product_dict.get('hsnCode', ''),
                                'weightKg': float(product_dict.get('weightKg', 0)),
                                'lengthCm': float(product_dict.get('lengthCm', 0)),
                                'breadthCm': float(product_dict.get('breadthCm', 0)),
                                'heightCm': float(product_dict.get('heightCm', 0))
                            })
                            
                        except Exception as e:
                            print(f"❌ Error parsing individual product: {e}")
                            import traceback
                            traceback.print_exc()
                    
                    print(f"✅ DEBUG: Successfully parsed {len(items)} items")
                    
                except Exception as e:
                    print(f"❌ Error parsing products: {e}")
                    import traceback
                    traceback.print_exc()
            
            # Determine correct email and phone (they're swapped)
            actual_email = order.get('phone')  # Email is in phone column
            actual_phone = order.get('email')  # Phone is in email column
            
            # Get the order date (use created_at)
            order_date = order.get('created_at')
            if order_date:
                date_str = order_date.strftime('%Y-%m-%d')
            else:
                date_str = ''
            
            # Ensure amount is float
            amount = order.get('amount', 0)
            if amount is None:
                amount = 0.0
            elif not isinstance(amount, (int, float)):
                try:
                    amount = float(amount)
                except:
                    amount = 0.0
            
            # Build the order response
            order_response = {
                'id': str(order.get('id', '')),
                'order_id': str(order.get('order_id', '')),  # Add order_id for display
                'customer': order.get('customer', ''),
                'email': actual_email,
                'amount': float(amount),
                'items_count': order.get('items_count', len(items)),
                'customer_type': order.get('customer_type', 'b2c'),
                'type': order.get('customer_type', 'b2c'),
                'status': map_order_status_for_app(order.get('status')),
                'payment_status': order.get('payment', 'pending'),
                'payment_method': order.get('payment_method', ''),
                'date': date_str,
                'address': order.get('address', ''),
                'phone': actual_phone,
                'state_gst_amount': float(order.get('state_gst_amount', 0) or 0),
                'central_gst_amount': float(order.get('central_gst_amount', 0) or 0),
                'shipping_fee': float(order.get('shipping_fee', 0) or 0),
                'items': items  # Changed from 'order_items' to 'items'
            }
            
            print(f"✅ DEBUG: Order response keys: {list(order_response.keys())}")
            print(f"✅ DEBUG: Order has {len(items)} items")
            
            formatted_orders.append(order_response)

        print(f"✅ DEBUG: Returning {len(formatted_orders)} formatted orders")
        return {
            "success": True,
            "orders": formatted_orders,
            "count": len(orders)
        }

    except Exception as e:
        print(f"❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Failed to fetch orders: {str(e)}")

    finally:
        cursor.close()
        conn.close()
# ============================ RETURN REQUESTS ============================
@app.post("/returns/refund")
async def create_refund(
    order_item_id: int = Form(...),
    reason: str = Form(...),
    details: str = Form(""),
    payment_method: str = Form(...),
    refund_amount: float = Form(...),
    quantity: int = Form(1),
    images: List[UploadFile] = File(...),
    current_user: str = Depends(get_current_user)
):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        print(f"=== DEBUG: Starting refund request ===")
        print(f"DEBUG: order_item_id={order_item_id}, reason={reason}")
        print(f"DEBUG: details={details}, payment_method={payment_method}")
        print(f"DEBUG: refund_amount={refund_amount}, quantity={quantity}")
        print(f"DEBUG: current_user={current_user}")
        print(f"DEBUG: Number of images: {len(images)}")

        # === Upload images ===
        image_urls = []
        for i, file in enumerate(images):
            print(f"DEBUG: Processing image {i+1}: {file.filename}")
            if file and file.filename:
                ext = file.filename.rsplit(".", 1)[-1]
                filename = f"{uuid.uuid4()}.{ext}"
                path = os.path.join(UPLOAD_FOLDER, filename)
                print(f"DEBUG: Saving image to: {path}")
                
                try:
                    with open(path, "wb") as f:
                        content = await file.read()
                        f.write(content)
                        print(f"DEBUG: Image saved successfully: {filename}, size: {len(content)} bytes")
                    image_urls.append(f"{BASE_URL.rstrip('/')}/uploads/{filename}")
                except Exception as img_error:
                    print(f"DEBUG: Error saving image: {str(img_error)}")
                    raise

        images_json = json.dumps(image_urls)
        print(f"DEBUG: Image URLs JSON: {images_json}")

        # === Get user ===
        print(f"DEBUG: Fetching user with ID: {current_user}")
        cursor.execute(
            "SELECT email, full_name FROM auth_users WHERE id = %s",
            (current_user,)
        )
        user = cursor.fetchone()
        if not user:
            print(f"DEBUG: User not found for ID: {current_user}")
            raise HTTPException(404, "User not found")

        email, customer_name = user
        print(f"DEBUG: User email: {email}, name: {customer_name}")

        # === Debug: Check database structure ===
        print(f"DEBUG: Checking database for order_item_id={order_item_id}")
        cursor.execute("""
            SELECT 
                oi.id as oi_id,
                oi.order_id as oi_order_id,
                oi.quantity as oi_quantity,
                oi.product_name,
                oi.unit_price,
                o.order_id as o_order_id,
                o.customer as o_customer,
                o.email as o_email
            FROM order_items oi
            LEFT JOIN orders o ON o.order_id = oi.order_id
            WHERE oi.id = %s
        """, (order_item_id,))

        debug_row = cursor.fetchone()
        if debug_row:
            # Since it's a tuple, access by position
            print(f"DEBUG: Found order item row: {debug_row}")
            print(f"DEBUG: Order email field (position 7): {debug_row[7] if len(debug_row) > 7 else 'N/A'}")
            print(f"DEBUG: Looking for email: {email}")
            print(f"DEBUG: Note: orders.email contains phone number: {debug_row[7]}")
        else:
            print(f"DEBUG: No order item found with id={order_item_id}")

        # === Validate ownership ===
        print(f"DEBUG: Validating order item {order_item_id} for user {current_user}")
        
        # Correct query based on your schema
        cursor.execute("""
            SELECT 
                oi.order_id as  business_order_id,
                oi.quantity,
                oi.product_name,
                oi.unit_price
            FROM order_items oi
            JOIN orders o ON o.order_id = oi.order_id
            WHERE oi.id = %s AND o.customer = %s
        """, (order_item_id, current_user))

        row = cursor.fetchone()
        if not row:
            print(f"DEBUG: Order item {order_item_id} not found for user {current_user}")
            raise HTTPException(403, "Invalid order item")

        # FIXED: Changed 'price' to 'row'
        order_id, original_qty, product_name, unit_price = row
        
        print(f"DEBUG: Found order - order_id: {order_id}, original_qty: {original_qty}")
        print(f"DEBUG: product_name: {product_name}, unit_price: {unit_price}")

        # === Quantity check ===
        print(f"DEBUG: Checking quantity: requested={quantity}, available={original_qty}")
        if quantity < 1 or quantity > original_qty:
            error_msg = f"Invalid quantity: {quantity} (available: {original_qty})"
            print(f"DEBUG: {error_msg}")
            raise HTTPException(400, error_msg)

        # === Existing refunds ===
        cursor.execute("""
            SELECT COALESCE(SUM(quantity),0)
            FROM refunds
            WHERE order_item_id = %s
              AND status NOT IN ('Rejected','Cancelled')
        """, (order_item_id,))
        already_refunded = cursor.fetchone()[0]
        print(f"DEBUG: Already refunded quantity: {already_refunded}")

        if already_refunded + quantity > original_qty:
            error_msg = f"Quantity exceeds limit: {already_refunded + quantity} > {original_qty}"
            print(f"DEBUG: {error_msg}")
            raise HTTPException(400, error_msg)

        # === Amount validation ===
        expected = float(unit_price) * quantity
        refund_amount = round(expected, 2)
        print(f"DEBUG: Calculated refund amount: {refund_amount} ({unit_price} * {quantity})")

        # === Insert refund ===
        print(f"DEBUG: Inserting refund into database...")
        cursor.execute("""
        INSERT INTO refunds (
        order_id,
        order_item_id,
        customer,
        email,
        reason,
        description,
        payment_method,
        amount,
        proof_image_path,
        type,
        product_name,
        quantity,
        status
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING id
        """, (
        order_id,
        order_item_id,
        current_user,
        email,
        reason,
        details,           # description
        payment_method,
        refund_amount,     # amount
        images_json,       # proof_image_path
        'refund',          # type
        product_name,
        quantity,
        'Pending'    
        ))

        refund_id = cursor.fetchone()[0]
        print(f"DEBUG: Refund created with ID: {refund_id}")

        # === Update item status ===
        total = already_refunded + quantity
        status = "returned" if total >= original_qty else "partial_returned"
        print(f"DEBUG: Updating order item status to: {status}")

        cursor.execute(
            "UPDATE order_items SET status=%s WHERE id=%s",
            (status, order_item_id)
        )

        conn.commit()
        print(f"DEBUG: Transaction committed successfully")
        return {"success": True, "refund_id": refund_id}

    except HTTPException as http_err:
        print(f"DEBUG: HTTP Exception: {http_err.status_code} - {http_err.detail}")
        conn.rollback()
        raise http_err
    except Exception as e:
        print(f"=== DEBUG: UNEXPECTED ERROR ===")
        print(f"DEBUG: Error type: {type(e).__name__}")
        print(f"DEBUG: Error message: {str(e)}")
        print(f"DEBUG: Full traceback:")
        import traceback
        traceback.print_exc()
        
        conn.rollback()
        raise HTTPException(500, f"Internal server error: {str(e)}")
    finally:
        cursor.close()
        conn.close()
        print(f"=== DEBUG: Refund request completed ===")

@app.post("/returns/exchange")
async def create_exchange(
    order_item_id: int = Form(...),
    reason: str = Form(...),
    details: str = Form(""),
    quantity: int = Form(1),
    variant_color: str = Form(None), 
    images: List[UploadFile] = File(...),
    current_user: str = Depends(get_current_user)
):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        print(f"=== DEBUG: Starting exchange request ===")
        print(f"DEBUG: order_item_id={order_item_id}, reason={reason}")
        print(f"DEBUG: details={details}, quantity={quantity}")
        print(f"DEBUG: current_user={current_user}")
        print(f"DEBUG: Number of images: {len(images)}")

        # === Upload images ===
        image_urls = []
        for file in images:
            if file and file.filename:
                ext = file.filename.rsplit(".", 1)[-1]
                name = f"{uuid.uuid4()}.{ext}"
                path = os.path.join(UPLOAD_FOLDER, name)
                with open(path, "wb") as f:
                    f.write(await file.read())
                image_urls.append(f"{BASE_URL.rstrip('/')}/uploads/{name}")

        images_json = json.dumps(image_urls)

        # === User ===
        cursor.execute(
            "SELECT email FROM auth_users WHERE id=%s",
            (current_user,)
        )
        user = cursor.fetchone()
        if not user:
            raise HTTPException(404, "User not found")
        email = user[0]

        # === Ownership ===
        # FIXED: Changed to check by customer UUID
        cursor.execute("""
            SELECT 
         oi.order_id,
         oi.quantity,
         oi.product_name,
         oi.unit_price
         FROM order_items oi
        JOIN orders o ON o.order_id = oi.order_id
        WHERE oi.id = %s AND o.customer = %s

        """, (order_item_id, current_user))

        row = cursor.fetchone()
        if not row:
            raise HTTPException(403, "Invalid order item")

        business_order_id, original_qty, product_name, price = row  # FIXED: variable name

        # === Quantity check ===
        cursor.execute("""
            SELECT COALESCE(SUM(quantity),0)
            FROM exchanges
            WHERE order_item_id=%s
              AND status NOT IN ('rejected','cancelled','completed')
        """, (order_item_id,))
        used = cursor.fetchone()[0]

        if used + quantity > original_qty:
            raise HTTPException(400, "Quantity exceeded")

        # === Insert exchange ===
        cursor.execute("""
        INSERT INTO exchanges (
        order_id,
        order_item_id,
        customer,
        email,
        reason,
        description,
        proof_image_path,
        type,
        product_name,
        variant_color,
        price,
        quantity,
        status
        ) VALUES (
        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
        )
        """, (
        business_order_id,
        order_item_id,
        current_user,
        email,
        reason,
        details,           # This maps to 'description'
        images_json,       # This maps to 'proof_image_path'
        'exchange',        # This maps to 'type'
        product_name,
        variant_color,
        price,
        quantity,
        'Pending'          # This maps to 'status'
   ))

        # === Update item status ===
        total = used + quantity
        status = "exchanged" if total >= original_qty else "partial_exchanged"

        cursor.execute(
            "UPDATE order_items SET status=%s WHERE id=%s",
            (status, order_item_id)
        )

        conn.commit()
        return {"success": True, "message": "Exchange created"}

    except Exception as e:
        conn.rollback()
        print(f"DEBUG: Exchange error: {str(e)}")
        raise HTTPException(500, str(e))
    finally:
        cursor.close()
        conn.close()

@app.get("/refunds/user")
async def get_user_refunds(
    current_user: str = Depends(get_current_user)
):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cursor.execute("""
            SELECT *
            FROM refunds
            WHERE customer = %s
            ORDER BY created_at DESC
        """, (current_user,))

        rows = cursor.fetchall()

        for r in rows:
            # Format dates
            if r.get("created_at"):
                r["created_at"] = r["created_at"].strftime('%Y-%m-%d')
            if r.get("updated_at"):
                r["updated_at"] = r["updated_at"].strftime('%Y-%m-%d')

            # Handle images
            if r.get("proof_image_path"):
                try:
                    r["images"] = json.loads(r["proof_image_path"])
                except json.JSONDecodeError:
                    r["images"] = [r["proof_image_path"]] if r["proof_image_path"] else []
            else:
                r["images"] = []

        return {"success": True, "refunds": rows}

    except Exception as e:
        print(f"ERROR fetching user refunds for user {current_user}: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to fetch refund history")
    finally:
        cursor.close()
        conn.close()


@app.get("/returns/order/{order_id}")
async def get_returns_by_order(
    order_id: str,
    current_user: str = Depends(get_current_user)
):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cursor.execute("""
            SELECT *
            FROM refunds
            WHERE order_id = %s
              AND customer = %s
            ORDER BY created_at DESC
        """, (order_id, current_user))

        data = cursor.fetchall()

        for r in data:
            # Format dates
            if r.get("created_at"):
                r["created_at"] = r["created_at"].strftime('%Y-%m-%d')
            if r.get("updated_at"):
                r["updated_at"] = r["updated_at"].strftime('%Y-%m-%d')

            # Handle images
            if r.get("proof_image_path"):
                try:
                    r["images"] = json.loads(r["proof_image_path"])
                except json.JSONDecodeError:
                    r["images"] = [r["proof_image_path"]] if r["proof_image_path"] else []
            else:
                r["images"] = []

        return {
            "success": True,
            "returns": data,
            "count": len(data)  # added for consistency with exchanges
        }

    except Exception as e:
        print(f"RETURN ORDER FETCH ERROR for order {order_id}, user {current_user}: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to fetch order returns")
    finally:
        cursor.close()
        conn.close()


@app.get("/exchanges/user")
async def get_user_exchanges(
    current_user: str = Depends(get_current_user)
):
    """
    Get all exchange requests for the current user
    """
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cursor.execute("""
            SELECT *
            FROM exchanges
            WHERE customer = %s
            ORDER BY created_at DESC
        """, (current_user,))

        rows = cursor.fetchall()

        for exchange in rows:
            # Format dates
            if exchange.get("created_at"):
                exchange["created_at"] = exchange["created_at"].strftime('%Y-%m-%d')
            if exchange.get("updated_at"):
                exchange["updated_at"] = exchange["updated_at"].strftime('%Y-%m-%d')

            # Fixed: Proper try-except for image parsing (removed broken else)
            if exchange.get("proof_image_path"):
                try:
                    exchange["images"] = json.loads(exchange["proof_image_path"])
                except json.JSONDecodeError:
                    exchange["images"] = [exchange["proof_image_path"]] if exchange["proof_image_path"] else []
            else:
                exchange["images"] = []

        return {
            "success": True, 
            "exchanges": rows, 
            "count": len(rows)
        }

    except Exception as e:
        print(f"EXCHANGE USER FETCH ERROR for user {current_user}: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to fetch exchange history")
    finally:
        cursor.close()
        conn.close()


@app.get("/exchanges/order/{order_id}")
async def get_exchanges_by_order(
    order_id: str,
    current_user: str = Depends(get_current_user)
):
    """
    Get exchange requests for a specific order belonging to current user
    """
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cursor.execute("""
            SELECT *
            FROM exchanges
            WHERE order_id = %s
              AND customer = %s
            ORDER BY created_at DESC
        """, (order_id, current_user))

        data = cursor.fetchall()

        for exchange in data:
            # Format dates
            if exchange.get("created_at"):
                exchange["created_at"] = exchange["created_at"].strftime('%Y-%m-%d')
            if exchange.get("updated_at"):
                exchange["updated_at"] = exchange["updated_at"].strftime('%Y-%m-%d')

            # Fixed: Use correct key "proof_image_path"
            if exchange.get("proof_image_path"):
                try:
                    exchange["images"] = json.loads(exchange["proof_image_path"])
                except json.JSONDecodeError:
                    exchange["images"] = [exchange["proof_image_path"]] if exchange["proof_image_path"] else []
            else:
                exchange["images"] = []

        return {
            "success": True,
            "exchanges": data,
            "count": len(data)
        }

    except Exception as e:
        print(f"EXCHANGE ORDER FETCH ERROR for order {order_id}, user {current_user}: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to fetch order exchanges")
    finally:
        cursor.close()
        conn.close()

# ============================ RAZORPAY PAYMENT INTEGRATION ============================

@app.post("/payment/create-order")
async def create_razorpay_order(
    payment_data: CreatePaymentRequest,
    current_user_id: str = Depends(get_current_user)
):
    """
    Create a RazorPay order for payment
    """
    try:
        # Convert amount to paise (RazorPay expects amount in smallest currency unit)
        amount_in_paise = int(payment_data.amount * 100)
        
        # Create receipt if not provided
        receipt = payment_data.receipt or f"receipt_{datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        # Create RazorPay order
        razorpay_order = razorpay_client.order.create({
            'amount': amount_in_paise,
            'currency': payment_data.currency,
            'receipt': receipt,
            'notes': payment_data.notes or {},
            'payment_capture': 1  # Auto-capture payment
        })
        
        return {
            "success": True,
            "order_id": razorpay_order['id'],
            "amount": razorpay_order['amount'],
            "currency": razorpay_order['currency'],
            "key": RAZORPAY_KEY_ID,
            "notes": razorpay_order.get('notes', {})
        }
        
    except Exception as e:
        print(f"Error creating RazorPay order: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to create payment order: {str(e)}")

@app.post("/payment/verify")
async def verify_payment(payload: VerifyPaymentRequest):
    try:
        # Step 1: Verify Razorpay signature
        generated_signature = hmac.new(
            RAZORPAY_KEY_SECRET.encode(),
            f"{payload.razorpay_order_id}|{payload.razorpay_payment_id}".encode(),
            hashlib.sha256
        ).hexdigest()

        if generated_signature != payload.razorpay_signature:
            raise HTTPException(status_code=400, detail="Invalid payment signature")
        payment = razorpay_client.payment.fetch(payload.razorpay_payment_id)
        actual_payment_method = payment.get("method")  # card, netbanking, upi, wallet
    

        # ✅ Step 2: Payment is verified
        # ❌ DO NOT CHECK DB HERE

        return {
            "success": True,
            "message": "Payment verified successfully",
            "order_id": payload.order_id,
            "razorpay_payment_id": payload.razorpay_payment_id,
            "payment_method": actual_payment_method
        }

    except HTTPException:
        raise
    except Exception as e:
        print("Error verifying payment:", e)
        raise HTTPException(status_code=500, detail="Payment verification failed")


@app.get("/payment/order-status/{order_id}")
async def get_payment_status(order_id: str):
    """
    Check payment status for an order
    """
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        cursor.execute("""
            SELECT id, payment_status,
                   amount, email, date
            FROM orders 
            WHERE id = %s
        """, (order_id,))
        
        order = cursor.fetchone()
        
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
        
        return {
            "success": True,
            "order_id": order['id'],
            "payment_status": order['payment_status'],
            "amount": float(order['amount']) if order['amount'] else 0.0,
            "email": order['email'],
            "date": order['date'].strftime('%Y-%m-%d %H:%M:%S') if order['date'] else None
        }
        
    except Exception as e:
        print(f"Error fetching payment status: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch payment status: {str(e)}")
    finally:
        cursor.close()
        conn.close()

@app.post("/payment/create-for-order/{order_id}")
async def create_payment_for_order(
    order_id: str,
    payload: CreatePaymentRequest
):
    try:
        amount_in_paise = int(payload.amount * 100)

        razorpay_order = razorpay_client.order.create({
            "amount": amount_in_paise,
            "currency": "INR",
            "receipt": f"receipt_{order_id}",
            "payment_capture": 1
        })

        return {
            "success": True,
            "razorpay_order_id": razorpay_order["id"],
            "amount": razorpay_order["amount"],
            "currency": razorpay_order["currency"],
            "key": RAZORPAY_KEY_ID
        }

    except Exception as e:
        print("Error creating Razorpay order:", e)
        raise HTTPException(status_code=500, detail="Payment creation failed")

@app.post("/orders/send-otp")
async def send_order_otp(payload: PhoneRequest, user_id: str = Depends(get_current_user)):
    phone = normalize_phone(payload.phone)
    
    # Generate OTP
    otp = str(random.randint(100000, 999999))
    
    # Store with order type
    otp_store[f"order_{phone}"] = {
        "otp": otp,
        "expires_at": datetime.now() + timedelta(minutes=10),
        "verified": False,
        "user_id": user_id
    }
    
    # Send via Twilio
    client.messages.create(
        body=f"Your order verification code is: {otp}",
        from_=os.getenv("TWILIO_PHONE_NUMBER"),
        to=phone
    )
    
    return {"success": True, "message": "OTP sent for order verification"}
    
class VerifyOrderOtpRequest(BaseModel):
    phone: str
    otp: str

@app.post("/orders/verify-otp")
async def verify_order_otp(payload: VerifyOrderOtpRequest, user_id: str = Depends(get_current_user)):
    phone = normalize_phone(payload.phone)
    key = f"order_{phone}"

    if key not in otp_store:
        raise HTTPException(400, "No OTP requested for this phone")

    record = otp_store[key]

    if datetime.now() > record["expires_at"]:
        del otp_store[key]
        raise HTTPException(400, "OTP expired")

    if record["otp"] != payload.otp:
        raise HTTPException(400, "Invalid OTP")

    record["verified"] = True
    return {"success": True, "message": "Phone verified successfully for order"}

class CouponRequest(BaseModel):
    coupon_code: str
    subtotal: float
    # Usually, you'd fetch the cart subtotal from the DB based on user_id, 
    # but for simplicity, we'll assume it's provided or handled.
    # subtotal: float 
@app.post("/coupons/apply")
async def apply_coupon(
    request: CouponRequest,
    user_id: str = Depends(get_current_user)
):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    try:
        # 1️⃣ Fetch coupon
        cursor.execute("""
            SELECT *
            FROM coupons
            WHERE code = %s
        """, (request.coupon_code,))
        coupon = cursor.fetchone()

        if not coupon:
            raise HTTPException(400, "Invalid coupon code")

        # 2️⃣ Validations
        if coupon["status"] != "Active":
            raise HTTPException(400, "Coupon is not active")

        now = datetime.now(timezone.utc).date()

        if coupon["expiry"] and coupon["expiry"] < now:
            raise HTTPException(400, "Coupon has expired")

        # Parse usage_count from "0/100" format
        usage_parts = coupon["usage_count"].split("/")
        current_usage = int(usage_parts[0])
        usage_limit = int(usage_parts[1])


        if current_usage >= usage_limit:
            raise HTTPException(400, "Coupon usage limit reached")

        # 3️⃣ Subtotal (TEMP)
        current_subtotal =request.subtotal # Replace later

        min_amount = float(coupon["min_order_value"] or 0)
        if current_subtotal < min_amount:
            raise HTTPException(
                400,
                f"Minimum purchase of ₹{min_amount} required"
            )

        # 4️⃣ Discount calculation
        if coupon["discount_type"].lower() == "fixed":
            discount_amount = float(coupon["discount_value"])
        elif coupon["discount_type"].lower() == "percentage":
            discount_amount = (
                current_subtotal * float(coupon["discount_value"])
            ) / 100
        else:
            raise HTTPException(400, "Invalid discount type")

        # 5️⃣ Success response
        return {
            "success": True,
            "coupon_code": coupon["code"],
            "discount_amount": round(discount_amount, 2),
            "message": f"Coupon applied! You saved ₹{round(discount_amount, 2)}",
        }

    except HTTPException:
        raise
    except Exception as e:
        print("Coupon error:", e)
        raise HTTPException(500, "Failed to apply coupon")
    finally:
        cursor.close()
        conn.close()


@app.get("/coupons/available")
async def get_available_coupons(
    user_id: str = Depends(get_current_user)
):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    try:
        now = datetime.now(timezone.utc).date()

        cursor.execute("""
            SELECT
                code,
                discount_type,
                discount_value,
                min_order_value,
                usage_count,
                expiry
            FROM coupons
            WHERE status = 'Active'
              AND (expiry IS NULL OR expiry >= %s)
            ORDER BY id DESC
        """, (now,))

        coupons = cursor.fetchall()

        available_coupons = []
        for c in coupons:
            # Parse usage_count from "0/100" format
            usage_parts = c["usage_count"].split("/")
            current_usage = int(usage_parts[0])
            usage_limit = int(usage_parts[1])


            # Only include if usage limit not reached
            if current_usage < usage_limit:
                available_coupons.append({
                    "code": c["code"],
                    "discount_type": c["discount_type"],
                    "discount_value": float(c["discount_value"]),
                    "min_order_value": float(c["min_order_value"] or 0),
                    "expires_at": c["expiry"].isoformat() if c["expiry"] else None
                })

        return {
            "success": True,
            "data": available_coupons
        }

    except Exception as e:
        print("Fetch coupons error:", e)
        raise HTTPException(500, "Failed to fetch coupons")
    finally:
        cursor.close()
        conn.close()
@app.get("/category-banners")
async def get_category_banners(
    user_id: str = Depends(get_current_user)
):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    try:
        cursor.execute("""
            SELECT
                id,
                category,
                image_url,
                status
            FROM cms_category_banners
            WHERE status = TRUE
            ORDER BY id ASC
        """)

        banners = cursor.fetchall()

        return {
            "success": True,
            "data": [
                {
                    "id": b["id"],
                    "category": b["category"],
                    "image_url": b["image_url"]
                }
                for b in banners
            ]
        }

    except Exception as e:
        print("Fetch category banners error:", e)
        raise HTTPException(500, "Failed to fetch category banners")

    finally:
        cursor.close()
        conn.close()        
@app.get("/hero-banners")
async def get_hero_banners(
    user_id: str = Depends(get_current_user)
):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    try:
        cursor.execute("""
            SELECT
                id,
                title,
                image,
                position,
                status,
                created_at
            FROM cms_banners
            WHERE position = 'Hero Slider'
              AND status = 'Active'
            ORDER BY id ASC
        """)

        banners = cursor.fetchall()

        return {
            "success": True,
            "data": [
                {
                    "id": banner["id"],
                    "title": banner["title"],
                    "image_url": banner["image"],
                    "position": banner["position"],
                    "created_at": banner["created_at"].isoformat() if banner["created_at"] else None
                }
                for banner in banners
            ]
        }

    except Exception as e:
        print("Fetch hero banners error:", e)
        raise HTTPException(status_code=500, detail="Failed to fetch hero banners")

    finally:
        cursor.close()
        conn.close()        
@app.get("/cms-pages")
async def get_cms_pages(
    user_id: str = Depends(get_current_user)
):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    try:
        cursor.execute("""
            SELECT
                id,
                title,
                slug,
                content,
                status,
                updated_at
            FROM cms_pages
            WHERE status = 'Published'
            ORDER BY id ASC
        """)

        pages = cursor.fetchall()

        return {
            "success": True,
            "data": [
                {
                    "id": page["id"],
                    "title": page["title"],
                    "slug": page["slug"],
                    "content": page["content"],
                    "status": page["status"],
                    "updated_at": page["updated_at"].isoformat() if page["updated_at"] else None
                }
                for page in pages
            ]
        }

    except Exception as e:
        print("Fetch CMS pages error:", e)
        raise HTTPException(status_code=500, detail="Failed to fetch CMS pages")

    finally:
        cursor.close()
        conn.close()
@app.get("/notifications", response_model=list[NotificationOut])
def get_notifications(
    user_type: str = Query(..., alias="userType")  # ✅ FIX
):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    try:
        cursor.execute("""
            SELECT id, title, message, audience, created_at
            FROM notifications
            WHERE audience = 'all' OR audience = %s
            ORDER BY created_at DESC
        """, (user_type,))

        rows = cursor.fetchall()

        return [
            {
                "id": row["id"],
                "title": row["title"],
                "message": row["message"],
                "audience": row["audience"],
                "time": row["created_at"].strftime("%d %b %I:%M %p"),
            }
            for row in rows
        ]
    finally:
        cursor.close()
        conn.close()
