# Gmail Clone Flutter App - Frontend

This is the frontend of a cross-platform mobile application developed using Flutter, simulating an email service similar to Gmail, as part of the **Cross-Platform Mobile Application Development (502071)** course for Semester 1, Academic Year 2024-2025. The frontend provides a responsive, user-friendly interface for account management, profile setup, and label management, with plans to support additional email functionalities like composing, viewing, and searching emails.

## Project Overview

The frontend is built with Flutter and Dart, designed to run on both mobile (Android) and web platforms. It communicates with a backend server (assumed to be implemented separately) via HTTP or WebSocket for data exchange. The app supports internal communication, allowing users to register, log in, manage their profiles, and organize emails using labels. The UI incorporates Material Design, animations, and theme support (light/dark modes) to enhance user experience.

## Implemented Features

The frontend currently implements the following features from the project rubric (refer to "502071 - Final Project.pdf"):

### Account Management (1.5 points)
- **Registration (0.25 points)**: Users register using a phone number, password, and confirm password with validation (`register_page.dart`).
- **Login (0.25 points)**: Secure login with phone number, password, and optional OTP for two-step verification (`login_page.dart`).
- **Two-step Verification (0.25 points)**: Toggle 2FA in the profile settings, requiring a verified email (`profile_page.dart`).
- **View Profile Info and Picture (0.25 points)**: Display user name, email, and profile picture (`profile_page.dart`).
- **Change Profile Info (0.25 points)**: Update name and email with confirmation for email changes (`profile_page.dart`, `profile_setup_page.dart`).
- **Change Profile Image (0.25 points)**: Upload and update profile pictures with size and format restrictions (`profile_page.dart`, `profile_setup_page.dart`).

### Label Management (0.75 points)
- **Manage Labels (0.25 points)**: List, add, remove, and rename labels (`labels_page.dart`).
- **Label Assignment (0.25 points)**: Planned integration in email actions (not yet implemented in provided files).
- **Filter by Label (0.25 points)**: Select labels to filter emails, with callback support (`labels_page.dart`).

### Settings and User Preferences (0.5 points)
- **User Settings (0.5 points)**: Toggle dark mode via `ThemeProvider` (`profile_page.dart`). Additional settings like notification preferences and auto-answer mode are planned.

### UI and UX (1.0 point)
- Responsive design with animations (fade, scale transitions), gradient backgrounds, and card-based layouts.
- Material Design components, skeleton loading, and SnackBar notifications for user feedback.
- Support for both mobile and large-screen (tablet/web) layouts.

### Total Points (Frontend Contribution)
- Implemented: **3.0 points** (Account Management: 1.5, Label Management: 0.5, Settings: 0.5, UI/UX: 0.5 partial).
- Planned: Additional features like email composition, search, and notifications will contribute to the remaining points.

## Project Structure

The frontend is organized under the `lib` directory, with the following key files:

### Authentication and Profile Management
- **`register_page.dart`**:
  - Handles user registration with phone number and password inputs.
  - Features animations, responsive layout, and navigation to profile setup.
- **`login_page.dart`**:
  - Manages login with phone number, password, and OTP for 2FA.
  - Includes password visibility toggle and links to forgot password/register.
- **`profile_setup_page.dart`**:
  - Allows new users to set up their profile with email, name, and picture.
  - Validates email and restricts image uploads (5MB, JPG/PNG).
- **`profile_page.dart`**:
  - Displays and edits user profile (name, email, picture).
  - Toggles 2FA and dark mode, with confirmation for email changes.

### Label Management
- **`labels_page.dart`**:
  - Lists, creates, renames, and deletes labels.
  - Supports label selection for filtering emails.
  - Features skeleton loading, refresh indicator, and animations.

### Planned Files (Not Provided)
- `home_page.dart`: For email list display (Inbox, Sent, etc.) and navigation.
- `compose_screen.dart`: For email composition with WYSIWYG editor.
- `email_detail_page.dart`: For viewing email details and actions.
- `search_page.dart`: For basic and advanced email search.
- `settings_page.dart`: For additional user preferences and auto-answer mode.

## Dependencies

Key packages used in the frontend (as inferred from the code):
- `flutter`: Core Flutter framework.
- `provider`: State management for `AuthService`, `EmailService`, and `ThemeProvider`.
- `image_picker`: For profile picture uploads.
- `email_validator`: For email validation in profile setup.
- Additional dependencies (e.g., HTTP, WebSocket, WYSIWYG editor) may be required for planned features, to be added in `pubspec.yaml`.

## Setup Instructions

1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd gmail_clone
   ```
2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
3. **Configure Backend**:
   - Ensure the backend server is running (e.g., ExpressJS, Firebase).
   - Update API endpoints in `AuthService` and `EmailService` to match the backend.
   - Configure WebSocket URL for real-time notifications (if implemented).
4. **Run the App**:
   - For mobile (Android):
     ```bash
     flutter run
     ```
   - For web:
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
     Deploy the `build/web` directory to a hosting service (e.g., Firebase, Netlify).
6. **Test Accounts**:
   - Use the following test accounts (or configure via backend):
     - Phone: `+1234567890`, Password: `P@ssw0rd123`
     - Phone: `+0987654321`, Password: `P@ssw0rd123`
   - Pre-loaded data (labels, emails) should be set up in the backend.

## Deployment

- **Web**: Planned deployment to Firebase Hosting or Netlify with a public URL.
- **Mobile**: APK generated for Android (ARM64), tested on emulators and physical devices.
- Ensure the backend is accessible and CORS is configured for web deployment.

## Assumptions and Notes

- **Backend**: The frontend assumes a backend with APIs for authentication (`/register`, `/login`, `/update-profile`), label management (`/labels`), and email operations. WebSocket is assumed for real-time notifications.
- **Missing Features**: Features like email composition, search, notifications, and auto-answer mode are planned but not included in the provided files. These will be implemented in additional files (e.g., `compose_screen.dart`, `settings_page.dart`).
- **AI/ML Integration**: Spam detection is planned as a bonus feature (0.25 points), requiring backend ML model integration and frontend UI updates (e.g., Spam folder, spam status display).
- **Session Management**: The app saves login state to persist sessions, with automatic redirects to login on session expiration.
- **Clean Project**: Before submission, run `flutter clean` to remove unnecessary files and reduce archive size.

## Future Improvements

- Implement email composition with WYSIWYG editor and attachment support.
- Add email list views (basic/detailed) and folder navigation (Inbox, Sent, etc.).
- Integrate search functionality (basic and advanced) with filters.
- Enable real-time notifications using WebSocket for new emails.
- Add auto-answer mode with customizable responses.
- Implement AI-powered spam detection with user feedback options.
- Enhance accessibility (screen reader support, keyboard navigation).
- Write unit tests for UI components and service integrations.

## Submission Checklist

- **Source**: Include `lib` directory with all Dart files, `pubspec.yaml`, and backend source (if custom).
- **Bin**: Provide Android APK (ARM64) and web build (`build/web`).
- **Demo**: Record a 1080p video showcasing all implemented features.
- **Git**: Submit screenshots of GitHub contributions (2+ commits/week/member, 1+ month duration).
- **Readme.txt**: Include build instructions, test account credentials, backend URL, and bonus feature details.
- **Bonus**: Document AI/ML features (e.g., spam detection) with evidence.
- **Rubrik.docx**: Self-assess 30 features, include web URL and login credentials.
- **Archive**: Name as `id1_fullname1_id2_fullname2.zip`, submit via e-learning.