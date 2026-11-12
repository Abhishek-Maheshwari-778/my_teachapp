class NoteModel {
  final String noteId;
  final String title;
  final String subject;
  final String semester;
  final String description;
  final double price;
  final String driveFileId;
  final String youtubeVideoId;
  final bool isUnlocked;
  bool isDownloaded;

  NoteModel({
    required this.noteId,
    required this.title,
    required this.subject,
    required this.semester,
    required this.description,
    required this.price,
    required this.driveFileId,
    required this.youtubeVideoId,
    required this.isUnlocked,
    this.isDownloaded = false,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      noteId: json['note_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Note',
      subject: json['subject']?.toString() ?? 'General',
      semester: json['semester']?.toString() ?? 'BCA',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      driveFileId: json['drive_file_id']?.toString() ?? '',
      youtubeVideoId: json['youtube_video_id']?.toString() ?? '',
      isUnlocked: json['is_unlocked'] == true || json['is_unlocked']?.toString() == 'true',
    );
  }
}

