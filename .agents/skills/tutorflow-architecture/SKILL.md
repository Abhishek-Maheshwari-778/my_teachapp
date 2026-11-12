---
name: tutorflow-architecture
description: Runbooks and architecture specifications for building and maintaining the TutorFlow zero-cost LMS, including Google Apps Script endpoints, sandboxed PDF in-memory streaming, and Android anti-piracy configurations.
---

# TutorFlow Architecture Skill

## Core Directives for Agents Working in this Repository
1. **Never Save PDFs to Public Storage:** All downloaded document bytes must strictly reside inside the app's internal sandbox (`path_provider.getApplicationDocumentsDirectory()`). Never use `/sdcard` or public download paths.
2. **Strict FLAG_SECURE Enforcment:** Any activity or screen viewing notes or videos must have `WindowManager.LayoutParams.FLAG_SECURE` enabled to prevent screenshots, screen recording, and task switcher preview leaks.
3. **Follow HTTP Redirects on Backend Calls:** Google Apps Script Web App endpoints respond with HTTP 302 redirects to `script.googleusercontent.com`. Ensure any HTTP client (`http` or `dio`) is configured with `followRedirects: true`.
4. **Zero Unencrypted Direct URLs in Client:** Obscure and strip direct YouTube and Google Drive links in UI widgets to prevent URL scraping.

