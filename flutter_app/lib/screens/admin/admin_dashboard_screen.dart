import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../constants/app_constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserModel currentUser;
  const AdminDashboardScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiService = ApiService();

  // Note Form Controllers
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _semesterController = TextEditingController(text: 'Semester 1');
  final _descController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _driveIdController = TextEditingController();
  final _ytIdController = TextEditingController();
  bool _isPublishingNote = false;

  // Live Class Form Controllers
  final _liveTitleController = TextEditingController();
  final _liveSubjectController = TextEditingController();
  final _liveInstructorController = TextEditingController(text: AppConstants.developerName);
  String _selectedMeetingType = 'JITSI';
  final _meetingUrlController = TextEditingController();
  bool _isSchedulingClass = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _publishNote() async {
    if (_titleController.text.isEmpty || _driveIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and Drive File ID are required')),
      );
      return;
    }

    setState(() => _isPublishingNote = true);
    final success = await _apiService.adminAddNote(
      title: _titleController.text.trim(),
      subject: _subjectController.text.trim().isEmpty ? 'General' : _subjectController.text.trim(),
      semester: _semesterController.text.trim(),
      description: _descController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0.0,
      driveFileId: _driveIdController.text.trim(),
      youtubeVideoId: _ytIdController.text.trim(),
    );

    setState(() => _isPublishingNote = false);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note published to Google Sheets successfully!')),
      );
      _titleController.clear();
      _descController.clear();
      _driveIdController.clear();
      _ytIdController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to publish note.')),
      );
    }
  }

  void _scheduleLiveClass() async {
    if (_liveTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class title is required')),
      );
      return;
    }

    setState(() => _isSchedulingClass = true);
    final success = await _apiService.adminAddLiveClass(
      title: _liveTitleController.text.trim(),
      subject: _liveSubjectController.text.trim().isEmpty ? 'BCA' : _liveSubjectController.text.trim(),
      instructor: _liveInstructorController.text.trim(),
      meetingType: _selectedMeetingType,
      meetingRoomOrUrl: _meetingUrlController.text.trim(),
    );

    setState(() => _isSchedulingClass = false);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live class scheduled in Google Sheets!')),
      );
      _liveTitleController.clear();
      _meetingUrlController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to schedule class.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Operations Panel'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.note_add), text: 'Publish Note'),
            Tab(icon: Icon(Icons.video_call), text: 'Schedule Class'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Publish Study Note
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Publish New Study Note (Google Drive Sync)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Note Title *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Subject (e.g. DBMS)', border: OutlineInputBorder()))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _semesterController, decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: _descController, maxLines: 2, decoration: const InputDecoration(labelText: 'Description / Chapters', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (₹) - Set 0 for free', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                  controller: _driveIdController,
                  decoration: const InputDecoration(
                    labelText: 'Google Drive File ID *',
                    helperText: 'From: drive.google.com/file/d/FILE_ID/view',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ytIdController,
                  decoration: const InputDecoration(
                    labelText: 'YouTube Video ID (Optional)',
                    helperText: 'e.g. dQw4w9WgXcQ (from unlisted video)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isPublishingNote ? null : _publishNote,
                  icon: const Icon(Icons.cloud_upload),
                  label: _isPublishingNote ? const CircularProgressIndicator(color: Colors.white) : const Text('Publish to Google Sheets'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),

          // Tab 2: Schedule Live Class
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Schedule Live Class (Jitsi / Meet / Zoom)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                TextField(controller: _liveTitleController, decoration: const InputDecoration(labelText: 'Class Title *', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _liveSubjectController, decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _liveInstructorController, decoration: const InputDecoration(labelText: 'Instructor Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedMeetingType,
                  decoration: const InputDecoration(labelText: 'Meeting Platform', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'JITSI', child: Text('Jitsi Meet (Free In-App Interactive)')),
                    DropdownMenuItem(value: 'MEET', child: Text('Google Meet (External Link)')),
                    DropdownMenuItem(value: 'ZOOM', child: Text('Zoom Meeting (External Link)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMeetingType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _meetingUrlController,
                  decoration: InputDecoration(
                    labelText: _selectedMeetingType == 'JITSI' ? 'Jitsi Room Name (Optional)' : 'Meeting URL *',
                    helperText: _selectedMeetingType == 'JITSI' ? 'Leave empty to auto-generate a room' : 'https://meet.google.com/...',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isSchedulingClass ? null : _scheduleLiveClass,
                  icon: const Icon(Icons.video_call),
                  label: _isSchedulingClass ? const CircularProgressIndicator(color: Colors.white) : const Text('Schedule Class in Sheets'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

