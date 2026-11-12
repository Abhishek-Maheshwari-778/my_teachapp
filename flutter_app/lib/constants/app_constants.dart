import 'package:flutter/material.dart';

class AppConstants {
  // Replace with your deployed Google Apps Script Web App URL from Step 1 of SETUP_GUIDE.md
  static const String gasWebAppUrl = 'https://script.google.com/macros/s/AKfycbz_REPLACE_WITH_YOUR_DEPLOYED_GAS_URL/exec';

  // Configured IDs from chat.text
  static const String spreadsheetId = '1AKGL9CXjkpGAdO3k22l8cmpHUgVAWfLTajzPg7GT6CI';
  static const String driveFolderId = '1RHH23n7u3bwZkjlDeqI9FjoJoCH0DdNQ';

  // Attribution & Developer Info
  static const String appName = 'TutorFlow BCA LMS';
  static const String appTagline = 'Zero-Cost Secure Study Ecosystem';
  static const String developerName = 'Abhishek Maheshwari';
  static const String instituteLocation = 'Prince Electronics & Electricals, Bilsi';
  static const String curriculumSource = 'https://github.com/Pravin-hub-rgb/BCA';

  // UI Theme Colors
  static const Color primaryColor = Color(0xFF1E3A8A); // Deep Royal Blue
  static const Color secondaryColor = Color(0xFF0EA5E9); // Sky Blue Accent
  static const Color accentColor = Color(0xFF10B981); // Emerald Green
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color darkBackgroundColor = Color(0xFF0F172A);
  static const Color cardColor = Colors.white;

  // Direct Google Drive download stream link generator
  static String getDriveDirectDownloadUrl(String fileId) {
    return 'https://drive.google.com/uc?export=download&id=$fileId';
  }
}

