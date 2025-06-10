# Gmail Clone Application

A comprehensive email application combining a Flutter frontend and a Node.js backend, replicating core Gmail functionalities like email management, user authentication, and profile customization.

## Overview
This repository contains both the frontend and backend for a Gmail Clone app:
- **Frontend**: A cross-platform Flutter app (mobile, web) with a responsive UI for seamless email and profile management.
- **Link URl Frontend**: `https://mail-mkjc.onrender.com`
- **Backend**: A REST API built with Node.js and Express.js, using MongoDB for data storage, Cloudinary for file uploads, and Socket.IO for real-time notifications.
- **Link URl Backend**: `https://gmail-backend-1-wlx4.onrender.com`

## Features
- **User Authentication**:
  - Register, login, forgot password, and change password using phone number and OTP.
  - Two-factor authentication (2FA) via email OTP.
- **Email Management**:
  - Send, reply, forward, save drafts, star, mark read/unread, move to trash, and permanently delete emails.
  - Advanced search by keyword, sender, recipient, date range, and attachments.
  - Support for attachments (JPEG, PNG, PDF, 10MB limit).
- **Labels**:
  - Create, rename, delete, and assign custom labels to emails.
  - System "Spam" label for suspicious emails.
- **Spam Detection**:
  - Rule-based detection using keywords, link count, unverified senders, and attachment size.
  - Spam emails are moved to the "spam" folder with a "Spam" label.
- **Auto Reply**: Configure automatic responses for incoming emails.
- **Real-Time Notifications**: Socket.IO for new email alerts.
- **Profile Management**:
  - Update name, email, and profile picture (.jpg, .jpeg, .png, 5MB limit).
  - Enable/disable 2FA and toggle light/dark themes.
- **Cross-Platform**: Responsive UI for mobile, tablet, and web.

## Technologies Used
### Frontend
- **Flutter (Dart)**: Cross-platform UI framework.
- **Provider**: State management.
- **Key Dependencies**:
  - `http`: API requests.
  - `image_picker`: Profile picture uploads.
  - `shared_preferences`: Token storage.
  - `email_validator`: Email validation.
  - `html_editor_enhanced`: Rich text email composition.
  - See `frontend/pubspec.yaml` for details.

### Backend
- **Node.js & Express.js**: Backend framework.
- **MongoDB & Mongoose**: Database and ORM.
- **JWT**: Token-based authentication.
- **Cloudinary**: File storage for attachments and profile pictures.
- **Socket.IO**: Real-time WebSocket communication.
- **Nodemailer**: OTP email sending.
- **Multer**: File upload handling.
- **Bcrypt**: Password hashing.
- **dotenv**: Environment variable management.

## Prerequisites
- **Frontend**:
  - Flutter SDK: `>=3.0.0 <4.0.0`
  - Dart SDK
  - Android Studio/Xcode for emulator or device
  - Web browser (for web platform)
- **Backend**:
  - Node.js (v16 or higher)
  - MongoDB Atlas account
  - Cloudinary account
  - Gmail account for Nodemailer (App Password for 2FA-enabled accounts)

## Setup Instructions
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/trungka982004/Finalterm.git
   cd Finalteem
   ```

### Frontend Setup
2. **Navigate to Frontend Directory**:
   ```bash
   cd frontend
   ```
3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
4. **Configure Backend URL**:
   - Ensure the backend is running (e.g., at `https://gmail-backend-1-wlx4.onrender.com`).
   - Update `_baseUrlAuth` and `_baseUrlUser` in `frontend/lib/services/auth_service.dart` and `_baseUrl` in `frontend/lib/services/email_service.dart` if using a custom backend URL.
5. **Run the App**:
   ```bash
   flutter run
   ```
   Select a device (emulator, physical device, or browser).

### Backend Setup
2. **Navigate to Backend Directory**:
   ```bash
   cd backend
   ```
3. **Install Dependencies**:
   ```bash
   npm install
   ```
4. **Configure Environment Variables**:
   Create a `backend/.env` file with:
   ```env
   MONGODB_URI=<your-mongodb-atlas-uri>
   JWT_SECRET=<your-jwt-secret>
   CLOUDINARY_CLOUD_NAME=<your-cloudinary-cloud-name>
   CLOUDINARY_API_KEY=<your-cloudinary-api-key>
   CLOUDINARY_API_SECRET=<your-cloudinary-api-secret>
   GMAIL_USER=<your-gmail-email>
   GMAIL_PASS=<your-gmail-app-password>
   ```
5. **Run the Server**:
   ```bash
   npm start
   ```
   The server runs at `http://localhost:3000` (or the specified port).

## Usage
1. **Register**: Create an account with a phone number and password.
2. **Set Up Profile**: Add email, name, and profile picture post-registration.
3. **Login**: Use phone number and password (OTP required if 2FA enabled).
4. **Manage Emails**:
   - View emails in folders (Inbox, Sent, Drafts, Starred, Trash, Spam).
   - Compose, reply, or forward emails with attachments.
   - Organize emails with custom labels.
   - Search emails with advanced filters.
5. **Profile Settings**:
   - Update profile or toggle 2FA.
   - Switch between light/dark themes.
6. **Auto Reply**: Enable and configure auto-reply messages.
7. **Notifications**: Receive real-time new email alerts.

## Project Structure
### Frontend
```
frontend/
├── lib
│   ├── main.dart                # App entry point
│   ├── models
│   │   └── user.dart            # User model
│   ├── services
│   │   ├── auth_service.dart    # Authentication logic
│   │   └── email_service.dart   # Email API calls
│   ├── pages
│   │   ├── home_page.dart       # Email list view
│   │   ├── email_detail_page.dart # Email details
│   │   ├── compose_screen.dart  # Email composition
│   │   ├── labels_page.dart     # Label management
│   │   ├── profile_page.dart    # User profile
│   │   ├── register_page.dart   # Registration
│   │   ├── login_page.dart      # Login
│   │   ├── profile_setup_page.dart # Profile setup
│   │   ├── forgot_password_page.dart # Password recovery
│   │   ├── change_password_page.dart # Password change
│   │   └── auto_reply_page.dart # Auto-reply settings
├── assets
│   └── images
│       └── logo.png            # App logo
├── pubspec.yaml               # Dependencies
```

### Backend
```
backend/
├── src
│   ├── models
│   │   ├── user.js             # User model
│   │   ├── email.js            # Email model
│   │   ├── label.js            # Label model
│   │   └── autoReply.js        # Auto-reply model
│   ├── routes
│   │   ├── auth.js             # Auth APIs
│   │   ├── user.js             # User management APIs
│   │   └── email.js            # Email management APIs
│   ├── middleware
│   │   └── auth.js             # Authentication middleware
│   ├── utils
│   │   ├── spamDetection.js    # Spam detection logic
│   │   └── socket.js           # Socket.IO handling
│   ├── app.js                  # Express app setup
│   └── server.js               # Server entry point
├── .env                       # Environment variables
├── package.json               # Dependencies and scripts
```

## API Endpoints
### Authentication (`/api/auth`)
- `POST /register`: Register a new user.
- `POST /login`: Login (supports 2FA with OTP).
- `POST /forgot-password`: Request OTP for password reset.
- `POST /reset-password`: Reset password using OTP.
- `GET /verify-token`: Verify JWT token.

### User Management (`/api/user`)
- `GET /profile`: Get user profile.
- `POST /update-profile`: Update profile (email, name, picture).
- `POST /change-password`: Change password.
- `POST /toggle-2fa`: Enable/disable 2FA.

### Email Management (`/api/email`)
- `POST /send`: Send email with attachments, CC, BCC.
- `POST /save-draft`: Save email draft.
- `POST /reply/:emailId`: Reply to an email.
- `POST /forward/:emailId`: Forward an email.
- `GET /list/:folder`: List emails in a folder.
- `PATCH /mark-read/:emailId`: Mark as read/unread.
- `PATCH /star/:emailId`: Star/unstar email.
- `PATCH /move-to-trash/:emailId`: Move to trash.
- `GET /search`: Search emails.
- `POST /labels`: Create a label.
- `DELETE /labels/:labelId`: Delete a label.
- `PATCH /labels/:labelId`: Update label name.
- `PATCH /emails/:emailId/labels`: Assign/remove label.
- `GET /labels`: List labels.
- `POST /auto-reply`: Configure auto-reply.
- `GET /emails/:emailId`: Get email details.
- `DELETE /:emailId`: Permanently delete email.

## Contributing
1. Fork the repository.
2. Create a feature branch: `git checkout -b feature-name`.
3. Commit changes: `git commit -m "Add feature-name"`.
4. Push to the branch: `git push origin feature-name`.
5. Open a pull request.