# Sevenxt Backend Service

This directory contains the FastAPI-based backend for the Sevenxt ecosystem. It handles authentication, business logic, payments, and integrations with third-party services.

## Core Stack

- **Framework**: [FastAPI](https://fastapi.tiangolo.com/)
- **Database**: PostgreSQL (via `psycopg2`)
- **Security**: JWT tokens, OAuth2 Password Bearer flow, BCrypt hashing.
- **Task Management**: Twilio for SMS verification.
- **Payments**: Razorpay integration.
- **Logistics**: Delhivery shipping rate calculations.

## Setup Instructions

### 1. Environment Configuration
Create a `.env` file in this directory. You can use `.env.example` as a template.

**Mandatory Variables:**
- `DATABASE_URL`: PostgreSQL connection string.
- `JWT_SECRET`: Secret key for authentication.
- `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`: For SMS services.
- `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`: For payment processing.

### 2. Virtual Environment
```bash
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Unix/macOS
```

### 3. Install Dependencies
```bash
pip install fastapi uvicorn psycopg2-binary python-jose[cryptography] passlib[bcrypt] razorpay twilio python-dotenv python-multipart
```

### 4. Run the API
```bash
uvicorn main:app --reload
```

## API Documentation

Once the server is running, you can access the interactive Swagger documentation at:
- `http://localhost:8000/docs`

## Features

- **OTP Verification**: Secure phone verification flow.
- **B2B Applications**: Document upload handling (GST, Licenses) and approval workflow.
- **Address Management**: CRUD operations for user shipping addresses.
- **Order Management**: Secure payment verification and shipping rate estimation.

---
*Built for performance and scalability.*
