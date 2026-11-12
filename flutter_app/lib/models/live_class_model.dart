class LiveClassModel {
  final String classId;
  final String title;
  final String instructor;
  final String subject;
  final String meetingType; // 'JITSI' | 'MEET' | 'ZOOM'
  final String meetingRoomOrUrl;
  final String scheduleTime;
  final bool isActive;

  LiveClassModel({
    required this.classId,
    required this.title,
    required this.instructor,
    required this.subject,
    required this.meetingType,
    required this.meetingRoomOrUrl,
    required this.scheduleTime,
    required this.isActive,
  });

  factory LiveClassModel.fromJson(Map<String, dynamic> json) {
    return LiveClassModel(
      classId: json['class_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Live Session',
      instructor: json['instructor']?.toString() ?? 'Abhishek Maheshwari',
      subject: json['subject']?.toString() ?? 'Computer Applications',
      meetingType: json['meeting_type']?.toString().toUpperCase() ?? 'JITSI',
      meetingRoomOrUrl: json['meeting_room_or_url']?.toString() ?? '',
      scheduleTime: json['schedule_time']?.toString() ?? '',
      isActive: json['is_active'] == true || json['is_active']?.toString() == 'true',
    );
  }
}

