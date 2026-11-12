import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/note_model.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../constants/app_constants.dart';
import '../viewer/secure_pdf_viewer.dart';
import '../viewer/concealed_video_player.dart';
import '../live/live_classes_screen.dart';
import '../certificates/certificate_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';

class CatalogScreen extends StatefulWidget {
  final UserModel currentUser;
  const CatalogScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _apiService = ApiService();
  final _storageService = StorageService();

  List<NoteModel> _notes = [];
  List<NoteModel> _filteredNotes = [];
  bool _isLoading = true;
  String _selectedSemester = 'All';
  String _searchQuery = '';
  String _cacheSize = '0 MB';

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    _refreshCacheSize();
  }

  void _refreshCacheSize() async {
    final size = await _storageService.getCachedStorageSize();
    if (mounted) setState(() => _cacheSize = size);
  }

  void _loadCatalog() async {
    setState(() => _isLoading = true);
    final notes = await _apiService.getCatalog(widget.currentUser.userId);

    // Verify local offline status for each note
    for (var note in notes) {
      note.isDownloaded = await _storageService.isNoteDownloaded(note.noteId);
    }

    if (mounted) {
      setState(() {
        _notes = notes;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredNotes = _notes.where((note) {
        final matchesSem = _selectedSemester == 'All' || note.semester == _selectedSemester;
        final matchesSearch = note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            note.subject.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesSem && matchesSearch;
      }).toList();
    });
  }

  void _handleDownload(NoteModel note) async {
    if (note.driveFileId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document link not yet assigned by educator')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading "${note.title}" into secure sandbox...')),
    );

    final success = await _storageService.downloadAndSandboxNote(
      noteId: note.noteId,
      driveFileId: note.driveFileId,
    );

    if (success) {
      setState(() {
        note.isDownloaded = true;
      });
      _refreshCacheSize();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloaded! Ready for offline study.')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed. Verify internet connection.')),
      );
    }
  }

  void _openSecureViewer(NoteModel note) async {
    final file = await _storageService.getSandboxedFile(note.noteId);
    if (!await file.exists()) {
      _handleDownload(note);
      return;
    }

    // Mark automated attendance for reading module
    _apiService.markAttendance(
      userId: widget.currentUser.userId,
      userName: widget.currentUser.name,
      sessionId: note.noteId,
      sessionTitle: note.title,
      sessionType: 'NOTE_STUDY',
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecurePdfViewerScreen(
          sandboxedFile: file,
          noteTitle: note.title,
        ),
      ),
    );
  }

  void _showUnlockDialog(NoteModel note) {
    final refController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Unlock ${note.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: ₹${note.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Pay via UPI to: 9876543210@upi\nOr scan QR at Prince Electronics & Electricals, Bilsi.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: refController,
              decoration: const InputDecoration(
                labelText: 'UPI Reference / UTR Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await _apiService.recordPurchase(
                userId: widget.currentUser.userId,
                noteId: note.noteId,
                txnReference: refController.text.trim(),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res['status'] == 'success' ? 'Payment submitted! Admin will approve.' : 'Error submitting payment')),
              );
              _loadCatalog();
            },
            child: const Text('Submit Reference'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final semesters = ['All', 'Semester 1', 'Semester 2', 'Semester 3', 'Semester 4', 'Semester 5', 'Semester 6'];

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppConstants.appName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Welcome, ${widget.currentUser.name}', style: const TextStyle(fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_camera_front),
            tooltip: 'Live Classes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LiveClassesScreen(currentUser: widget.currentUser),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.card_membership),
            tooltip: 'Certificates',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CertificateScreen(currentUser: widget.currentUser),
                ),
              );
            },
          ),
          if (widget.currentUser.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Dashboard',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminDashboardScreen(currentUser: widget.currentUser),
                  ),
                );
              },
            ),
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'clear_cache') {
                await _storageService.clearAllCache();
                _refreshCacheSize();
                _loadCatalog();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline cache cleared')));
              } else if (val == 'logout') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'cache_info', enabled: false, child: Text('Offline Cache: $_cacheSize')),
              const PopupMenuItem(value: 'clear_cache', child: Text('Clear Offline Storage')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // BCA Curriculum Search & Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search BCA notes or subjects...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _applyFilter();
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: semesters.map((sem) {
                      final isSelected = _selectedSemester == sem;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(sem),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _selectedSemester = sem;
                              _applyFilter();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Course Notes Grid / List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No study notes found for this category.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadCatalog(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = _filteredNotes[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Chip(
                                          label: Text(note.subject, style: const TextStyle(fontSize: 11)),
                                          backgroundColor: AppConstants.secondaryColor.withOpacity(0.15),
                                        ),
                                        Chip(
                                          label: Text(note.semester, style: const TextStyle(fontSize: 11)),
                                          backgroundColor: Colors.grey.shade100,
                                        ),
                                        note.isUnlocked
                                            ? const Chip(
                                                label: Text('UNLOCKED', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                                                backgroundColor: Color(0xFFE8F5E9),
                                              )
                                            : Chip(
                                                label: Text('₹${note.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                                                backgroundColor: const Color(0xFFFFF8E1),
                                              ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      note.title,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    if (note.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        note.description,
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        if (note.isUnlocked) ...[
                                          if (note.isDownloaded)
                                            ElevatedButton.icon(
                                              onPressed: () => _openSecureViewer(note),
                                              icon: const Icon(Icons.chrome_reader_mode, size: 18),
                                              label: const Text('Read Offline'),
                                              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor, foregroundColor: Colors.white),
                                            )
                                          else
                                            OutlinedButton.icon(
                                              onPressed: () => _handleDownload(note),
                                              icon: const Icon(Icons.download, size: 18),
                                              label: const Text('Download Note'),
                                            ),
                                          const SizedBox(width: 8),
                                          if (note.youtubeVideoId.isNotEmpty)
                                            IconButton(
                                              icon: const Icon(Icons.play_circle_filled, color: Colors.red),
                                              tooltip: 'Watch Video Class',
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ConcealedVideoPlayerScreen(
                                                      videoId: note.youtubeVideoId,
                                                      lessonTitle: note.title,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                        ] else ...[
                                          ElevatedButton.icon(
                                            onPressed: () => _showUnlockDialog(note),
                                            icon: const Icon(Icons.lock_open, size: 18),
                                            label: const Text('Unlock Access'),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

