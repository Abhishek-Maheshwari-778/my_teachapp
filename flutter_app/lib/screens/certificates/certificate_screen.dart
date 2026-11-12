import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/certificate_model.dart';
import '../../services/api_service.dart';
import '../../services/certificate_service.dart';
import '../../constants/app_constants.dart';

class CertificateScreen extends StatefulWidget {
  final UserModel currentUser;
  const CertificateScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final _apiService = ApiService();
  List<CertificateModel> _certificates = [];
  bool _isLoading = true;

  final List<String> _bcaTracks = [
    'BCA Semester 1: C Programming & Algorithms',
    'BCA Semester 2: Data Structures & Algorithms',
    'BCA Semester 3: Database Management Systems',
    'BCA Semester 4: Java Programming & OOP',
    'BCA Semester 4: Operating Systems & Architecture',
    'BCA Semester 5: Python for Applications',
  ];

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  void _loadCertificates() async {
    setState(() => _isLoading = true);
    final certs = await _apiService.getCertificates(widget.currentUser.userId);
    if (mounted) {
      setState(() {
        _certificates = certs;
        _isLoading = false;
      });
    }
  }

  void _requestNewCertificate() {
    String selectedTrack = _bcaTracks.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Claim Course Certificate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select completed BCA curriculum track:'),
              const SizedBox(height: 12),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedTrack,
                items: _bcaTracks
                    .map((track) => DropdownMenuItem(value: track, child: Text(track, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedTrack = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await _apiService.generateCertificate(
                  userId: widget.currentUser.userId,
                  userName: widget.currentUser.name,
                  courseTitle: selectedTrack,
                );
                if (res['status'] == 'success') {
                  _loadCertificates();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Certificate generated and recorded!')),
                  );
                }
              },
              child: const Text('Generate Now'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _requestNewCertificate,
        icon: const Icon(Icons.add_award),
        label: const Text('Claim Certificate'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _certificates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.workspace_premium_outlined, size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('No certificates issued yet.', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Complete BCA modules and claim your certificate below!', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _certificates.length,
                  itemBuilder: (context, index) {
                    final cert = _certificates[index];
                    return Card(
                      elevation: 2,
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
                                  label: Text(cert.certificateId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  backgroundColor: Colors.amber.shade100,
                                ),
                                Text(cert.issueDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(cert.courseTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Recipient: ${cert.userName}', style: const TextStyle(fontSize: 13)),
                            Text('Signed by: ${cert.instructor}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => CertificateService.printCertificate(cert),
                              icon: const Icon(Icons.print, size: 18),
                              label: const Text('Print / Save Certificate PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

