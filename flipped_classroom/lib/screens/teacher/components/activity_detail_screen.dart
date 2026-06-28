import 'package:flutter/material.dart';

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

  String _formatDate(dynamic rawValue) {
    if (rawValue == null) {
      return '';
    }
    final raw = rawValue.toString().split('T').first;
    final parts = raw.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return raw;
  }

  Future<void> _loadActivity() async {
    if (widget.activityId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final detail = await ActivityService().getTeacherActivityDetail(widget.activityId!);
      final submissions = await ActivityService().getActivitySubmissions(widget.activityId!);

      if (!mounted) {
        return;
      }

      setState(() {
        _activityTitle = detail['title']?.toString() ?? _activityTitle;
        _description = detail['description']?.toString() ?? _description;
        _deadline = _formatDate(detail['dueAt']);
        _status = detail['status']?.toString() ?? '';
        _submissionsList = submissions.map<Map<String, dynamic>>((submission) {
          final status = submission['status']?.toString() ?? '';
          final isSubmitted = status != 'NOT_SUBMITTED' && status.isNotEmpty;
          return {
            'id': submission['id'],
            'name': submission['studentName'] ?? 'Sinh vien',
            'code': 'ID: ${submission['studentId'] ?? ''}',
            'submitted': isSubmitted,
            'time': _formatDate(submission['submittedAt']),
            'score': submission['score'],
            'status': status,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading activity detail: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showGradeDialog(int index) async {
    final submission = _submissionsList[index];
    final scoreController = TextEditingController(
      text: submission['score']?.toString() ?? '',
    );
    final feedbackController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFFFFF),
              title: Text(
                'Cham diem: ${submission['name']}',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: scoreController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Nhap diem',
                      hintStyle: TextStyle(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                      ),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    style: const TextStyle(color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Nhan xet (khong bat buoc)',
                      hintStyle: TextStyle(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                      ),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isSavingGrade ? null : () => Navigator.of(context).pop(),
                  child: const Text('Huy', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: _isSavingGrade
                      ? null
                      : () async {
                          final score = double.tryParse(scoreController.text.trim());
                          if (score == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui long nhap diem hop le.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          setState(() => _isSavingGrade = true);
                          setDialogState(() {});
                          try {
                            final updated = await ActivityService().gradeSubmission(
                              submission['id'] as int,
                              score: score,
                              feedback: feedbackController.text.trim().isEmpty
                                  ? null
                                  : feedbackController.text.trim(),
                            );
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _submissionsList[index]['score'] = updated['score'] ?? score;
                              _submissionsList[index]['status'] = updated['status'] ?? 'GRADED';
                            });
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Da cap nhat diem thanh cong.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Khong the cham diem: $e'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isSavingGrade = false);
                            }
                          }
                        },
                  child: const Text('Luu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editActivity() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditActivityScreen(
          activityTitle: _activityTitle,
          description: _description,
          deadline: _deadline,
        ),
      ),
    );
    if (result == null || widget.activityId == null) {
      return;
    }

    try {
      final deadlineParts = (result['deadline'] as String).split('/');
      final dueAt = deadlineParts.length == 3
          ? '${deadlineParts[2]}-${deadlineParts[1]}-${deadlineParts[0]}T23:59:59'
          : null;
      final updated = await ActivityService().updateActivity(
        widget.activityId!,
        {
          'title': result['title'],
          'description': result['description'],
          'dueAt': dueAt,
        },
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _activityTitle = updated['title']?.toString() ?? result['title'] as String;
        _description = updated['description']?.toString() ?? result['description'] as String;
        _deadline = _formatDate(updated['dueAt']);
        _status = updated['status']?.toString() ?? _status;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Da cap nhat hoat dong thanh cong.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Khong the cap nhat hoat dong: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalStudents = _submissionsList.length;
    final submittedStudents =
        _submissionsList.where((submission) => submission['submitted'] == true).length;
    final percentage =
        totalStudents > 0 ? (submittedStudents / totalStudents * 100).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop({
                      'title': _activityTitle,
                      'deadline': _deadline,
                      'description': _description,
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7EC07E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF0F172A),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Chi tiet hoat dong',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
                    )
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _activityTitle,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (widget.className != null && widget.className!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.school,
                                          color: Color(0xFF7EC07E),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Lop nhan hoat dong: ${widget.className}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF7EC07E),
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
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: _editActivity,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7EC07E),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Chinh sua',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Han nop: $_deadline',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (_status.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Trang thai: $_status',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mo ta hoat dong',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _description.isEmpty
                                    ? 'Chua co mo ta cho hoat dong nay.'
                                    : _description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Tien do',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    '$submittedStudents/$totalStudents',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: totalStudents > 0 ? submittedStudents / totalStudents : 0,
                                  backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.08),
                                  color: const Color(0xFF7EC07E),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$percentage% sinh vien da nop bai',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Danh sach bai nop',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_submissionsList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'Chua co bai nop nao.',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            ),
                          )
                        else
                          ...List.generate(_submissionsList.length, (index) {
                            final submission = _submissionsList[index];
                            final isSubmitted = submission['submitted'] as bool;
                            final hasScore = submission['score'] != null;

                            return GestureDetector(
                              onTap: () {
                                if (!isSubmitted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Sinh vien chua nop bai.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SubmissionDetailScreen(
                                      submissionId: submission['id'] as int?,
                                      studentName: submission['name']?.toString() ?? '',
                                      submittedTime: submission['time']?.toString() ?? '',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFFFF),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isSubmitted
                                          ? const Color(0xFF7EC07E).withValues(alpha: 0.12)
                                          : const Color(0xFF0F172A).withValues(alpha: 0.06),
                                      radius: 18,
                                      child: Icon(
                                        isSubmitted
                                            ? Icons.check_circle_outline
                                            : Icons.pending_outlined,
                                        color: isSubmitted
                                            ? const Color(0xFF7EC07E)
                                            : const Color(0xFF64748B),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            submission['name']?.toString() ?? '',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isSubmitted
                                                ? 'Nop luc: ${submission['time']}'
                                                : 'Chua nop bai',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isSubmitted
                                                  ? const Color(0xFF64748B)
                                                  : Colors.redAccent.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSubmitted) ...[
                                      if (hasScore) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7EC07E).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${submission['score']}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF7EC07E),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      ElevatedButton(
                                        onPressed: () => _showGradeDialog(index),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF7EC07E),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          hasScore ? 'Sua' : 'Cham',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 30),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
