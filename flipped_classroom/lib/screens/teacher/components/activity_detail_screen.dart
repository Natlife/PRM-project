import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/activity_service.dart';
import '../edit_activity_screen.dart';
import '../submission_detail_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final int? activityId;
  final String activityTitle;
  final String deadline;
  final String submissions;
  final String description;
  final String? className;

  const ActivityDetailScreen({
    super.key,
    this.activityId,
    required this.activityTitle,
    required this.deadline,
    required this.submissions,
    this.description = '',
    this.className,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);
  static const Color _warningColor = Color(0xFFF59E0B);

  late String _activityTitle;
  late String _deadline;
  late String _description;
  late String _status;

  bool _isLoading = true;
  bool _isSavingGrade = false;

  List<Map<String, dynamic>> _submissionsList = [];

  @override
  void initState() {
    super.initState();

    _activityTitle = widget.activityTitle;
    _deadline = widget.deadline;
    _description = widget.description;
    _status = '';

    _loadActivity();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PUBLISHED':
        return _primaryColor;
      case 'CLOSED':
        return _errorColor;
      default:
        return _warningColor;
    }
  }

  String _formatDate(dynamic rawValue) {
    if (rawValue == null) {
      return '';
    }

    final String raw = rawValue.toString().split('T').first;

    final List<String> parts = raw.split('-');

    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }

    return raw;
  }

  Future<void> _changeStatus(String newStatus) async {
    if (widget.activityId == null) {
      return;
    }

    try {
      final Map<String, dynamic> updated = await ActivityService()
          .updateActivity(widget.activityId!, {'status': newStatus});

      if (!mounted) {
        return;
      }

      setState(() {
        _status = updated['status']?.toString() ?? newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã đổi trạng thái hoạt động sang $_status.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _primaryDarkColor,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể đổi trạng thái hoạt động: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  Future<void> _loadActivity() async {
    if (widget.activityId == null) {
      setState(() {
        _isLoading = false;
      });

      return;
    }

    try {
      final Map<String, dynamic> detail = await ActivityService()
          .getTeacherActivityDetail(widget.activityId!);

      final List<dynamic> submissions = await ActivityService()
          .getActivitySubmissions(widget.activityId!);

      if (!mounted) {
        return;
      }

      setState(() {
        _activityTitle = detail['title']?.toString() ?? _activityTitle;

        _description = detail['description']?.toString() ?? _description;

        _deadline = _formatDate(detail['dueAt']);

        _status = detail['status']?.toString() ?? '';

        _submissionsList = submissions.map<Map<String, dynamic>>((
          dynamic submission,
        ) {
          final String status = submission['status']?.toString() ?? '';

          final bool isSubmitted =
              status != 'NOT_SUBMITTED' && status.isNotEmpty;

          return {
            'id': submission['id'],
            'name': submission['studentName'] ?? 'Sinh viên',
            'code': 'ID: ${submission['studentId'] ?? ''}',
            'submitted': isSubmitted,
            'time': _formatDate(submission['submittedAt']),
            'score': submission['score'],
            'status': status,
            'feedback': submission['teacherFeedback'],
          };
        }).toList();

        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading activity detail: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showGradeDialog(int index) async {
    final Map<String, dynamic> submission = _submissionsList[index];

    final TextEditingController scoreController = TextEditingController(
      text: submission['score']?.toString() ?? '',
    );

    final TextEditingController feedbackController = TextEditingController(
      text: submission['feedback']?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext dialogContext, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: _surfaceColor,
              surfaceTintColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
              contentPadding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
              actionsPadding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
              title: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.grade_outlined,
                      color: _primaryDarkColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      'Chấm điểm: ${submission['name']}',
                      style: const TextStyle(
                        color: _textPrimaryColor,
                        fontSize: 18,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Điểm số',
                    style: TextStyle(
                      color: _textPrimaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: scoreController,
                    enabled: !_isSavingGrade,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    style: const TextStyle(
                      color: _textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _buildInputDecoration(
                      hintText: 'Nhập điểm từ 0 đến 10',
                      prefixIcon: Icons.score_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nhận xét',
                    style: TextStyle(
                      color: _textPrimaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: feedbackController,
                    enabled: !_isSavingGrade,
                    maxLines: 3,
                    minLines: 3,
                    style: const TextStyle(
                      color: _textPrimaryColor,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                    decoration: _buildInputDecoration(
                      hintText: 'Nhận xét không bắt buộc',
                      prefixIcon: Icons.comment_outlined,
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSavingGrade
                            ? null
                            : () {
                                Navigator.of(dialogContext).pop();
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
                        onPressed: _isSavingGrade
                            ? null
                            : () async {
                                final String scoreText = scoreController.text
                                    .trim();

                                final RegExp scoreRegExp = RegExp(
                                  r'^\d+(\.\d+)?$',
                                );

                                if (!scoreRegExp.hasMatch(scoreText)) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vui lòng nhập điểm '
                                        'hợp lệ '
                                        '(chỉ nhận số).',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );

                                  return;
                                }

                                final double? score = double.tryParse(
                                  scoreText,
                                );

                                if (score == null || score < 0 || score > 10) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Điểm phải là số '
                                        'từ 0 đến 10.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );

                                  return;
                                }

                                setState(() {
                                  _isSavingGrade = true;
                                });

                                setDialogState(() {});

                                try {
                                  final Map<String, dynamic> updated =
                                      await ActivityService().gradeSubmission(
                                        submission['id'] as int,
                                        score: score,
                                        feedback:
                                            feedbackController.text
                                                .trim()
                                                .isEmpty
                                            ? null
                                            : feedbackController.text.trim(),
                                      );

                                  if (!mounted) {
                                    return;
                                  }

                                  setState(() {
                                    _submissionsList[index]['score'] =
                                        updated['score'] ?? score;

                                    _submissionsList[index]['status'] =
                                        updated['status'] ?? 'GRADED';

                                    _submissionsList[index]['feedback'] =
                                        updated['teacherFeedback'] ??
                                        feedbackController.text.trim();
                                  });

                                  Navigator.of(dialogContext).pop();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Đã cập nhật điểm '
                                        'thành công.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: _primaryDarkColor,
                                    ),
                                  );
                                } catch (error) {
                                  if (!mounted) {
                                    return;
                                  }

                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Không thể chấm '
                                        'điểm: $error',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: _errorColor,
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isSavingGrade = false;
                                    });
                                  }
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _primaryColor.withOpacity(
                            0.65,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSavingGrade
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Lưu',
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
      },
    );

    scoreController.dispose();
    feedbackController.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9AA49E),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(prefixIcon, color: _textSecondaryColor, size: 20),
      filled: true,
      fillColor: const Color(0xFFF9FBFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _borderColor),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
    );
  }

  Future<void> _editActivity() async {
    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute<Map<String, dynamic>>(
            builder: (BuildContext context) {
              return EditActivityScreen(
                activityTitle: _activityTitle,
                description: _description,
                deadline: _deadline,
                currentStatus: _status,
              );
            },
          ),
        );

    if (result == null || widget.activityId == null) {
      return;
    }

    try {
      final List<String> deadlineParts = (result['deadline'] as String).split(
        '/',
      );

      final String? dueAt = deadlineParts.length == 3
          ? '${deadlineParts[2]}-'
                '${deadlineParts[1]}-'
                '${deadlineParts[0]}T23:59:59'
          : null;

      final Map<String, dynamic> updated = await ActivityService()
          .updateActivity(widget.activityId!, {
            'title': result['title'],
            'description': result['description'],
            'dueAt': dueAt,
            'status': result['status'],
          });

      if (!mounted) {
        return;
      }

      setState(() {
        _activityTitle =
            updated['title']?.toString() ?? result['title'] as String;

        _description =
            updated['description']?.toString() ??
            result['description'] as String;

        _deadline = _formatDate(updated['dueAt']);

        _status = updated['status']?.toString() ?? _status;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật hoạt động thành công.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _primaryDarkColor,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật hoạt động: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  void _closeScreen() {
    Navigator.of(context).pop({
      'title': _activityTitle,
      'deadline': _deadline,
      'description': _description,
    });
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
        onPressed: _closeScreen,
        icon: const Icon(Icons.arrow_back_rounded, color: _textPrimaryColor),
      ),
      titleSpacing: 0,
      title: const Text(
        'Chi tiết hoạt động',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildActivityOverview() {
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
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
                      _activityTitle,
                      style: const TextStyle(
                        color: _textPrimaryColor,
                        fontSize: 20,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.35,
                      ),
                    ),
                    if (widget.className != null &&
                        widget.className!.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            color: _primaryDarkColor,
                            size: 16,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Lớp nhận hoạt động: '
                              '${widget.className}',
                              style: const TextStyle(
                                color: _primaryDarkColor,
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _editActivity,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryDarkColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  side: const BorderSide(color: _primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text(
                  'Chỉnh sửa',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: _borderColor),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: _buildOverviewInformation(
                  icon: Icons.schedule_rounded,
                  label: 'Hạn nộp',
                  value: _deadline,
                ),
              ),
              if (_status.isNotEmpty) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(_status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    _status,
                    style: TextStyle(
                      color: _statusColor(_status),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewInformation({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _textSecondaryColor, size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _textSecondaryColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: _textPrimaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusActions() {
    if (_status.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            title: 'Quản lý trạng thái',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              if (_status != 'PUBLISHED')
                _buildStatusButton(
                  label: 'Publish',
                  icon: Icons.public_rounded,
                  onPressed: () {
                    _changeStatus('PUBLISHED');
                  },
                ),
              if (_status != 'DRAFT')
                _buildStatusButton(
                  label: 'Về nháp',
                  icon: Icons.edit_note_rounded,
                  onPressed: () {
                    _changeStatus('DRAFT');
                  },
                ),
              if (_status != 'CLOSED')
                _buildStatusButton(
                  label: 'Đóng hoạt động',
                  icon: Icons.lock_outline_rounded,
                  onPressed: () {
                    _changeStatus('CLOSED');
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _textPrimaryColor,
        backgroundColor: const Color(0xFFF9FBFA),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        side: const BorderSide(color: _borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      icon: Icon(icon, color: _primaryDarkColor, size: 17),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            title: 'Mô tả hoạt động',
            icon: Icons.notes_rounded,
          ),
          const SizedBox(height: 14),
          Text(
            _description.isEmpty
                ? 'Chưa có mô tả cho hoạt động này.'
                : _description,
            style: const TextStyle(
              color: _textSecondaryColor,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection({
    required int totalStudents,
    required int submittedStudents,
    required int percentage,
  }) {
    final double progress = totalStudents > 0
        ? submittedStudents / totalStudents
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSectionTitle(
                  title: 'Tiến độ nộp bài',
                  icon: Icons.insights_outlined,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$submittedStudents/$totalStudents',
                  style: const TextStyle(
                    color: _primaryDarkColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF0F3F1),
              valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$percentage% sinh viên đã nộp bài',
            style: const TextStyle(
              color: _textSecondaryColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
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
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Danh sách bài nộp',
          icon: Icons.assignment_turned_in_outlined,
        ),
        const SizedBox(height: 14),
        if (_submissionsList.isEmpty)
          _buildEmptySubmissionsState()
        else
          ...List<Widget>.generate(_submissionsList.length, (int index) {
            return _buildSubmissionCard(index);
          }),
      ],
    );
  }

  Widget _buildEmptySubmissionsState() {
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
          Icon(Icons.assignment_outlined, color: Color(0xFF9AA49E), size: 32),
          SizedBox(height: 11),
          Text(
            'Chưa có bài nộp nào.',
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

  Widget _buildSubmissionCard(int index) {
    final Map<String, dynamic> submission = _submissionsList[index];

    final bool isSubmitted = submission['submitted'] as bool;

    final bool hasScore = submission['score'] != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withOpacity(0.025),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () {
            if (!isSubmitted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sinh viên chưa nộp bài.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );

              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) {
                  return SubmissionDetailScreen(
                    submissionId: submission['id'] as int?,
                    studentName: submission['name']?.toString() ?? '',
                    submittedTime: submission['time']?.toString() ?? '',
                  );
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSubmitted
                        ? const Color(0xFFEAF7F0)
                        : const Color(0xFFF1F4F2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isSubmitted
                        ? Icons.check_circle_outline_rounded
                        : Icons.pending_outlined,
                    color: isSubmitted
                        ? _primaryDarkColor
                        : _textSecondaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        submission['name']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrimaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        isSubmitted
                            ? 'Nộp lúc: '
                                  '${submission['time']}'
                            : 'Chưa nộp bài',
                        style: TextStyle(
                          color: isSubmitted
                              ? _textSecondaryColor
                              : _errorColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSubmitted) ...[
                  if (hasScore) ...[
                    Container(
                      constraints: const BoxConstraints(minWidth: 40),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${submission['score']}',
                        style: const TextStyle(
                          color: _primaryDarkColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton(
                    onPressed: () {
                      _showGradeDialog(index);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      hasScore ? 'Sửa' : 'Chấm',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ] else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFB0B8B3),
                    size: 21,
                  ),
              ],
            ),
          ),
        ),
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
    final int totalStudents = _submissionsList.length;

    final int submittedStudents = _submissionsList
        .where(
          (Map<String, dynamic> submission) => submission['submitted'] == true,
        )
        .length;

    final int percentage = totalStudents > 0
        ? (submittedStudents / totalStudents * 100).round()
        : 0;

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
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildActivityOverview(),
                          const SizedBox(height: 14),
                          _buildStatusActions(),
                          if (_status.isNotEmpty) const SizedBox(height: 14),
                          _buildDescriptionSection(),
                          const SizedBox(height: 14),
                          _buildProgressSection(
                            totalStudents: totalStudents,
                            submittedStudents: submittedStudents,
                            percentage: percentage,
                          ),
                          const SizedBox(height: 28),
                          _buildSubmissionsSection(),
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
