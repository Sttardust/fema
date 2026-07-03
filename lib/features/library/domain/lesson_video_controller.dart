import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';

class LessonVideoController {
  LessonVideoController(this.url);
  final String url;
  VideoPlayerController? _video;
  ChewieController? chewie;

  static bool isPlayableUrl(String? url) =>
      url != null &&
      (Uri.tryParse(url)?.hasScheme ?? false) &&
      (url.startsWith('http://') || url.startsWith('https://'));

  Future<void> initialize() async {
    _video = VideoPlayerController.networkUrl(Uri.parse(url));
    await _video!.initialize();
    chewie = ChewieController(
      videoPlayerController: _video!,
      autoPlay: false,
      allowFullScreen: true,
      allowMuting: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.primary,
        handleColor: AppColors.primary,
        bufferedColor: AppColors.primaryLight,
        backgroundColor: AppColors.greyLight,
      ),
    );
  }

  void dispose() {
    chewie?.dispose();
    _video?.dispose();
  }
}
