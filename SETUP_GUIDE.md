# TutorFlow SecureNotes & Mini-LMS - Setup & Operations Guide (v2.0)
## Targeted for Sheet ID: `1AKGL9CXjkpGAdO3k22l8cmpHUgVAWfLTajzPg7GT6CI`
## Drive Folder ID: `1RHH23n7u3bwZkjlDeqI9FjoJoCH0DdNQ`

---

## Step 1: Deploy the Updated Google Apps Script

1. Open your master Google Sheet:
   [https://docs.google.com/spreadsheets/d/1AKGL9CXjkpGAdO3k22l8cmpHUgVAWfLTajzPg7GT6CI/edit?usp=sharing](https://docs.google.com/spreadsheets/d/1AKGL9CXjkpGAdO3k22l8cmpHUgVAWfLTajzPg7GT6CI/edit?usp=sharing)
2. In the top navigation, click **Extensions** > **Apps Script**.
3. Replace the contents of `Code.gs` with the updated code in [`backend/google-apps-script/Code.gs`](file:///c:/Users/princ/Downloads/myownlms/backend/google-apps-script/Code.gs).
4. Run the **`setupDatabase`** function once:
   - Select `setupDatabase` in the dropdown and click **Run**.
   - This automatically creates all 6 tabs (`Users`, `Notes`, `Purchases`, `LiveClasses`, `Attendance`, `Certificates`) with headers and pre-populates initial BCA course modules from Pravin's curriculum.
   - Also creates your default admin account: `admin@tutorflow.com` / `admin123`.
5. Click **Deploy** > **New deployment** > **Web app**.
   - **Execute as:** `Me`
   - **Who has access:** `Anyone`
   - Deploy and copy the Web App URL (paste it into `lib/constants/app_constants.dart` in the Flutter app).

---

## Step 2: Upload BCA Course Notes to Google Drive

1. Open your shared Google Drive Folder:
   [https://drive.google.com/drive/folders/1RHH23n7u3bwZkjlDeqI9FjoJoCH0DdNQ?usp=sharing](https://drive.google.com/drive/folders/1RHH23n7u3bwZkjlDeqI9FjoJoCH0DdNQ?usp=sharing)
2. Upload your PDF notes (e.g. C Programming, Data Structures, DBMS, Java, OS, Python).
3. Ensure the folder is set to: **"Anyone with the link can view"**.
4. In your Google Sheet `Notes` tab, paste the File ID into the `drive_file_id` column for each note.

---

## Step 3: Schedule Live Lectures

1. In your Google Sheet, open the **`LiveClasses`** tab (or use the in-app Admin Dashboard).
2. To use free embedded Jitsi:
   - Set `meeting_type` to `JITSI`.
   - Set `meeting_room_or_url` to a custom room name, e.g., `TutorFlow_BCA_Class_101`.
   - Students tap "Join Live Class" inside the app and enter the interactive room without leaving the app!
3. To use Google Meet or Zoom:
   - Set `meeting_type` to `MEET` or `ZOOM`.
   - Set `meeting_room_or_url` to your meeting link (e.g., `https://meet.google.com/abc-defg-hij`).
