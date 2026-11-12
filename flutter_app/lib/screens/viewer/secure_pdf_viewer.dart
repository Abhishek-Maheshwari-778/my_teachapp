import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../constants/app_constants.dart';

class SecurePdfViewerScreen extends StatefulWidget {
  final File sandboxedFile;
  final String noteTitle;

  const SecurePdfViewerScreen({
    Key? key,
    required this.sandboxedFile,
    required this.noteTitle,
  }) : super(key: key);

  @override
  State<SecurePdfViewerScreen> createState() => _SecurePdfViewerScreenState();
}

class _SecurePdfViewerScreenState extends State<SecurePdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();

  @override
  void initState() {
    super.initState();
    _enforceFlagSecure();
  }

  void _enforceFlagSecure() async {
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteTitle, style: const TextStyle(fontSize: 16)),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0);
            },
          ),
        ],
      ),
      body: SfPdfViewer.file(
        widget.sandboxedFile,
        controller: _pdfViewerController,
        enableTextSelection: false, // Prevents text selection & copy-pasting
        canShowScrollHead: true,
        canShowScrollStatus: true,
        pageSpacing: 8,
      ),
    );
  }
}

