# Product Requirements Document (PRD) - v2.0
## Project: TutorFlow SecureNotes & Mini-LMS (Zero-Cost Educational Platform)
**Client / Lead Developer:** Abhishek Maheshwari  
**Institute / Business:** Prince Electronics & Electricals, Bilsi  
**Curriculum Integration:** Bachelor of Computer Applications (BCA) — [Pravin-hub-rgb/BCA](https://github.com/Pravin-hub-rgb/BCA)  
**Target Google Sheet:** [TutorFlow Backend (1AKGL9CXjkpGAdO3k22l8cmpHUgVAWfLTajzPg7GT6CI)](https://docs.google.com/spreadsheets/d/1AKGL9CXjkpGAdO3k22l8cmpHUgVAWfLTajzPg7GT6CI/edit?usp=sharing)  
**Target Google Drive Folder:** [TutorFlow Notes Folder (1RHH23n7u3bwZkjlDeqI9FjoJoCH0DdNQ)](https://drive.google.com/drive/folders/1RHH23n7u3bwZkjlDeqI9FjoJoCH0DdNQ?usp=sharing)  
**Role:** Technical Project Manager & Chief of Staff to the CEO  

---

## 1. Executive Summary & Core Value Proposition

TutorFlow SecureNotes is a zero-operating-cost, anti-piracy-hardened Learning Management System (LMS) and study note delivery application. It empowers educators to distribute proprietary BCA study notes, host live interactive video lectures, automatically record student attendance, and issue verifiable digital certificates without paying for cloud servers, database subscriptions, or bandwidth.

---

## 2. Master System Components

### 2.1 Backend & Content Repositories
1. **Google Sheets Database (Sheet ID: `1AKGL9CXjkpGAdO3k22l8cmpHUgVAWfLTajzPg7GT6CI`):**
   * Tabs: `Users`, `Notes`, `Purchases`, `LiveClasses`, `Attendance`, `Certificates`.
2. **Google Drive Cloud Storage (Folder ID: `1RHH23n7u3bwZkjlDeqI9FjoJoCH0DdNQ`):**
   * Stores master PDF study notes for all BCA semesters (C Programming, Data Structures, DBMS, Java, OS, Python).
3. **YouTube (Unlisted CDN):**
   * High-definition video lectures streamed without bandwidth charges.
4. **Jitsi Meet & Google Meet / Zoom:**
   * Embedded and external real-time video classrooms at zero platform cost.

---

## 3. Detailed Functional Modules

### 3.1 Anti-Piracy Document Protection (DRM)
* **FLAG_SECURE Mandatory:** Enforced across all notes, videos, and live classrooms to block Android native screenshots, screen recorders, and app thumbnails.
* **Internal Sandbox Storage:** Downloaded files are saved to `context.filesDir` (`path_provider.getApplicationDocumentsDirectory()`) with an obfuscated extension (`.tflock`). Files are completely invisible to external file managers, WhatsApp, and gallery apps.
* **In-Memory Streaming:** PDFs are rendered strictly via Flutter canvas byte streams (`syncfusion_flutter_pdfviewer` or `pdfx`), never opening third-party viewers. Text copy/paste and export are disabled.

### 3.2 Dual Live Lecture System
* **Option 1 (Embedded In-App Jitsi Meet):**
  * Uses `jitsi_meet_flutter_sdk` to embed interactive classrooms directly in the Flutter UI.
  * Screen recording blocked via `FLAG_SECURE`.
  * Dynamic room mapping from the `LiveClasses` sheet tab.
* **Option 2 (Google Meet / Zoom Direct Launch):**
  * Secure intent / WebView launcher for scheduled Google Meet or Zoom lecture URLs.

### 3.3 Automated Attendance Tracking System
* When a student joins a live class or accesses study materials, an automated background event logs the student's `user_id`, `name`, `session_id`, `session_title`, and `timestamp` into the `Attendance` tab in Google Sheets.
* Zero manual roll-call required.

### 3.4 Digital Certificate Generation & Verification
* When a student completes a course module, the app enables a "Generate Certificate" action.
* **Local On-Device Painting:** Dynamically paints the student name, course title, issue date, and instructor signature onto a formal certificate using the `pdf` package.
* **Tamper-Evident Hash:** Generates a unique certificate ID (`TF-BCA-XXXXXX`) and verification hash logged in the `Certificates` sheet tab for employer verification.

### 3.5 Course Catalog (BCA Curriculum)
* Pre-populated with BCA subjects from the `Pravin-hub-rgb/BCA` knowledge base:
  * Semester 1: C Programming & Algorithms
  * Semester 2: Data Structures & Algorithms
  * Semester 3: Database Management Systems (DBMS) & SQL
  * Semester 4: Java Programming & OOP Concepts
  * Semester 4: Operating Systems & Process Scheduling
  * Semester 5: Python for Modern Applications
* Search, filter, and category navigation.

### 3.6 Admin Management Dashboard
* Dedicated section for educator/admin (`admin@tutorflow.com`):
  * Publish notes with Drive File ID and YouTube link.
  * Schedule new live classes (Jitsi/Meet/Zoom).
  * Approve / unlock student purchase requests.
  * Audit student attendance logs.
