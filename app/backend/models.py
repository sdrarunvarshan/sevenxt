from pydantic import BaseModel, EmailStr ,Field
from typing import Optional , List
from fastapi import UploadFile, File# ← IMPORTANT: for file uploads

class Token(BaseModel):
    access_token: str
    token_type: str

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: Optional[str] = None
    phone_number: Optional[str] = None
    business_name: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class PhoneRequest(BaseModel):
    phone: str

def normalize_phone(phone: str) -> str:
    phone = phone.strip().replace(" ", "")
    if phone.startswith("+"):
        return phone
    if phone.startswith("91") and len(phone) == 12:
        return f"+{phone}"
    if len(phone) == 10:
        return f"+91{phone}"
    raise HTTPException(status_code=400, detail="Invalid phone number format")

class VerifyOtpRequest(BaseModel):
    phone: str
    otp: str  
    type: Optional[str] = None  # Add this field  

class ResetPasswordRequest(BaseModel):
    email: EmailStr
    phone: str
    otp: str
    new_password: str
        
class AddressCreate(BaseModel):
    address: str
    city: str
    state:str
    pincode: Optional[int] = None
    state: Optional[str] = None
    country: str
    name: str = "Home"
    is_default: bool = False

class B2BApplicationCreate(BaseModel):
    business_name: str
    gstin: str
    pan: str
    phone_number: str
    gst_certificate_url: str
    business_license_url: str
    address_id: str


class AddressPayload(BaseModel):
    address: str
    city: str
    pincode: Optional[int] = None
    state: Optional[str] = None
    country: Optional[str] = ""
    name: Optional[str] = "Home"
    is_default: Optional[bool] = False


class B2CRegister(BaseModel):
    email: EmailStr
    password: str
    full_name: Optional[str] = None
    phone_number: Optional[str] = None
    raw_user_meta_data: Optional[dict] = None
    address: Optional[AddressPayload] = None
    
class OrderedProductBase(BaseModel):
    order_item_id: Optional[int] = None 
    product_id: Optional[str] = None  # 🔥 ADD THIS
    name: str
    price: float
    imageUrl: str
    quantity: int
    colorHex: str
    hsnCode: str  
    weightKg: Optional[float] = None  # Make Optional and float
    lengthCm: Optional[float] = None  # Make Optional and float
    breadthCm: Optional[float] = None  # Make Optional and float
    heightCm: Optional[float] = None  # Make Optional and float
    

class OrderCreate(BaseModel):
    order_id: str # Unique ID from Flutter (e.g., timestamp)
    placed_on: str # Date string
    order_status: str # e.g., 'processing'
    customer_name: str
    products: List[OrderedProductBase]
    total_price: float
    shipping_fee: float  
    state_gst_amount: float
    central_gst_amount: float
    sgst_percentage: float = 0.0 
    cgst_percentage: float = 0.0
    customer_email: str
    phone: str
    customer_address_text: str
    customer_type: Optional[str] = None
    payment_status: str
    payment_method: str
    hsn: Optional[str] = ""  # Add this
    city: Optional[str] = None        # 🔥 ADD
    state: Optional[str] = None 
    pincode: Optional[int] = None 
    weight: Optional[float] = 0  # Add this
    height: Optional[float] = 0  # Add this
    length: Optional[float] = 0  # Add this
    breadth: Optional[float] = 0  # Add this


class CreatePaymentRequest(BaseModel):
    amount: float
    currency: str = "INR"
    receipt: str = None
    notes: dict = None

class VerifyPaymentRequest(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str
    order_id: str  # Your internal order ID    
class NotificationOut(BaseModel):
    id: int
    title: str
    message: str
    audience: str
    time: str    
