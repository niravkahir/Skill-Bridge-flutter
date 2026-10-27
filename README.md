# 🎓 Skill Bridge — Peer-to-Peer Skill Exchange Platform

Skill Bridge is a Flutter-based mobile and web application that allows students to teach skills they already know and learn skills they want to learn from other students. It provides real-time learning requests, 1-on-1 Zoom meeting scheduling, profile management, rating systems, and role-based features for students and administrators.

## 📸 Screenshots

*Explore the application's interface and its key features below.*

### 🏠 Student Dashboard & Profile
*Browse skills, manage your profile, and view your ratings.*

<img width="717" height="1530" alt="WhatsApp Image 2026-10-27 at 8 44 00 PM" src="https://github.com/user-attachments/assets/9144f74f-e8c5-4c8c-a4a8-91bfd8a8b0f5" />
<img width="720" height="1191" alt="WhatsApp Image 2026-10-27 at 8 44 01 PM" src="https://github.com/user-attachments/assets/e85d6f2c-d333-4eb8-9c3f-da7084c58407" />
<img width="710" height="1033" alt="WhatsApp Image 2026-10-27 at 8 44 01 PM (1)" src="https://github.com/user-attachments/assets/c35a89cd-2e12-4d23-b16d-a29d054e5ee1" />
<img width="718" height="1527" alt="WhatsApp Image 2026-10-27 at 8 44 01 PM (2)" src="https://github.com/user-attachments/assets/9b70170e-a46a-4a29-bde4-184666a6184c" />


### 🤝 Learning Requests & Scheduling
*Send requests, accept learners, and auto-generate Zoom meeting links.*

<img width="715" height="1525" alt="WhatsApp Image 2026-10-27 at 8 44 02 PM (1)" src="https://github.com/user-attachments/assets/d70c8196-2064-453a-a757-985b7f55a695" />
<img width="715" height="1523" alt="WhatsApp Image 2026-10-27 at 8 44 02 PM" src="https://github.com/user-attachments/assets/b0f721de-5e86-4823-9d13-643aed06eb31" />


### 🛡️ Admin Dashboard
*Manage skills, monitor platform activity, and control system data.*

<img width="719" height="1038" alt="WhatsApp Image 2026-10-27 at 8 44 03 PM" src="https://github.com/user-attachments/assets/be64e506-c174-49bd-bae1-c32931a6ad8b" />


---

## ✨ Features

### 👤 User (Student) Features
- **Registration & Login:** Secure email/password authentication via Firebase.
- **Profile Management:** Add bio, college, semester, and profile pictures (uploaded via Cloudinary).
- **Skill Management:** Add skills you can teach and skills you want to learn, specifying proficiency levels (Beginner, Intermediate, Expert).
- **Discover Students:** Search and filter peers based on specific skills and colleges.
- **Rating & Reviews:** View average ratings and session history on other users' profiles.

### 🤝 Connection & Meeting Features
- **Learning Requests:** Send requests to peers with a personalized message and preferred time.
- **Accept/Reject System:** Teachers can review incoming requests and accept or reject them.
- **Zoom Integration:** Automatically generate real, secure Zoom meeting links for scheduled sessions using the Zoom API.
- **Meeting Dashboard:** View upcoming, completed, and cancelled sessions.

### 🛡️ Admin Features
- **Role-Based Access:** Admin panel is only accessible to verified admin accounts.
- **Skill Management:** Add, edit, or deactivate skills in the system database.
- **User Analytics:** Track platform activity (coming soon).

---

## 🛠️ Tech Stack

| Technology | Purpose |
| :--- | :--- |
| **Flutter** | Cross-platform UI framework |
| **Dart** | Programming language |
| **Firebase Auth** | Secure user authentication (JWT handling) |
| **Cloud Firestore** | Real-time NoSQL Database |
| **Cloudinary API** | Cloud storage and CDN for profile images |
| **Zoom API** | 1-on-1 video meeting generation |
| **Cloudflare Workers** | Serverless proxy to bypass CORS for Zoom API |
| **Provider** | State Management |
| **URL Launcher** | Opening external apps (Zoom) |

---

## ⚙️ Prerequisites

- Flutter SDK (Latest stable version).
- Android Studio / VS Code.
- A Firebase project (with Authentication and Firestore enabled).
- A Cloudinary account (for image hosting).
- A Zoom Developer Account (Server-to-Server OAuth App).
- A Cloudflare account (for the Worker proxy).

---

## 🚀 Installation and Setup

### 1. Clone the repository

```bash
git clone https://github.com/niravkahir/Skill-Bridge-flutter
cd Skill-Bridge-flutter
