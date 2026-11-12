class CertificateModel {
  final String certificateId;
  final String userId;
  final String userName;
  final String courseTitle;
  final String issueDate;
  final String verificationHash;
  final String instructor;

  CertificateModel({
    required this.certificateId,
    required this.userId,
    required this.userName,
    required this.courseTitle,
    required this.issueDate,
    required this.verificationHash,
    required this.instructor,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      certificateId: json['certificate_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      courseTitle: json['course_title']?.toString() ?? '',
      issueDate: json['issue_date']?.toString() ?? '',
      verificationHash: json['verification_hash']?.toString() ?? '',
      instructor: json['instructor']?.toString() ?? 'Abhishek Maheshwari',
    );
  }
}

