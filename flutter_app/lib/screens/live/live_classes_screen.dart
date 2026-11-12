import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../models/live_class_model.dart';
import '../../services/api_service.dart';
import '../../constants/app_constants.dart';

class LiveClassesScreen extends StatefulWidget {
  final UserModel currentUser;
  const LiveClassesScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<LiveClassesScreen> createState() => _LiveClassesScreenState();
}

class _LiveClassesScreenState extends State<LiveClassesScreen> {
  final _apiService = ApiService();
  final _jitsiMeet = JitsiMeet();

  List<LiveClassModel> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _enforceFlagSecure();
    _loadLiveClasses();
  }

  void _enforceFlagSecure() async {
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
  }

  void _loadLiveClasses() async {
    setState(() => _isLoading = true);
    final classes = await _apiService.getLiveClasses(widget.currentUser.userId);
    if (mounted) {
      setState(() {
        _classes = classes;
        _isLoading = false;
      });
    }
  }

  void _joinClass(LiveClassModel liveClass) async {
    // 1. Automatically log student attendance in Google Sheets
    _apiService.markAttendance(
      userId: widget.currentUser.userId,
      userName: widget.currentUser.name,
      sessionId: liveClass.classId,
      sessionTitle: liveClass.title,
      sessionType: 'LIVE_CLASS',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance logged! Connecting to live class...')),
    );

    // 2. Launch according to meeting type
    if (liveClass.meetingType == 'JITSI') {
      var options = JitsiMeetConferenceOptions(
        serverURL: "https://meet.jit.si",
        room: liveClass.meetingRoomOrUrl.isNotEmpty
            ? liveClass.meetingRoomOrUrl
            : 'TutorFlow_BCA_${liveClass.classId}',
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
          "subject": liveClass.title,
        },
        featureFlags: {
          "unsaferoomwarning.enabled": false,
          "welcomepage.enabled": false,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: widget.currentUser.name,
          email: widget.currentUser.email,
        ),
      );

      await _jitsiMeet.join(options);
    } else {
      // External Google Meet or Zoom URL launch
      final uri = Uri.parse(liveClass.meetingRoomOrUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external meeting link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Live BCA Classes'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_camera_back_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('No live classes scheduled right now.', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text('Instructor: ${AppConstants.developerName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadLiveClasses(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _classes.length,
                    itemBuilder: (context, index) {
                      final item = _classes[index];
                      final isJitsi = item.meetingType == 'JITSI';

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Chip(
                                    label: Text(item.subject, style: const TextStyle(fontSize: 11)),
                                    backgroundColor: Colors.blue.shade50,
                                  ),
                                  Chip(
                                    label: Text(item.meetingType, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                    backgroundColor: isJitsi ? Colors.purple : Colors.teal,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Instructor: ${item.instructor}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _joinClass(item),
                                icon: Icon(isJitsi ? Icons.videocam : Icons.open_in_browser),
                                label: Text(isJitsi ? 'Join Live Interactive Class' : 'Launch Meeting Link'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isJitsi ? Colors.purple : Colors.teal,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(44),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

