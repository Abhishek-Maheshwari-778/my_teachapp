import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/note_model.dart';
import '../models/live_class_model.dart';
import '../models/certificate_model.dart';

class ApiService {
  final http.Client _client = http.Client();

  /// Execute an HTTP POST to Google Apps Script following 302 redirects cleanly
  Future<Map<String, dynamic>> _postToGas(Map<String, dynamic> payload) async {
    try {
      final response = await _client.post(
        Uri.parse(AppConstants.gasWebAppUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // Handle Apps Script 302 redirect manually if client didn't auto-follow
      if (response.statusCode == 302 || response.statusCode == 301) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final redirectedResponse = await _client.get(Uri.parse(redirectUrl));
          return jsonDecode(redirectedResponse.body) as Map<String, dynamic>;
        }
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {'status': 'error', 'message': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// 1. User Registration
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    return await _postToGas({
      'action': 'register',
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
  }

  /// 2. User Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await _postToGas({
      'action': 'login',
      'email': email,
      'password': password,
    });
  }

  /// 3. Fetch BCA Catalog & Unlock Status
  Future<List<NoteModel>> getCatalog(String userId) async {
    final res = await _postToGas({
      'action': 'get_catalog',
      'user_id': userId,
    });

    if (res['status'] == 'success' && res['data'] is List) {
      return (res['data'] as List)
          .map((item) => NoteModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 4. Record Purchase (Manual UPI or Transaction Reference)
  Future<Map<String, dynamic>> recordPurchase({
    required String userId,
    required String noteId,
    required String txnReference,
  }) async {
    return await _postToGas({
      'action': 'record_purchase',
      'user_id': userId,
      'note_id': noteId,
      'txn_reference': txnReference,
    });
  }

  /// 5. Fetch Live Classes (Jitsi / Meet / Zoom)
  Future<List<LiveClassModel>> getLiveClasses(String userId) async {
    final res = await _postToGas({
      'action': 'get_live_classes',
      'user_id': userId,
    });

    if (res['status'] == 'success' && res['data'] is List) {
      return (res['data'] as List)
          .map((item) => LiveClassModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 6. Automated Attendance Logging
  Future<bool> markAttendance({
    required String userId,
    required String userName,
    required String sessionId,
    required String sessionTitle,
    String sessionType = 'LIVE_CLASS',
  }) async {
    final res = await _postToGas({
      'action': 'mark_attendance',
      'user_id': userId,
      'user_name': userName,
      'session_id': sessionId,
      'session_title': sessionTitle,
      'session_type': sessionType,
    });

    return res['status'] == 'success';
  }

  /// 7. Fetch User Certificates
  Future<List<CertificateModel>> getCertificates(String userId) async {
    final res = await _postToGas({
      'action': 'get_certificates',
      'user_id': userId,
    });

    if (res['status'] == 'success' && res['data'] is List) {
      return (res['data'] as List)
          .map((item) => CertificateModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 8. Request / Generate Digital Certificate
  Future<Map<String, dynamic>> generateCertificate({
    required String userId,
    required String userName,
    required String courseTitle,
  }) async {
    return await _postToGas({
      'action': 'generate_certificate',
      'user_id': userId,
      'user_name': userName,
      'course_title': courseTitle,
    });
  }

  /// Admin Actions: Add Note
  Future<bool> adminAddNote({
    required String title,
    required String subject,
    required String semester,
    required String description,
    required double price,
    required String driveFileId,
    required String youtubeVideoId,
  }) async {
    final res = await _postToGas({
      'action': 'admin_add_note',
      'title': title,
      'subject': subject,
      'semester': semester,
      'description': description,
      'price': price,
      'drive_file_id': driveFileId,
      'youtube_video_id': youtubeVideoId,
    });
    return res['status'] == 'success';
  }

  /// Admin Actions: Schedule Live Class
  Future<bool> adminAddLiveClass({
    required String title,
    required String subject,
    required String instructor,
    required String meetingType,
    required String meetingRoomOrUrl,
  }) async {
    final res = await _postToGas({
      'action': 'admin_add_live_class',
      'title': title,
      'subject': subject,
      'instructor': instructor,
      'meeting_type': meetingType,
      'meeting_room_or_url': meetingRoomOrUrl,
    });
    return res['status'] == 'success';
  }
}

