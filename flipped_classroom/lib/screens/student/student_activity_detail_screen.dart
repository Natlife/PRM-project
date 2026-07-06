import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../services/activity_service.dart';
import '../../services/auth_service.dart';

class StudentActivityDetailScreen extends StatefulWidget {
  final Map<String, dynamic> activity;

  const StudentActivityDetailScreen({super.key, required this.activity});

  @override
  State<StudentActivityDetailScreen> createState() =>
      _StudentActivityDetailScreenState();
}

class _StudentActivityDetailScreenState
    extends State<StudentActivityDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _submissionTextController =
      TextEditingController();

  List<int>? _selectedFileBytes;
  String? _selectedFileName;
  String _submittedContent = '';

  bool _isLoading = true;
  int? _submissionId;
  bool _isResubmitting = false;
  String _title = '';
  String _type = '';
  String _deadline = '';
  String _description = '';
  String _status = 'Chưa làm';
  String _submissionStatus = 'NOT_SUBMITTED';
  String _activityWorkflowStatus = '';
  String? _submittedAt;
  String? _createdAt;
  String? _updatedAt;
  int _attachmentCount = 0;
  int _commentCount = 0;
  dynamic _score;
  dynamic _maxScore;
  String _teacherFeedback = '';
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _title = widget.activity['title']?.toString() ?? '';
    _type = widget.activity['type']?.toString() ?? '';
    _deadline = widget.activity['deadline']?.toString() ?? '';
    _description = widget.activity['description']?.toString() ?? '';
    _status = widget.activity['status']?.toString() ?? 'Chưa làm';
    _submissionStatus =
        widget.activity['submissionStatus']?.toString() ?? 'NOT_SUBMITTED';
    _score = widget.activity['score'];
    _maxScore = widget.activity['maxScore'];
    _teacherFeedback = widget.activity['teacherFeedback']?.toString() ?? '';
    _loadActivityDetail();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _submissionTextController.dispose();
    super.dispose();
  }

  String _formatDateTime(dynamic rawValue) {
    if (rawValue == null) {
      return '';
    }
    final raw = rawValue.toString();
    final parts = raw.split('T');
    if (parts.length != 2) {
      return raw;
    }
    final date = parts.first.split('-');
    final time = parts.last.split(':');
    if (date.length == 3 && time.length >= 2) {
      return '${date[2]}/${date[1]}/${date[0]} ${time[0]}:${time[1]}';
    }
    return raw;
  }

  Future<void> _loadActivityDetail() async {
    final activityId = (widget.activity['id'] as num?)?.toInt();
    if (activityId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final detail = await ActivityService().getStudentActivityDetail(
        activityId,
      );
      final submission = await ActivityService().getStudentSubmission(
        activityId,
      );
      List<Map<String, dynamic>> comments = [];
      final submissionId = (submission['id'] as num?)?.toInt();
      if (submissionId != null) {
        comments = await ActivityService().getSubmissionComments(submissionId);
      }

      if (!mounted) {
        return;
      }

      final submissionStatus =
          submission['status']?.toString() ?? 'NOT_SUBMITTED';
      final isDone =
          submissionStatus == 'SUBMITTED' ||
          submissionStatus == 'LATE_SUBMITTED' ||
          submissionStatus == 'GRADED';

      setState(() {
        _title = detail['title']?.toString() ?? _title;
        _description = detail['description']?.toString() ?? _description;
        _type =
            (detail['activityType'] == 'PRE_CLASS' ||
                detail['activityType'] == 'BEFORE_CLASS')
            ? 'Trước buổi học'
            : 'Trong buổi học';
        _deadline = 'Hạn: ${_formatDateTime(detail['dueAt']).split(' ').first}';
        _submissionId = submissionId;
        _submissionStatus = submissionStatus;
        _activityWorkflowStatus = detail['status']?.toString() ?? '';
        _submittedAt = submission['submittedAt']?.toString();
        _createdAt = detail['createdAt']?.toString();
        _updatedAt = detail['updatedAt']?.toString();
        _attachmentCount = submission['attachmentCount'] as int? ?? 0;
        _commentCount = submission['commentCount'] as int? ?? comments.length;
        _status = isDone ? 'Đã làm' : 'Chưa làm';
        _score = submission['score'];
        _maxScore = detail['maxScore'];
        _teacherFeedback = submission['teacherFeedback']?.toString() ?? '';
        _comments = comments;
        _submittedContent = submission['content']?.toString() ?? '';
        _submissionTextController.text = _submittedContent;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading student activity detail: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickSubmissionFile() async {
    try {
      final result = await FilePicker.pickFiles();
      if (result == null || result.files.isEmpty) {
        return;
      }
      final file = result.files.first;
      List<int>? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await io.File(file.path!).readAsBytes();
      }
      if (bytes == null) {
        throw Exception('Không thể đọc file');
      }
      setState(() {
        _selectedFileBytes = bytes;
        _selectedFileName = file.name;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chọn file: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _submitAssignment() async {
    final text = _submissionTextController.text.trim();
    final activityId = (widget.activity['id'] as num?)?.toInt();
    if (activityId == null) return;

    if (text.isEmpty && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung hoặc chọn tệp đính kèm.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Submit/update as draft
      await ActivityService().submitStudentActivity(
        activityId,
        content: text,
        fileBytes: _selectedFileBytes,
        fileName: _selectedFileName,
      );

      // 2. Finalize submission (sets status to SUBMITTED / LATE_SUBMITTED)
      await ActivityService().finalizeSubmission(activityId);

      setState(() {
        _selectedFileBytes = null;
        _selectedFileName = null;
        _isResubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nộp bài thành công!'),
            backgroundColor: Color(0xFF7EC07E),
          ),
        );
      }

      await _loadActivityDetail();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nộp bài thất bại: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _submissionId == null) {
      return;
    }

    try {
      final created = await ActivityService().addSubmissionComment(
        _submissionId!,
        content: text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _comments.add(created);
        _commentCount = _comments.length;
        _replyController.clear();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể gửi trao đổi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onBottomNavTapped(int index) {
    Navigator.pop(context, index);
  }

  @override
  Widget build(BuildContext context) {
    final submittedLabel = _submittedAt != null && _submittedAt!.isNotEmpty
        ? _formatDateTime(_submittedAt)
        : 'Chưa nộp bài';
    final createdLabel = _createdAt != null && _createdAt!.isNotEmpty
        ? _formatDateTime(_createdAt)
        : '';
    final updatedLabel = _updatedAt != null && _updatedAt!.isNotEmpty
        ? _formatDateTime(_updatedAt)
        : '';
    final scoreLabel = _score != null
        ? (_maxScore != null ? '$_score / $_maxScore' : _score.toString())
        : 'Chưa có điểm';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0F172A),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết hoạt động',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildTag(_type, const Color(0xFF7EC07E), true),
                              _buildTag(
                                _status,
                                _status == 'Đã làm'
                                    ? const Color(0xFF7EC07E)
                                    : Colors.redAccent,
                                false,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _deadline,
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF0F172A).withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Yêu cầu',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFF0F172A,
                                ).withOpacity(0.05),
                              ),
                            ),
                            child: Text(
                              _description.isEmpty
                                  ? 'Chưa có mô tả.'
                                  : _description,
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF0F172A).withOpacity(0.7),
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Thông tin bài nộp',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFF0F172A,
                                ).withOpacity(0.05),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trạng thái nộp bài: ${_translateStatus(_submissionStatus)}',
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Trạng thái hoạt động: ${_activityWorkflowStatus.isEmpty ? 'N/A' : _translateActivityStatus(_activityWorkflowStatus)}',
                                ),
                                const SizedBox(height: 6),
                                Text('Thời gian nộp: $submittedLabel'),
                                const SizedBox(height: 6),
                                Text(
                                  'Số lượng minh chứng đã nộp: $_attachmentCount',
                                ),
                                const SizedBox(height: 6),
                                Text('Số lượng trao đổi: $_commentCount'),
                                const SizedBox(height: 6),
                                Text('Điểm: $scoreLabel'),
                                if (createdLabel.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text('Tạo lúc: $createdLabel'),
                                ],
                                if (updatedLabel.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text('Cập nhật lúc: $updatedLabel'),
                                ],
                              ],
                            ),
                          ),
                          if (_teacherFeedback.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Nhận xét của giảng viên',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFF0F172A,
                                  ).withOpacity(0.05),
                                ),
                              ),
                              child: Text(
                                _teacherFeedback,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(
                                    0xFF0F172A,
                                  ).withOpacity(0.7),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          if (_submissionStatus == 'NOT_SUBMITTED' ||
                              _submissionStatus == 'DRAFT' ||
                              _isResubmitting) ...[
                            const Text(
                              'Nộp bài làm',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFF0F172A,
                                  ).withOpacity(0.05),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _submissionTextController,
                                    maxLines: 4,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF0F172A),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Nhập nội dung bài nộp...',
                                      hintStyle: TextStyle(
                                        color: const Color(
                                          0xFF0F172A,
                                        ).withValues(alpha: 0.3),
                                      ),
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _pickSubmissionFile,
                                        icon: const Icon(
                                          Icons.attach_file,
                                          size: 18,
                                        ),
                                        label: const Text('Chọn tệp đính kèm'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF7EC07E,
                                          ),
                                          foregroundColor: Colors.white,
                                          textStyle: const TextStyle(
                                            fontSize: 12,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedFileName ?? 'Chưa chọn file',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _submitAssignment,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7EC07E),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(44),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Nộp bài',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (_isResubmitting) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isResubmitting = false;
                                          _selectedFileBytes = null;
                                          _selectedFileName = null;
                                          _submissionTextController.text =
                                              _submittedContent;
                                        });
                                      },
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size.fromHeight(44),
                                      ),
                                      child: const Text(
                                        'Hủy',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'Bài làm đã nộp',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFF0F172A,
                                  ).withOpacity(0.05),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_submittedContent.isNotEmpty) ...[
                                    Text(
                                      _submittedContent,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const SizedBox(height: 6),
                                  ],
                                  Text(
                                    'Số lượng minh chứng: $_attachmentCount',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  if ((_submissionStatus == 'SUBMITTED' ||
                                          _submissionStatus ==
                                              'LATE_SUBMITTED') &&
                                      _activityWorkflowStatus != 'CLOSED') ...[
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isResubmitting = true;
                                          _submissionTextController.text =
                                              _submittedContent;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF7EC07E,
                                        ),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(44),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Nộp lại bài làm',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          const Text(
                            'Trao đổi với giảng viên',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_comments.isEmpty)
                            const Text(
                              'Chưa có trao đổi nào.',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ..._comments.map((comment) {
                              final author =
                                  comment['authorName']?.toString() ??
                                  'Người dùng';
                              final content =
                                  comment['content']?.toString() ?? '';
                              final time = _formatDateTime(
                                comment['createdAt'],
                              );
                              final currentUserDbId =
                                  AuthService().currentUser?.dbId;
                              final authorId = (comment['authorId'] as num?)
                                  ?.toInt();
                              final isMe =
                                  currentUserDbId != null &&
                                  authorId == currentUserDbId;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF0F172A,
                                          ).withOpacity(0.1),
                                        ),
                                      ),
                                      child: Text(
                                        content,
                                        style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        '$author • $time',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          const SizedBox(height: 12),
                          if (_submissionId != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF0F172A,
                                  ).withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _replyController,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 13,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Nhập câu trả lời',
                                        hintStyle: TextStyle(
                                          color: const Color(
                                            0xFF0F172A,
                                          ).withValues(alpha: 0.3),
                                        ),
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: (_) => _sendReply(),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.send,
                                      color: Color(0xFF7EC07E),
                                      size: 20,
                                    ),
                                    onPressed: _sendReply,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: const Color(0xFF7EC07E),
        unselectedItemColor: const Color(0xFF0F172A).withOpacity(0.4),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            label: 'Lớp học',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_work_outlined),
            label: 'Dự án',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color, bool filledGreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(filledGreen ? 0.12 : 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'DRAFT':
        return 'Bản nháp';
      case 'SUBMITTED':
        return 'Đã nộp';
      case 'LATE_SUBMITTED':
        return 'Nộp muộn';
      case 'GRADED':
        return 'Đã chấm';
      case 'NOT_SUBMITTED':
        return 'Chưa nộp';
      default:
        return status;
    }
  }

  String _translateActivityStatus(String status) {
    switch (status) {
      case 'DRAFT':
        return 'Nháp';
      case 'PUBLISHED':
        return 'Đang mở';
      case 'CLOSED':
        return 'Đã đóng';
      default:
        return status;
    }
  }
}
