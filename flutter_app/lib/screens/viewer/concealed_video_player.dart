import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../constants/app_constants.dart';

class ConcealedVideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String lessonTitle;

  const ConcealedVideoPlayerScreen({
    Key? key,
    required this.videoId,
    required this.lessonTitle,
  }) : super(key: key);

  @override
  State<ConcealedVideoPlayerScreen> createState() => _ConcealedVideoPlayerScreenState();
}

class _ConcealedVideoPlayerScreenState extends State<ConcealedVideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _enforceFlagSecure();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: false,
      ),
    );
  }

  void _enforceFlagSecure() async {
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.lessonTitle, style: const TextStyle(fontSize: 16)),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppConstants.secondaryColor,
          progressColors: const ProgressBarColors(
            playedColor: AppConstants.primaryColor,
            handleColor: AppConstants.secondaryColor,
          ),
        ),
      ),
    );
  }
}

