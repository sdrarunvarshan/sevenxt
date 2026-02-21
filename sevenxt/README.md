# Sevenxt - Premium E-commerce Solution

Sevenxt is a comprehensive e-commerce platform featuring a modern Flutter frontend and a robust FastAPI backend. It provides a complete solution for both customers (B2C) and business partners (B2B).

## Project Structure

- **`sevenxt/`**: The Flutter-based mobile application. It contains a premium UI kit with 100+ screens and logic for a smooth shopping experience.
- **`app/backend/`**: The Python FastAPI backend. It handles user authentication, business registrations, payment processing via Razorpay, and logistics via Delhivery.

## Features

### Frontend (Flutter)
- **Premium UI Kit**: Over 100+ meticulously crafted minimal screens.
- **E-commerce Core**: Product browsing, category filtering, cart management, and order placement.
- **Payment Integration**: Secure payments powered by Razorpay.
- **User Types**: Dedicated flows for regular customers and B2B business users.
- **Native Experience**: Responsive design optimized for both Android and iOS.

### Backend (FastAPI)
- **RESTful API**: Fast and efficient API endpoints built with FastAPI.
- **Secure Authentication**: JWT-based auth with OAuth2 password flow.
- **Identity Verification**: Phone-based OTP verification using Twilio.
- **B2B Onboarding**: Complex registration flow with document uploads (GST, Business License).
- **Integrations**: 
  - **Razorpay**: Payment gateway integration.
  - **Delhivery**: Logistics and shipping rate calculations.
  - **Twilio**: SMS services for OTP.
- **Database**: Robust data management using PostgreSQL.

## Prerequisites

Before setting up the project, ensure you have the following installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Latest stable version)
- [Python 3.10+](https://www.python.org/downloads/)
- [PostgreSQL](https://www.postgresql.org/download/)
- [Git](https://git-scm.com/downloads)

## Setup Instructions

### 1. Backend Setup

1.  **Navigate to the backend directory**:
    ```bash
    cd app/backend
    ```
2.  **Create a virtual environment**:
    ```bash
    python -m venv venv
    ```
3.  **Activate the virtual environment**:
    - **Windows**: `venv\Scripts\activate`
    - **macOS/Linux**: `source venv/bin/activate`
4.  **Install dependencies**:
    ```bash
    pip install fastapi uvicorn psycopg2-binary python-jose[cryptography] passlib[bcrypt] razorpay twilio python-dotenv python-multipart
    ```
5.  **Configure Environment Variables**:
    - Create a `.env` file in `app/backend/`.
    - Use `.env.example` as a template.
    - Set your `DATABASE_URL`, `TWILIO` credentials, and `RAZORPAY` keys.
6.  **Run the Server**:
    ```bash
    uvicorn main:app --reload
    ```
    The backend will be available at `http://localhost:8000`.

### 2. Frontend Setup

1.  **Navigate to the flutter directory**:
    ```bash
    cd sevenxt
    ```
2.  **Get packages**:
    ```bash
    flutter pub get
    ```
3.  **Configure Backend URL**:
    Ensure the app's service layer points to your backend URL (usually configured in a config file or via the integration layer).
4.  **Run the Application**:
    ```bash
    flutter run
    ```

## Technology Stack

- **Mobile**: Flutter, Dart, Provider (State Management)
- **Backend**: FastAPI, Python, PostgreSQL
- **Security**: JWT, Passlib (BCrypt)
- **Third-party Services**: Razorpay, Twilio, Delhivery
- **Storage**: Local file storage for uploads (GST, Licenses)

---

Developed as a premium e-commerce infrastructure.
