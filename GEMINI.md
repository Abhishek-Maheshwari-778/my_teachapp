# Repository Rules: TutorFlow SecureNotes

## Security & Anti-Piracy Architecture
- **In-Memory Byte Stream Rendering:** Never pass local raw file paths to external PDF reader intents (Adobe, Chrome, Drive). Render bytes strictly via native Flutter canvas widgets (`syncfusion_flutter_pdfviewer` or `pdfx`).
- **Internal Sandbox Only:** Write all downloaded assets to `context.filesDir` / `getApplicationDocumentsDirectory()`. Never request or write to `WRITE_EXTERNAL_STORAGE` or public shared media directories.
- **FLAG_SECURE Mandatory:** Enforce `FLAG_SECURE` at both Android native level (`MainActivity.kt`) and Flutter widget tree level.

## Backend Architecture
- **Zero Cost Protocol:** Backend database is Google Sheets managed through Google Apps Script JSON endpoints (`doGet` / `doPost`).
- **Always Follow Redirects:** Google Apps Script uses HTTP 302 redirects. HTTP client requests must follow redirects with a maximum limit of 5.
- **Passwords:** Passwords must be hashed using SHA-256 before storing in the sheet.

