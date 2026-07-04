import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../auth/domain/auth_repository.dart';
import '../domain/course_editor_repository.dart';
import '../domain/lesson_upload_controller.dart';

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

Future<void> showLessonSheet(
  BuildContext context,
  WidgetRef ref, {
  required String courseId,
  Map<String, dynamic>? existing,
  required List<int> existingOrders,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: MediaQuery.of(ctx).viewInsets,
      child: _LessonSheet(
        courseId: courseId,
        existing: existing,
        existingOrders: existingOrders,
      ),
    ),
  );
  // Invalidate after sheet closes (whether saved or cancelled — idempotent).
  ref.invalidate(courseEditorLessonsProvider(courseId));
}

// ---------------------------------------------------------------------------
// Upload state machine
// ---------------------------------------------------------------------------

enum _UploadPhase { idle, uploading, done }

class _UploadState {
  final _UploadPhase phase;
  final UploadTask? task;
  final double progress; // 0..1
  final String? url;
  final String? fileName;

  const _UploadState({
    this.phase = _UploadPhase.idle,
    this.task,
    this.progress = 0,
    this.url,
    this.fileName,
  });

  _UploadState copyWith({
    _UploadPhase? phase,
    UploadTask? task,
    double? progress,
    String? url,
    String? fileName,
    bool clearTask = false,
    bool clearUrl = false,
  }) =>
      _UploadState(
        phase: phase ?? this.phase,
        task: clearTask ? null : (task ?? this.task),
        progress: progress ?? this.progress,
        url: clearUrl ? null : (url ?? this.url),
        fileName: fileName ?? this.fileName,
      );

  bool get inFlight => phase == _UploadPhase.uploading;
}

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

class _LessonSheet extends ConsumerStatefulWidget {
  const _LessonSheet({
    required this.courseId,
    this.existing,
    required this.existingOrders,
  });

  final String courseId;
  final Map<String, dynamic>? existing;
  final List<int> existingOrders;

  @override
  ConsumerState<_LessonSheet> createState() => _LessonSheetState();
}

class _LessonSheetState extends ConsumerState<_LessonSheet> {
  // Controllers
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _transcriptCtrl;
  late final TextEditingController _bodyCtrl;

  // Mode
  late bool _isVideo;

  // Upload states
  _UploadState _videoUpload = const _UploadState();
  _UploadState _docUpload = const _UploadState();

  bool _saving = false;

  // Resolved URLs (initial from existing + post-upload)
  String? _videoUrl;
  String? _documentUrl;
  String? _documentName;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _isVideo = ex == null ? true : (ex['contentHtml'] == null || (ex['contentHtml'] as String).isEmpty);

    _titleCtrl = TextEditingController(text: ex?['title'] as String? ?? '');
    _descCtrl = TextEditingController(text: ex?['description'] as String? ?? '');
    _durationCtrl = TextEditingController(
      text: ex?['durationMinutes'] != null ? '${ex!['durationMinutes']}' : '',
    );
    _transcriptCtrl = TextEditingController(text: ex?['transcript'] as String? ?? '');
    _bodyCtrl = TextEditingController(text: ex?['contentHtml'] as String? ?? '');

    _videoUrl = ex?['videoUrl'] as String?;
    _documentUrl = ex?['documentUrl'] as String?;
    _documentName = ex?['documentName'] as String?;

    // If existing has a video URL already, start in "done" phase
    if (_videoUrl != null && _videoUrl!.isNotEmpty) {
      _videoUpload = _UploadState(
        phase: _UploadPhase.done,
        url: _videoUrl,
        fileName: 'Uploaded video',
      );
    }
    // If existing has a document URL already, start in "done" phase
    if (_documentUrl != null && _documentUrl!.isNotEmpty) {
      _docUpload = _UploadState(
        phase: _UploadPhase.done,
        url: _documentUrl,
        fileName: _documentName,
      );
    }

    _titleCtrl.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _videoUpload.task?.cancel();
    _docUpload.task?.cancel();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    _transcriptCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  String? get _uid => ref.read(authStateProvider).asData?.value?.uid;

  String _lessonId() {
    // Use existing id or generate one from timestamp for new lessons
    return widget.existing?['id'] as String? ?? 'ls_${DateTime.now().millisecondsSinceEpoch}';
  }

  bool get _hasInFlightUpload => _videoUpload.inFlight || _docUpload.inFlight;

  bool get _canSave =>
      _titleCtrl.text.trim().isNotEmpty && !_hasInFlightUpload && !_saving;

  // ── Video upload ──────────────────────────────────────────────────────────

  Future<void> _pickAndUploadVideo() async {
    final uid = _uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in. Please sign in and try again.')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null) return;

    final picked = result.files.single;
    if (picked.path == null) return;

    // Delete old video if replacing
    if (_videoUrl != null && _videoUrl!.isNotEmpty) {
      await LessonUploadController.deleteByUrl(_videoUrl!);
      if (!mounted) return;
      setState(() {
        _videoUrl = null;
      });
    }

    final lessonId = _lessonId();
    final controller = LessonUploadController();
    final file = File(picked.path!);
    final task = controller.startVideoUpload(
      uid: uid,
      courseId: widget.courseId,
      lessonId: lessonId,
      file: file,
    );

    if (!mounted) return;
    setState(() {
      _videoUpload = _UploadState(
        phase: _UploadPhase.uploading,
        task: task,
        progress: 0,
        fileName: picked.name,
      );
    });

    // Listen to progress
    task.snapshotEvents.listen((snapshot) {
      if (!mounted) return;
      final total = snapshot.totalBytes;
      final progress = total > 0 ? snapshot.bytesTransferred / total : 0.0;
      setState(() {
        _videoUpload = _videoUpload.copyWith(progress: progress);
      });
    });

    // Await completion
    try {
      await task;
      final url = await task.snapshot.ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        _videoUrl = url;
        _videoUpload = _UploadState(
          phase: _UploadPhase.done,
          url: url,
          fileName: picked.name,
        );
      });
    } on FirebaseException catch (e) {
      // Cancelled task throws FirebaseException — reset to idle silently
      if (!mounted) return;
      if (e.code == 'canceled') {
        setState(() {
          _videoUpload = const _UploadState();
        });
      } else {
        setState(() {
          _videoUpload = const _UploadState();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Try again.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _videoUpload = const _UploadState();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Try again.')),
      );
    }
  }

  void _cancelVideoUpload() {
    _videoUpload.task?.cancel();
    if (!mounted) return;
    setState(() {
      _videoUpload = const _UploadState();
    });
  }

  // ignore: unused_element
  Future<void> _removeVideo() async {
    if (_videoUrl != null && _videoUrl!.isNotEmpty) {
      await LessonUploadController.deleteByUrl(_videoUrl!);
    }
    if (!mounted) return;
    setState(() {
      _videoUrl = null;
      _videoUpload = const _UploadState();
    });
  }

  // ── Document upload ───────────────────────────────────────────────────────

  Future<void> _pickAndUploadDocument() async {
    final uid = _uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in. Please sign in and try again.')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result == null) return;

    final picked = result.files.single;
    if (picked.path == null) return;

    if (!LessonUploadController.isAllowedDocument(picked.name)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only PDF, DOC, and DOCX files are allowed.')),
      );
      return;
    }

    final lessonId = _lessonId();
    final controller = LessonUploadController();
    final file = File(picked.path!);
    final task = controller.startDocumentUpload(
      uid: uid,
      courseId: widget.courseId,
      lessonId: lessonId,
      fileName: picked.name,
      file: file,
    );

    if (!mounted) return;
    setState(() {
      _docUpload = _UploadState(
        phase: _UploadPhase.uploading,
        task: task,
        progress: 0,
        fileName: picked.name,
      );
    });

    task.snapshotEvents.listen((snapshot) {
      if (!mounted) return;
      final total = snapshot.totalBytes;
      final progress = total > 0 ? snapshot.bytesTransferred / total : 0.0;
      setState(() {
        _docUpload = _docUpload.copyWith(progress: progress);
      });
    });

    try {
      await task;
      final url = await task.snapshot.ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        _documentUrl = url;
        _documentName = picked.name;
        _docUpload = _UploadState(
          phase: _UploadPhase.done,
          url: url,
          fileName: picked.name,
        );
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      if (e.code == 'canceled') {
        setState(() {
          _docUpload = const _UploadState();
        });
      } else {
        setState(() {
          _docUpload = const _UploadState();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Try again.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _docUpload = const _UploadState();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Try again.')),
      );
    }
  }

  Future<void> _removeDocument() async {
    if (_documentUrl != null && _documentUrl!.isNotEmpty) {
      await LessonUploadController.deleteByUrl(_documentUrl!);
    }
    if (!mounted) return;
    setState(() {
      _documentUrl = null;
      _documentName = null;
      _docUpload = const _UploadState();
    });
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);

    try {
      final duration = int.tryParse(_durationCtrl.text.trim()) ?? 15;
      final existing = widget.existing;
      final order = (existing?['order'] as int?) ??
          CourseEditorRepository.nextOrder(widget.existingOrders);

      final repo = ref.read(courseEditorRepositoryProvider);

      final transcriptText = _transcriptCtrl.text.trim();
      final bodyText = _bodyCtrl.text.trim();

      await repo.saveLesson(
        widget.courseId,
        lessonId: existing?['id'] as String?,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        durationMinutes: duration,
        order: order,
        videoUrl: _isVideo ? (_videoUrl?.isNotEmpty == true ? _videoUrl : null) : null,
        transcript: _isVideo ? (transcriptText.isNotEmpty ? transcriptText : null) : null,
        contentHtml: !_isVideo ? (bodyText.isNotEmpty ? bodyText : null) : null,
        documentUrl: _documentUrl?.isNotEmpty == true ? _documentUrl : null,
        documentName: _documentName?.isNotEmpty == true ? _documentName : null,
      );

      if (!mounted) return;
      ref.invalidate(courseEditorLessonsProvider(widget.courseId));
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save lesson. Try again.")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build helpers ─────────────────────────────────────────────────────────

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.figtree(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textBody,
        ),
      );

  Widget _pillField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) =>
      Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.greyLight),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Center(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: GoogleFonts.figtree(fontSize: 14, color: AppColors.grey),
              isDense: true,
              isCollapsed: true,
            ),
            style: GoogleFonts.figtree(fontSize: 14, color: AppColors.textBody),
          ),
        ),
      );

  Widget _boxField({
    required TextEditingController controller,
    required String hint,
    required double height,
    int maxLines = 3,
  }) =>
      Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greyLight),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: GoogleFonts.figtree(fontSize: 14, color: AppColors.grey),
            isDense: true,
            isCollapsed: true,
          ),
          style: GoogleFonts.figtree(fontSize: 14, color: AppColors.textBody),
        ),
      );

  // ── Video upload zone ─────────────────────────────────────────────────────

  Widget _videoZone() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: _buildVideoZoneContent(),
    );
  }

  Widget _buildVideoZoneContent() {
    final phase = _videoUpload.phase;

    if (phase == _UploadPhase.done) {
      return Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF2BB37A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Video uploaded',
              style: GoogleFonts.figtree(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textBody,
              ),
            ),
          ),
          TextButton(
            onPressed: _pickAndUploadVideo,
            child: Text(
              'Replace',
              style: GoogleFonts.figtree(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      );
    }

    if (phase == _UploadPhase.uploading) {
      final pct = (_videoUpload.progress * 100).round();
      return Column(
        children: [
          Row(
            children: [
              // Upload tile
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud_upload_outlined, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _videoUpload.fileName ?? 'Uploading…',
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBody,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Uploading $pct%',
                      style: GoogleFonts.figtree(fontSize: 11.5, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.grey),
                onPressed: _cancelVideoUpload,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress track
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _videoUpload.progress,
              backgroundColor: Colors.white,
              color: AppColors.primary,
              minHeight: 6,
            ),
          ),
        ],
      );
    }

    // Idle
    return GestureDetector(
      onTap: _pickAndUploadVideo,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cloud_upload_outlined, size: 18, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload video',
            style: GoogleFonts.figtree(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'MP4 up to 500 MB',
            style: GoogleFonts.figtree(fontSize: 11.5, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  // ── Document attachment area ──────────────────────────────────────────────

  Widget _attachmentArea() {
    final phase = _docUpload.phase;

    if (phase == _UploadPhase.done) {
      final name = _docUpload.fileName ?? _documentName ?? 'Document';
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file_outlined, size: 15, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.figtree(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _removeDocument,
              child: const Icon(Icons.close, size: 14, color: AppColors.primary),
            ),
          ],
        ),
      );
    }

    if (phase == _UploadPhase.uploading) {
      final pct = (_docUpload.progress * 100).round();
      return Column(
        children: [
          Row(
            children: [
              const Icon(Icons.insert_drive_file_outlined, size: 15, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _docUpload.fileName ?? 'Uploading…',
                      style: GoogleFonts.figtree(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBody,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Uploading $pct%',
                      style: GoogleFonts.figtree(fontSize: 11.5, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: AppColors.grey),
                onPressed: () {
                  _docUpload.task?.cancel();
                  if (!mounted) return;
                  setState(() {
                    _docUpload = const _UploadState();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _docUpload.progress,
              backgroundColor: AppColors.greyLight,
              color: AppColors.primary,
              minHeight: 4,
            ),
          ),
        ],
      );
    }

    // Idle — outlined pill button
    return GestureDetector(
      onTap: _pickAndUploadDocument,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.greyLight),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.attach_file, size: 15, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Attach worksheet (PDF/DOC, optional)',
                style: GoogleFonts.figtree(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBody,
                ),
              ),
            ),
            const Icon(Icons.add, size: 15, color: AppColors.grey),
          ],
        ),
      ),
    );
  }

  // ── Segmented control ─────────────────────────────────────────────────────

  Widget _segmentedControl() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _segment('Video', Icons.play_circle_outline, isVideo: true),
          _segment('Text', Icons.article_outlined, isVideo: false),
        ],
      ),
    );
  }

  Widget _segment(String label, IconData icon, {required bool isVideo}) {
    final active = _isVideo == isVideo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isVideo = isVideo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: active ? Colors.white : AppColors.grey),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.figtree(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final saveLabel = _saving
        ? 'Saving…'
        : (_hasInFlightUpload ? 'Uploading…' : 'Save lesson');

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sheet title
              Text(
                isEditing ? 'Edit lesson' : 'Add lesson',
                style: GoogleFonts.figtree(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBody,
                ),
              ),

              const SizedBox(height: 20),

              // Video | Text segmented control
              _segmentedControl(),

              const SizedBox(height: 20),

              // Lesson title
              _label('Lesson title'),
              const SizedBox(height: 8),
              _pillField(controller: _titleCtrl, hint: 'e.g. Introduction to Fractions'),

              const SizedBox(height: 16),

              // Description
              _label('Description'),
              const SizedBox(height: 8),
              _pillField(controller: _descCtrl, hint: 'Short description of the lesson'),

              const SizedBox(height: 16),

              // Duration
              _label('Duration (minutes)'),
              const SizedBox(height: 8),
              _pillField(
                controller: _durationCtrl,
                hint: '15',
                keyboardType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              const SizedBox(height: 20),

              if (_isVideo) ...[
                // Video upload zone
                _label('Video'),
                const SizedBox(height: 8),
                _videoZone(),

                const SizedBox(height: 16),

                // Transcript
                _label('Transcript'),
                const SizedBox(height: 8),
                _boxField(
                  controller: _transcriptCtrl,
                  hint: 'Paste or type the lesson transcript…',
                  height: 84,
                  maxLines: 3,
                ),
              ] else ...[
                // Text content
                _label('Lesson content'),
                const SizedBox(height: 8),
                _boxField(
                  controller: _bodyCtrl,
                  hint: 'Write the lesson…',
                  height: 150,
                  maxLines: 6,
                ),
              ],

              const SizedBox(height: 20),

              // Attachment area
              _label('Worksheet (optional)'),
              const SizedBox(height: 8),
              _attachmentArea(),

              const SizedBox(height: 24),

              // Save button
              PillButton(
                label: saveLabel,
                enabled: _canSave,
                onPressed: _canSave ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
