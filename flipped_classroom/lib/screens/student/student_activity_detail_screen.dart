import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);
  static const Color _warningColor = Color(0xFFF59E0B);

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

    final String raw = rawValue.toString();
    final List<String> parts = raw.split('T');

    if (parts.length != 2) {
      return raw;
    }

    final List<String> date = parts.first.split('-');
    final List<String> time = parts.last.split(':');

    if (date.length == 3 && time.length >= 2) {
      return '${date[2]}/${date[1]}/${date[0]} '
          '${time[0]}:${time[1]}';
    }

    return raw;
  }

  Future<void> _loadActivityDetail() async {
    final int? activityId = (widget.activity['id'] as num?)?.toInt();

    if (activityId == null) {
      setState(() {
        _isLoading = false;
      });
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

      final int? submissionId = (submission['id'] as num?)?.toInt();

      if (submissionId != null) {
        comments = await ActivityService().getSubmissionComments(submissionId);
      }

      if (!mounted) {
        return;
      }

      final String submissionStatus =
          submission['status']?.toString() ?? 'NOT_SUBMITTED';

      final bool isDone =
          submissionStatus == 'SUBMITTED' ||
          submissionStatus == 'LATE_SUBMITTED' ||
          submissionStatus == 'GRADED';

      setState(() {
        _title = detail['title']?.toString() ?? _title;
        _description = detail['description']?.toString() ?? _description;

        _type =
            detail['activityType'] == 'PRE_CLASS' ||
                detail['activityType'] == 'BEFORE_CLASS'
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
    } catch (error) {
      debugPrint('Error loading student activity detail: $error');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickSubmissionFile() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles();

      if (result == null || result.files.isEmpty) {
        return;
      }

      final PlatformFile file = result.files.first;

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
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chọn file: $error'),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitAssignment() async {
    final String text = _submissionTextController.text.trim();
    final int? activityId = (widget.activity['id'] as num?)?.toInt();

    if (activityId == null) {
      return;
    }

    if (text.isEmpty && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung hoặc chọn tệp đính kèm.'),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ActivityService().submitStudentActivity(
        activityId,
        content: text,
        fileBytes: _selectedFileBytes,
        fileName: _selectedFileName,
      );

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
            backgroundColor: _primaryDarkColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await _loadActivityDetail();
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nộp bài thất bại: $error'),
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendReply() async {
    final String text = _replyController.text.trim();

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
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể gửi trao đổi: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onBottomNavTapped(int index) {
    Navigator.pop(context, index);
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

  Widget _buildActivityHeader() {
    final bool isDone = _status == 'Đã làm';

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
          Text(
            _title,
            style: const TextStyle(
              color: _textPrimaryColor,
              fontSize: 20,
              height: 1.35,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(
                label: _type,
                icon: Icons.layers_outlined,
                color: _primaryColor,
              ),
              _buildTag(
                label: _status,
                icon: isDone
                    ? Icons.check_circle_outline_rounded
                    : Icons.pending_outlined,
                color: isDone ? _primaryColor : _errorColor,
              ),
            ],
          ),
          if (_deadline.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: _textSecondaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _deadline,
                    style: const TextStyle(
                      color: _textSecondaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title, IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
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
        ],
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

  Widget _buildContentCard({
    required Widget child,
    Color color = _surfaceColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: child,
    );
  }

  Widget _buildRequirementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Yêu cầu hoạt động',
          icon: Icons.description_outlined,
        ),
        const SizedBox(height: 12),
        _buildContentCard(
          child: Text(
            _description.isEmpty ? 'Chưa có mô tả.' : _description,
            style: const TextStyle(
              color: _textSecondaryColor,
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionInformation({
    required String submittedLabel,
    required String createdLabel,
    required String updatedLabel,
    required String scoreLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Thông tin bài nộp',
          icon: Icons.assignment_turned_in_outlined,
        ),
        const SizedBox(height: 12),
        _buildContentCard(
          child: Column(
            children: [
              _buildInformationRow(
                icon: Icons.task_alt_rounded,
                label: 'Trạng thái nộp bài',
                value: _translateStatus(_submissionStatus),
              ),
              _buildDivider(),
              _buildInformationRow(
                icon: Icons.flag_outlined,
                label: 'Trạng thái hoạt động',
                value: _activityWorkflowStatus.isEmpty
                    ? 'N/A'
                    : _translateActivityStatus(_activityWorkflowStatus),
              ),
              _buildDivider(),
              _buildInformationRow(
                icon: Icons.schedule_outlined,
                label: 'Thời gian nộp',
                value: submittedLabel,
              ),
              _buildDivider(),
              _buildInformationRow(
                icon: Icons.attach_file_rounded,
                label: 'Minh chứng đã nộp',
                value: _attachmentCount.toString(),
              ),
              _buildDivider(),
              _buildInformationRow(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Số lượng trao đổi',
                value: _commentCount.toString(),
              ),
              _buildDivider(),
              _buildInformationRow(
                icon: Icons.star_outline_rounded,
                label: 'Điểm',
                value: scoreLabel,
              ),
              if (createdLabel.isNotEmpty) ...[
                _buildDivider(),
                _buildInformationRow(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Tạo lúc',
                  value: createdLabel,
                ),
              ],
              if (updatedLabel.isNotEmpty) ...[
                _buildDivider(),
                _buildInformationRow(
                  icon: Icons.update_rounded,
                  label: 'Cập nhật lúc',
                  value: updatedLabel,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInformationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F6F3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: _textSecondaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 13),
      child: Divider(height: 1, color: _borderColor),
    );
  }

  Widget _buildTeacherFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Nhận xét của giảng viên',
          icon: Icons.rate_review_outlined,
        ),
        const SizedBox(height: 12),
        _buildContentCard(
          color: const Color(0xFFFFFBEB),
          child: Text(
            _teacherFeedback,
            style: const TextStyle(
              color: _textSecondaryColor,
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Nộp bài làm',
          icon: Icons.upload_file_outlined,
        ),
        const SizedBox(height: 12),
        _buildContentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _submissionTextController,
                maxLines: 5,
                minLines: 4,
                style: const TextStyle(
                  color: _textPrimaryColor,
                  fontSize: 13.5,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập nội dung bài nộp...',
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
                    borderSide: const BorderSide(
                      color: _primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _pickSubmissionFile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryDarkColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  side: const BorderSide(color: _borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.centerLeft,
                ),
                icon: const Icon(Icons.attach_file_rounded, size: 19),
                label: const Text(
                  'Chọn tệp đính kèm',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    _selectedFileName == null
                        ? Icons.insert_drive_file_outlined
                        : Icons.check_circle_outline_rounded,
                    color: _selectedFileName == null
                        ? const Color(0xFF9AA49E)
                        : _primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedFileName ?? 'Chưa chọn tệp',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _selectedFileName == null
                            ? const Color(0xFF8B9690)
                            : _textPrimaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _submitAssignment,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 19),
                  label: const Text(
                    'Nộp bài',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (_isResubmitting) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 46,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isResubmitting = false;
                        _selectedFileBytes = null;
                        _selectedFileName = null;
                        _submissionTextController.text = _submittedContent;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: _errorColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmittedAssignment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Bài làm đã nộp',
          icon: Icons.task_alt_rounded,
        ),
        const SizedBox(height: 12),
        _buildContentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_submittedContent.isNotEmpty) ...[
                Text(
                  _submittedContent,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 13.5,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: _borderColor),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.attach_file_rounded,
                      color: _primaryDarkColor,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Số lượng minh chứng: $_attachmentCount',
                      style: const TextStyle(
                        color: _textPrimaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if ((_submissionStatus == 'SUBMITTED' ||
                      _submissionStatus == 'LATE_SUBMITTED') &&
                  _activityWorkflowStatus != 'CLOSED') ...[
                const SizedBox(height: 18),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _isResubmitting = true;
                        _submissionTextController.text = _submittedContent;
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 19),
                    label: const Text(
                      'Nộp lại bài làm',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Trao đổi với giảng viên',
          icon: Icons.forum_outlined,
        ),
        const SizedBox(height: 14),
        if (_comments.isEmpty)
          _buildContentCard(
            child: const Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF9AA49E),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chưa có trao đổi nào.',
                    style: TextStyle(color: _textSecondaryColor, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ..._comments.map(_buildComment),
        if (_submissionId != null) ...[
          const SizedBox(height: 12),
          _buildReplyInput(),
        ],
      ],
    );
  }

  Widget _buildComment(Map<String, dynamic> comment) {
    final String author = comment['authorName']?.toString() ?? 'Người dùng';

    final String content = comment['content']?.toString() ?? '';

    final String time = _formatDateTime(comment['createdAt']);

    final int? currentUserDbId = AuthService().currentUser?.dbId;

    final int? authorId = (comment['authorId'] as num?)?.toInt();

    final bool isMe = currentUserDbId != null && authorId == currentUserDbId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFEAF7F0) : _surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: Border.all(
                  color: isMe ? _primaryColor.withOpacity(0.18) : _borderColor,
                ),
              ),
              child: Text(
                content,
                style: const TextStyle(
                  color: _textPrimaryColor,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '$author • $time',
                style: const TextStyle(
                  color: Color(0xFF8B9690),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 5, 6, 5),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                _sendReply();
              },
              style: const TextStyle(color: _textPrimaryColor, fontSize: 13.5),
              decoration: const InputDecoration(
                hintText: 'Nhập câu trả lời...',
                hintStyle: TextStyle(color: Color(0xFF9AA49E), fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton.filled(
            tooltip: 'Gửi',
            onPressed: _sendReply,
            style: IconButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send_rounded, size: 19),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _surfaceColor,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: BottomNavigationBar(
        currentIndex: 1,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: _surfaceColor,
        elevation: 0,
        selectedItemColor: _primaryDarkColor,
        unselectedItemColor: const Color(0xFF8B9690),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school_rounded),
            label: 'Lớp học',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_work_outlined),
            activeIcon: Icon(Icons.group_work_rounded),
            label: 'Dự án',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications_rounded),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  Widget _buildTag({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final String submittedLabel =
        _submittedAt != null && _submittedAt!.isNotEmpty
        ? _formatDateTime(_submittedAt)
        : 'Chưa nộp bài';

    final String createdLabel = _createdAt != null && _createdAt!.isNotEmpty
        ? _formatDateTime(_createdAt)
        : '';

    final String updatedLabel = _updatedAt != null && _updatedAt!.isNotEmpty
        ? _formatDateTime(_updatedAt)
        : '';

    final String scoreLabel = _score != null
        ? _maxScore != null
              ? '$_score / $_maxScore'
              : _score.toString()
        : 'Chưa có điểm';

    final bool showSubmissionForm =
        _submissionStatus == 'NOT_SUBMITTED' ||
        _submissionStatus == 'DRAFT' ||
        _isResubmitting;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                  ),
                ),
              )
            : SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildActivityHeader(),
                        const SizedBox(height: 28),
                        _buildRequirementSection(),
                        const SizedBox(height: 28),
                        _buildSubmissionInformation(
                          submittedLabel: submittedLabel,
                          createdLabel: createdLabel,
                          updatedLabel: updatedLabel,
                          scoreLabel: scoreLabel,
                        ),
                        if (_teacherFeedback.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          _buildTeacherFeedbackSection(),
                        ],
                        const SizedBox(height: 28),
                        if (showSubmissionForm)
                          _buildSubmissionForm()
                        else
                          _buildSubmittedAssignment(),
                        const SizedBox(height: 30),
                        _buildCommentsSection(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
