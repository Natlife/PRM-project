import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/event_service.dart';

class StudentEventReviewScreen extends StatefulWidget {
  final int eventId;
  final int assignmentId;

  const StudentEventReviewScreen({
    super.key,
    required this.eventId,
    required this.assignmentId,
  });

  @override
  State<StudentEventReviewScreen> createState() =>
      _StudentEventReviewScreenState();
}

class _StudentEventReviewScreenState extends State<StudentEventReviewScreen> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);

  bool _isLoading = true;
  Map<String, dynamic> _detail = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final detail = await EventService().getStudentEventDetail(widget.eventId);

      if (!mounted) {
        return;
      }

      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải bản ghi sự kiện: $error'),
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: _borderColor,
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Quay lại',
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_rounded, color: _textPrimaryColor),
      ),
      titleSpacing: 0,
      title: const Text(
        'Xem lại sự kiện',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildEventOverview(Map<String, dynamic>? recording) {
    final String title = _detail['title']?.toString() ?? '';
    final String classroomCode = _detail['classroomCode']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.video_library_outlined,
                  color: _primaryDarkColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textPrimaryColor,
                        fontSize: 18,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (classroomCode.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            color: _textSecondaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              classroomCode,
                              style: const TextStyle(
                                color: _textSecondaryColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: _borderColor),
          const SizedBox(height: 18),
          if (recording != null)
            _buildRecordingButton(recording)
          else
            _buildMissingRecordingState(),
        ],
      ),
    );
  }

  Widget _buildRecordingButton(Map<String, dynamic> recording) {
    final String fileName =
        recording['originalFileName']?.toString() ?? 'Mở bản ghi';

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: () async {
          final String url = recording['fileUrl']?.toString() ?? '';

          if (url.isEmpty) {
            return;
          }

          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
        style: FilledButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.play_circle_outline_rounded, size: 21),
        label: Expanded(
          child: Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildMissingRecordingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.videocam_off_outlined, color: Color(0xFF8B9690), size: 22),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Giảng viên chưa tải bản ghi cho phiên này.',
              style: TextStyle(
                color: _textSecondaryColor,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return const Row(
      children: [
        _SectionIcon(),
        SizedBox(width: 11),
        Expanded(
          child: Text(
            'Câu hỏi đã đặt',
            style: TextStyle(
              color: _textPrimaryColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final String author = question['authorName']?.toString() ?? '';

    final String content = question['content']?.toString() ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: _primaryDarkColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  content,
                  style: const TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 13.5,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQuestions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.question_answer_outlined,
            color: Color(0xFF9AA49E),
            size: 32,
          ),
          SizedBox(height: 12),
          Text(
            'Không có câu hỏi nào được lưu',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> assignments =
        List<Map<String, dynamic>>.from(_detail['assignments'] ?? const []);

    final Map<String, dynamic> assignment =
        assignments.cast<Map<String, dynamic>?>().firstWhere(
          (Map<String, dynamic>? item) =>
              ((item?['id'] as num?)?.toInt() ?? 0) == widget.assignmentId,
          orElse: () =>
              Map<String, dynamic>.from(_detail['myAssignment'] ?? const {}),
        ) ??
        <String, dynamic>{};

    final List<Map<String, dynamic>> questions =
        List<Map<String, dynamic>>.from(assignment['questions'] ?? const []);

    final Map<String, dynamic>? recording =
        assignment['recording'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? _buildLoadingState()
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEventOverview(recording),
                          const SizedBox(height: 28),
                          _buildSectionTitle(),
                          const SizedBox(height: 14),
                          if (questions.isEmpty)
                            _buildEmptyQuestions()
                          else
                            ...questions.map(_buildQuestionCard),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.forum_outlined,
        color: Color(0xFF167A52),
        size: 18,
      ),
    );
  }
}
