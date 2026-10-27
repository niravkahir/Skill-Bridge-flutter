# 🎓 Skill Bridge — Peer-to-Peer Skill Exchange Platform

Skill Bridge is a Flutter-based mobile and web application that connects students who want to **teach skills they know and learn skills from others**. It provides student discovery, skill management, learning requests, Zoom meeting scheduling, profiles, ratings, and role-based administration.

## 📸 Screenshots

Explore the main features of Skill Bridge. Screenshots are displayed in a compact layout to keep the README easy to navigate.

### 🏠 Student Dashboard & Profile

Browse skills, manage your profile, view ratings, and explore learning opportunities.

<p align="center">
  <img src="https://github.com/user-attachments/assets/9144f74f-e8c5-4c8c-a4a8-91bfd8a8b0f5" width="42%" alt="Student Dashboard" />
  <img src="https://github.com/user-attachments/assets/9b70170e-a46a-4a29-bde4-184666a6184c" width="42%" alt="Skill Discovery" />
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/e85d6f2c-d333-4eb8-9c3f-da7084c58407" width="42%" alt="Student Profile" />
  <img src="https://github.com/user-attachments/assets/c35a89cd-2e12-4d23-b16d-a29d054e5ee1" width="42%" alt="Student Skills" />
</p>

### 🤝 Learning Requests & Meeting Scheduling

Send learning requests, manage incoming requests, and view scheduled learning sessions.

<p align="center">
  <img src="https://github.com/user-attachments/assets/d70c8196-2064-453a-a757-985b7f55a695" width="42%" alt="Learning Requests" />
  <img src="https://github.com/user-attachments/assets/b0f721de-5e86-4823-9d13-643aed06eb31" width="42%" alt="Meeting Details" />
</p>

### 🛡️ Admin Dashboard

Manage platform skills and access administrative functionality.

<p align="center">
  <img src="https://github.com/user-attachments/assets/be64e506-c174-49bd-bae1-c32931a6ad8b" width="42%" alt="Admin Dashboard" />
</p>

---

## ✨ Features

### 👤 Student Features
- **Authentication:** Register and log in securely using Firebase Authentication.
- **Profile Management:** Manage your bio, college, semester, and profile picture.
- **Skill Management:** Add skills you can teach and skills you want to learn, with proficiency levels.
- **Student Discovery:** Search for peers based on their skills and colleges.
- **Ratings & Reviews:** View user ratings and session history.

### 🤝 Learning & Meeting Features
- **Learning Requests:** Send personalized requests with preferred learning times.
- **Request Management:** Accept or reject incoming learning requests.
- **Zoom Integration:** Generate Zoom meeting links for scheduled sessions using the Zoom API.
- **Meeting Dashboard:** View upcoming, completed, and cancelled sessions.

### 🛡️ Admin Features
- **Role-Based Access:** Restrict administrative functionality to authorized admin accounts.
- **Skill Management:** Add, edit, or deactivate skills.
- **Platform Monitoring:** Support administrative oversight of platform activity.

---

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| **Flutter** | Cross-platform application UI |
| **Dart** | Programming language |
| **Firebase Authentication** | User authentication |
| **Cloud Firestore** | Real-time NoSQL database |
| **Cloudinary API** | Profile image hosting and delivery |
| **Zoom API** | Online meeting integration |
| **Cloudflare Workers** | Server-side proxy for Zoom API requests |
| **Provider** | State management |
| **URL Launcher** | Open external applications and meeting links |

---

## ⚙️ Prerequisites

Before running the project, install or configure:

- Flutter SDK (stable channel)
- Dart SDK (included with Flutter)
- Android Studio or Visual Studio Code
- A Firebase project with Authentication and Cloud Firestore enabled
- A Cloudinary account
- A Zoom developer application with the required API permissions
- A Cloudflare account, if using the Worker proxy

---

## 🚀 Installation

### Clone the repository

```bash
git clone https://github.com/niravkahir/Skill-Bridge-flutter.git
cd Skill-Bridge-flutter
```

If you find Skill Bridge useful, consider giving the repository a ⭐ on GitHub!
