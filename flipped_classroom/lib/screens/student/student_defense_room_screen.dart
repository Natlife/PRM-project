import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/event_service.dart';

class StudentDefenseRoomScreen extends StatefulWidget {
  final int eventId;
  final int assignmentId;

  const StudentDefenseRoomScreen({
    super.key,
    required this.eventId,
    required this.assignmentId,
  });

  @override
  State<StudentDefenseRoomScreen> createState() =>
      _StudentDefenseRoomScreenState();
}

class _StudentDefenseRoomScreenState extends State<StudentDefenseRoomScreen> {
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
          content: Text('Lỗi tải phòng phản biện: $error'),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _askQuestion() async {
    final List<Map<String, dynamic>> bank = List<Map<String, dynamic>>.from(
      _detail['questionBank'] ?? const [],
    );

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

    final TextEditingController controller = TextEditingController(
      text: bank.isNotEmpty ? bank.first['content']?.toString() ?? '' : '',
    );

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: _primaryDarkColor,
              size: 27,
            ),
          ),
          title: const Text(
            'Đặt câu hỏi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            minLines: 4,
            autofocus: true,
            style: const TextStyle(
              color: _textPrimaryColor,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Nhập câu hỏi dành cho người thuyết trình',
              hintStyle: const TextStyle(
                color: Color(0xFF9AA49E),
                fontSize: 13,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FBFA),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: _primaryColor, width: 1.5),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSecondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: _borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, controller.text.trim());
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Gửi',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) {
      return;
    }

    try {
      await EventService().addStudentLiveQuestion(
        widget.eventId,
        result,
        assignmentId: (assignment['id'] as num?)?.toInt(),
      );

      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi câu hỏi: $error'),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
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
          Navigator.pop(context, true);
        },
        icon: const Icon(Icons.arrow_back_rounded, color: _textPrimaryColor),
      ),
      titleSpacing: 0,
      title: const Text(
        'Phòng phản biện',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildAssignmentOverview(Map<String, dynamic> assignment) {
    final String presenterName =
        assignment['presenterGroupName']?.toString().isNotEmpty == true
        ? assignment['presenterGroupName'].toString()
        : assignment['presenterStudentName']?.toString() ?? '';

    final String reviewerName =
        assignment['reviewerStudentName']?.toString() ?? '';

    final String role = _detail['myRole']?.toString() ?? '';

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
                  Icons.record_voice_over_outlined,
                  color: _primaryDarkColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Người thuyết trình',
                      style: TextStyle(
                        color: _textSecondaryColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      presenterName,
                      style: const TextStyle(
                        color: _textPrimaryColor,
                        fontSize: 18,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: _borderColor),
          const SizedBox(height: 18),
          _buildInformationRow(
            icon: Icons.person_search_outlined,
            label: 'Người phản biện',
            value: reviewerName,
          ),
          const SizedBox(height: 14),
          _buildInformationRow(
            icon: Icons.badge_outlined,
            label: 'Vai trò của bạn',
            value: role,
          ),
        ],
      ),
    );
  }

  Widget _buildInformationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F6F3),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _textSecondaryColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _textSecondaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: _textPrimaryColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F0),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _primaryDarkColor, size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
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

  Widget _buildEvidenceSection(List<Map<String, dynamic>> evidences) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Minh chứng đang xem',
          icon: Icons.folder_open_outlined,
        ),
        const SizedBox(height: 12),
        ...evidences.map(_buildEvidenceCard),
      ],
    );
  }

  Widget _buildEvidenceCard(Map<String, dynamic> evidence) {
    final String fileName = evidence['originalFileName']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(15, 13, 8, 13),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.insert_drive_file_outlined,
              color: _primaryDarkColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textPrimaryColor,
                fontSize: 13.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Mở minh chứng',
            style: IconButton.styleFrom(
              foregroundColor: _primaryDarkColor,
              backgroundColor: const Color(0xFFEAF7F0),
            ),
            onPressed: () async {
              final String url = evidence['fileUrl']?.toString() ?? '';

              if (url.isEmpty) {
                return;
              }

              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsHeader(Map<String, dynamic> assignment) {
    return Row(
      children: [
        Expanded(
          child: _buildSectionTitle(
            title: 'Câu hỏi live',
            icon: Icons.forum_outlined,
          ),
        ),
        if (_detail['status']?.toString() == 'LIVE' &&
            assignment['myRole']?.toString() == 'REVIEWER')
          FilledButton.icon(
            onPressed: _askQuestion,
            style: FilledButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Đặt câu hỏi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
      ],
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
            Icons.chat_bubble_outline_rounded,
            color: Color(0xFF9AA49E),
            size: 30,
          ),
          SizedBox(height: 12),
          Text(
            'Chưa có câu hỏi nào trong phiên này',
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
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: _primaryDarkColor,
              size: 19,
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

    final List<Map<String, dynamic>> evidences =
        List<Map<String, dynamic>>.from(assignment['evidences'] ?? const []);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _load,
              color: _primaryColor,
              backgroundColor: _surfaceColor,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAssignmentOverview(assignment),
                          if (evidences.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            _buildEvidenceSection(evidences),
                          ],
                          const SizedBox(height: 28),
                          _buildQuestionsHeader(assignment),
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
