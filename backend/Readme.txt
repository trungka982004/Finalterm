Gmail Clone Backend - Final Project Instructions

1. Project Overview
This is the backend for a simulated email service application developed for the Cross-Platform Mobile Application Development course (502071). It uses Express.js, MongoDB, Socket.IO, and other dependencies to handle account management, email operations, label management, notifications, and user settings. UI-related settings (font size, font family, theme) are handled by the Flutter frontend.

2. Prerequisites
- Node.js (v16 or higher)
- MongoDB Atlas account or local MongoDB installation
- EmailJS account for password recovery emails
- Google reCAPTCHA v2 secret key
- Hosting platform (e.g., Heroku, AWS, Railway)

3. Installation
1. Clone the repository: `git clone <repository-url>`
2. Navigate to the project directory: `cd gmail_clone_backend`
3. Install dependencies: `npm install`
4. Create a `.env` file in the root directory with the following:
```
PORT=3000
MONGODB_URI=<your-mongodb-uri>
JWT_SECRET=<your-jwt-secret>
RECAPTCHA_SECRET_KEY=<your-recaptcha-v2-secret-key>
EMAILJS_SERVICE_ID=<your-emailjs-service-id>
EMAILJS_TEMPLATE_ID=<your-emailjs-template-id>
EMAILJS_USER_ID=<your-emailjs-user-id>
EMAILJS_PRIVATE_KEY=<your-emailjs-private-key>
```
5. Run the server: `node server.js`
6. (Optional) If migrating existing data, run: `node migrateEmails.js`

4. Deployment
- Deploy to a hosting platform (e.g., Heroku):
  1. Create a Heroku app: `heroku create`
  2. Push the code: `git push heroku main`
  3. Set environment variables: `heroku config:set <variable>=<value>`
- Public URL: <your-deployed-url> (e.g., https://your-app-name.herokuapp.com)
- Test accounts for evaluation:
  - Phone: 1234567890, Password: test123
  - Phone: 0987654321, Password: test123
- Ensure the `uploads` folder exists for file uploads (or configure AWS S3 for production).

5. API Endpoints
- /auth/register: Register a new user (requires reCAPTCHA v2 token)
- /auth/login: User login with optional 2FA (requires reCAPTCHA v2 token)
- /auth/enable-2fa: Enable two-factor authentication
- /auth/disable-2fa: Disable twoFA
- /auth/profile/:userId: Get user profile
- /auth/change-password: Change user password
- /auth/forgot-password: Send OTP for password recovery
- /auth/verify-otp: Verify OTP and reset password
- /auth/change-avatar/:userId: Update user avatar
- /emails/send: Send email with attachments
- /emails/reply/:emailId: Reply to an email
- /emails/forward/:emailId: Forward an email
- /emails/draft: Save email as draft
- /emails/action/:emailId: Perform actions on an email (read, star, category, labels)
- /emails/:userId/:category: Get emails by user and category
- /emails/search/:userId: Search emails with filters
- /labels: Create a new label
- /labels/:labelId: Update label name
- /labels/:labelId: Delete a label
- /labels/assign/:emailId: Assign a label to an email
- /labels/remove-label/:emailId: Remove a label from an email
- /labels/:userId: Get labels by user
- /labels/emails/:userId/:label: Get emails by label
- /settings/:userId: Get user settings (notifications, auto-answer)
- /settings/:userId: Update user settings
- /captcha/verify: Verify reCAPTCHA v2 token

6. Bonus Features (AI/ML Integration)
- Spam detection using a Naive Bayes classifier (0.25 points) in /emails/send, trained with 20 examples for improved accuracy.
- Custom backend developed with Express.js and MongoDB (0.5 points).
- CC/BCC now use arrays of User IDs for robust handling and notifications.

7. Notes
- Ensure MongoDB Atlas is properly configured.
- Use a strong JWT_SECRET for security.
- Font size, font family, and theme settings are handled by the Flutter frontend using shared_preferences.
- For reCAPTCHA v2, the Flutter frontend must integrate a reCAPTCHA v2 widget (e.g., flutter_recaptcha_v2) and send the g-recaptcha-response token.
- If migrating from string-based cc/bcc to arrays, run the migration script (migrateEmails.js).
- Do not commit .env to public repositories; add to .gitignore.
- Submit the project via the elearning system as a ZIP file named id1_fullname1_id2_fullname2.zip.