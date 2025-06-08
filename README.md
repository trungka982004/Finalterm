# Gmail Clone - Simulated Email Service Application

This is a cross-platform email service application developed for the **Cross-Platform Mobile Application Development (502071)** course, Semester 1, Academic Year 2024-2025. The project simulates a Gmail-like email system using Flutter for the frontend and a custom backend (assumed ExpressJS with MongoDB) for data management and real-time communication. The app supports internal email communication, user account management, label organization, and planned AI-powered features like spam detection.

## Link URL Project: `https://clone-3cdd9.web.app`

## Project Overview

The application is designed to run on mobile (Android) and web platforms, providing a responsive, user-friendly interface with Material Design, animations, and theme support. It uses HTTP APIs for core operations (e.g., authentication, email management) and WebSocket for real-time notifications. All user data, emails, and labels are stored in a database (MongoDB assumed), enabling cross-device access. The system restricts communication to internal users, eliminating the need for standard email protocols (IMAP/POP/SMTP).

## Implemented and Planned Features

The project implements a subset of the required features from the rubric (see "502071 - Final Project.pdf") and plans additional features for full compliance. Below is a summary of the status:

### Account Management (1.5 points)
- **Registration (0.25 points)**: Implemented (`register_page.dart`). Users register with phone number and password.
- **Login (0.25 points)**: Implemented (`login_page.dart`). Supports phone number, password, and OTP for 2FA.
- **Password Management (0.5 points)**:
  - Change Password (0.25 points): Planned (`change_password_page.dart` assumed).
  - Password Recovery (0.25 points): Planned (`forgot_password_page.dart` assumed).
- **Two-step Verification (0.25 points)**: Implemented (`profile_page.dart`). Toggle 2FA, requires verified email.
- **Profile Management (0.75 points)**:
  - View Profile Info and Picture (0.25 points): Implemented (`profile_page.dart`).
  - Change Profile Info (0.25 points): Implemented (`profile_page.dart`, `profile_setup_page.dart`).
  - Change Profile Image (0.25 points): Implemented (`profile_page.dart`, `profile_setup_page.dart`).

### Compose and Send Email (2.5 points)
- **Send Simple Text Email (0.25 points)**: Planned (`compose_screen.dart` assumed).
- **Auto Save as Draft (0.25 points)**: Planned.
- **Reply and Forward (0.5 points)**: Planned (`email_detail_page.dart` assumed).
- **Send Email in CC and BCC (0.25 points)**: Planned.
- **Advanced Text Editing with WYSIWYG (0.25 points)**: Planned.
- **Sending and Receiving Attachments (0.25 points)**: Planned.
- **Email Actions (0.5 points)**: Planned (view metadata, assign labels, mark read/unread, move to trash).
- **Star Email (0.25 points)**: Planned.

### Email Management and Settings (4.0 points)
- **View Emails in Categories (0.5 points)**: Planned (`home_page.dart` assumed for Inbox, Sent, Draft, Starred, Trash).
- **View Email List in Basic/Detail View (0.5 points)**: Planned.
- **Search Email by Keywords (0.5 points)**: Planned (`search_page.dart` assumed).
- **Advanced Searching (0.5 points)**: Planned.
- **Label Management (0.75 points)**:
  - Manage Labels (0.25 points): Implemented (`labels_page.dart`).
  - Add/Remove Labels (0.25 points): Planned.
  - View Emails by Label (0.25 points): Implemented (`labels_page.dart` callback).
- **Notifications (0.5 points)**:
  - Display Notification (0.25 points): Planned (WebSocket integration assumed).
  - Realtime Inbox Update (0.25 points): Planned.
- **User Settings (0.5 points)**: Partially implemented (`profile_page.dart` for dark mode). Planned for notification settings, font preferences, and auto-answer mode (`settings_page.dart` assumed).
- **Auto Answer (0.25 points)**: Planned (`auto_reply_page.dart` assumed).

### Others (2.0 points)
- **UI and UX (1.0 point)**: Partially implemented. Responsive design, animations, and Material Design components.
- **Deployment Web Version (0.5 points)**: Planned (Firebase Hosting or Netlify).
- **Teamwork (0.5 points)**: Assumed active GitHub collaboration with regular commits.

### Bonus Features (up to 1.0 point)
- **AI/ML Integration**: Planned spam detection (0.25 points) with backend ML model and frontend UI (Spam folder, spam status display).

### Total Points
- **Implemented**: ~3.0 points (Account Management: 1.5, Label Management: 0.5, Settings: 0.5 partial, UI/UX: 0.5 partial).
- **Planned**: ~6.5 points (remaining email, search, notification, and settings features).
- **Bonus**: Up to 0.25 points for spam detection.
- **Backend Bonus**: 0.5 points if custom backend is used.

## Project Structure

### Frontend (Flutter)
- **Directory**: `lib/`
- **Key Files**:
  - `register_page.dart`: User registration with phone number and password.
  - `login_page.dart`: Login with 2FA support and OTP.
  - `profile_setup_page.dart`: Initial profile setup with email, name, and picture.
  - `profile_page.dart`: Profile viewing/editing, 2FA, and dark mode toggle.
  - `labels_page.dart`: Label management (create, rename, delete, select).
  - Planned files: `home_page.dart`, `compose_screen.dart`, `email_detail_page.dart`, `search_page.dart`, `settings_page.dart`, `auto_reply_page.dart`, etc.
- **Dependencies** (from `pubspec.yaml` assumed):
  - `flutter`, `provider`, `image_picker`, `email_validator`.
  - Planned: `http`, `web_socket_channel`, WYSIWYG editor package (e.g., `flutter_quill`).

### Backend (Assumed ExpressJS + MongoDB)
- **Directory**: `server/`
- **Components**:
  - **API Endpoints**:
    - `/api/auth/register`: Register user with phone number.
    - `/api/auth/login`: Login with phone number, password, and OTP.
    - `/api/auth/update-profile`: Update user profile and picture.
    - `/api/auth/toggle-2fa`: Enable/disable 2FA.
    - `/api/labels`: CRUD operations for labels.
    - Planned: `/api/emails` for email operations, `/api/search` for search, `/api/spam` for spam detection.
  - **WebSocket**: Real-time notifications for new emails (`/ws` endpoint assumed).
  - **Database**: MongoDB for storing users, emails, labels, and settings.
  - **ML Model**: Planned for spam detection (e.g., using TensorFlow.js or Python API).
- **Dependencies** (assumed):
  - `express`, `mongoose`, `jsonwebtoken`, `ws`, `multer` (file uploads), `nodemailer` (for password recovery).

## Setup Instructions

### Frontend
1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd gmail_clone
   ```
2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
3. **Configure Backend URL**:
   - Update API base URL in `AuthService` and `EmailService` (e.g., `http://localhost:3000` or hosted URL).
   - Set WebSocket URL for notifications.
4. **Run the App**:
   - Mobile (Android):
     ```bash
     flutter run
     ```
   - Web:
     ```bash
     flutter run -d chrome
     ```
5. **Build for Deployment**:
   - Android APK (ARM64):
     ```bash
     flutter build apk --target-platform android-arm64
     ```
   - Web:
     ```bash
     flutter build web
     ```

### Backend
1. **Navigate to Server Directory**:
   ```bash
   cd server
   ```
2. **Install Dependencies**:
   ```bash
   npm install
   ```
3. **Configure Environment**:
   - Create `.env` file with:
     ```env
    MONGODB_URI=<your-mongodb-atlas-connection-string>
    JWT_SECRET=<your-jwt-secret>
    CLOUDINARY_CLOUD_NAME=<your-cloudinary-cloud-name>
    CLOUDINARY_API_KEY=<your-cloudinary-api-key>
    CLOUDINARY_API_SECRET=<your-cloudinary-api-secret>
    GMAIL_USER=<your-gmail-address>
    GMAIL_PASS=<your-gmail-app-password>
    PORT=3000
     ```
   - Ensure MongoDB is running.
4. **Run the Server**:
   ```bash
   node index.js
   ```
5. **Deploy**:
   - Host on a platform like Heroku, AWS, or Render.
   - Ensure CORS is configured for frontend access.

### Test Accounts
- Phone: `+1234567890`, Password: `test123`
- Phone: `+0987654321`, Password: `test123`
- Pre-loaded data (labels, emails) should be seeded in MongoDB.

## Deployment

- **Web**: Deploy frontend to Firebase Hosting or Netlify, backend to Heroku or AWS. Provide public URL (e.g., `https://gmail-clone.web.app`).
- **Mobile**: Generate Android APK (ARM64) for distribution.
- **Backend**: Ensure database and WebSocket are accessible from hosted frontend.

## Assumptions

- **Backend**: Implemented with ExpressJS, MongoDB, and WebSocket. APIs follow REST conventions, and JWT handles authentication.
- **Missing Frontend Files**: Features like email composition, search, and notifications are planned in additional Dart files.
- **AI/ML**: Spam detection will use a backend ML model (e.g., Naive Bayes) with frontend UI for Spam folder and user feedback.
- **Session Management**: Frontend persists login state using secure storage; backend validates JWT tokens.
- **Cross-Device Sync**: MongoDB ensures data consistency across devices.

## Future Improvements

- Implement email composition with WYSIWYG editor and attachments.
- Add email list views (basic/detailed) and folder navigation.
- Integrate search (basic and advanced) with filters.
- Enable real-time notifications via WebSocket.
- Add auto-answer mode with customizable responses.
- Implement AI-powered spam detection with user feedback.
- Enhance accessibility and add unit tests.
- Optimize performance for large email datasets.

## Submission Checklist

- **Source**:
  - `lib/`: Flutter source code.
  - `server/`: Backend source code.
  - `pubspec.yaml` and `package.json`.
- **Bin**:
  - `bin/android.apk`: Android APK (ARM64).
  - `bin/web/`: Web build files.
- **Demo**: `demo.mp4` (1080p) showcasing all features.
- **Git**: `git/` with GitHub contribution screenshots (2+ commits/week/member, 1+ month).
- **Readme.txt**:
  - Build/run instructions.
  - Test account credentials.
  - Backend URL and WebSocket endpoint.
  - Bonus feature details (spam detection).
- **Bonus**: `Bonus/` with spam detection description and evidence.
- **Rubrik.docx**: Self-assessed 30 features, web URL, and login credentials.
- **Archive**: `id1_fullname1_id2_fullname2.zip`, submitted via e-learning.
- **Clean Project**: Run `flutter clean` and `npm prune` before archiving.

## Notes

- **Bonus Points**: Custom backend (+0.5 points) and spam detection (+0.25 points) are targeted.
- **Plagiarism**: Code is original, and GitHub commits reflect team effort.
- **Grading Info**: All required details (usernames, URLs) will be in `Readme.txt` and `Rubrik.docx`.
- **Deductions**: Avoid late submission, ensure clear instructions, and clean project files.

## Team Information
- Team: <520H0341_NguyenThaiBao_id2_name2>
- GitHub Repository: <github-url>
- Submission Date: June 05, 2025

Thank you for evaluating our project!