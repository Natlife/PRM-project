import 'dart:convert';
import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/project_service.dart';

class StudentMilestoneDetailScreen extends StatefulWidget {
  final Map<String, dynamic> milestone;
  final Map<String, dynamic> project;

  const StudentMilestoneDetailScreen({
    super.key,
    required this.milestone,
    required this.project,
  });

  @override
  State<StudentMilestoneDetailScreen> createState() =>
      _StudentMilestoneDetailScreenState();
}

class _StudentMilestoneDetailScreenState
    extends State<StudentMilestoneDetailScreen> {
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

  bool _isLeader = false;

  late String _milestoneTitle;
  late String _dueDate;
  late String _status;
  late double _progress;

  late List<Map<String, dynamic>> _tasksList;
  late List<Map<String, dynamic>> _attachments;
  late List<Map<String, dynamic>> _commentsList;

  @override
  void initState() {
    super.initState();

    _milestoneTitle =
        widget.milestone['title']?.toString() ?? 'Chi tiết milestone';

    _dueDate = _buildDueDate(
      widget.milestone['dueAt'] ?? widget.milestone['dueDate'],
    );

    _status = _normalizeStatus(widget.milestone['status']);

    _progress = _normalizeProgress(
      widget.milestone['progressPercent'] ?? widget.milestone['progress'],
    );

    _tasksList = widget.milestone['tasks'] != null
        ? List<Map<String, dynamic>>.from(widget.milestone['tasks'])
        : <Map<String, dynamic>>[];

    _attachments = List<Map<String, dynamic>>.from(
      widget.milestone['attachments'] ?? const [],
    );

    _commentsList = widget.milestone['comments'] != null
        ? List<Map<String, dynamic>>.from(widget.milestone['comments'])
        : <Map<String, dynamic>>[];

    final currentUser = AuthService().currentUser;
    final Map<String, dynamic>? leader =
        widget.project['leader'] as Map<String, dynamic>?;

    final String? leaderId = leader?['id']?.toString();
    final String? leaderUsername = leader?['userName']?.toString();

    _isLeader =
        leaderId == currentUser?.id || leaderUsername == currentUser?.username;
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  String _buildDueDate(dynamic raw) {
    if (raw == null) {
      return 'Không có thời hạn';
    }

    final String value = raw.toString();

    if (value.contains('Hạn')) {
      return value;
    }

    try {
      final DateTime date = DateTime.parse(value);

      return 'Hạn: '
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  String _normalizeStatus(dynamic raw) {
    final String value = raw?.toString() ?? 'NOT_STARTED';

    if (value == 'COMPLETED' || value == 'Hoàn thành') {
      return 'Hoàn thành';
    }

    if (value == 'IN_PROGRESS' || value == 'Đang thực hiện') {
      return 'Đang thực hiện';
    }

    if (value == 'OVERDUE' || value == 'Quá hạn') {
      return 'Quá hạn';
    }

    return 'Chưa bắt đầu';
  }

  double _normalizeProgress(dynamic raw) {
    if (raw == null) {
      return 0;
    }

    if (raw is int) {
      return raw / 100.0;
    }

    final double value = (raw as num).toDouble();

    return value > 1 ? value / 100.0 : value;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
        return _primaryColor;
      case 'Đang thực hiện':
        return _warningColor;
      case 'Quá hạn':
        return _errorColor;
      default:
        return const Color(0xFF7A857F);
    }
  }

  Future<void> _updateProgressOnBackend(double newProgress) async {
    final int milestoneId = (widget.milestone['id'] as num?)?.toInt() ?? 0;

    if (milestoneId == 0) {
      return;
    }

    final int percent = (newProgress * 100).toInt();

    String backendStatus = 'NOT_STARTED';

    if (percent == 100) {
      backendStatus = 'COMPLETED';
    } else if (percent > 0) {
      backendStatus = 'IN_PROGRESS';
    }

    final String descriptionPayload = jsonEncode({
      'description': widget.milestone['description'] ?? '',
      'tasks': _tasksList,
      'comments': _commentsList,
    });

    try {
      await ProjectService().updateMilestoneProgress(
        milestoneId,
        percent,
        backendStatus,
        description: descriptionPayload,
      );
    } catch (error) {
      debugPrint('Failed to update milestone progress: $error');
    }
  }

  void _recalculateProgress() {
    if (_tasksList.isEmpty) {
      return;
    }

    final int completedCount = _tasksList
        .where((Map<String, dynamic> task) => task['isDone'] == true)
        .length;

    final double newProgress = completedCount / _tasksList.length;

    setState(() {
      _progress = newProgress;

      if (newProgress == 1) {
        _status = 'Hoàn thành';
      } else if (newProgress == 0) {
        _status = 'Chưa bắt đầu';
      } else {
        _status = 'Đang thực hiện';
      }
    });

    _updateProgressOnBackend(newProgress);
  }

  void _toggleTask(int index, bool? value) {
    if (!_isLeader) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chỉ trưởng nhóm mới có thể cập nhật '
            'công việc mốc thời gian.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );

      return;
    }

    setState(() {
      _tasksList[index]['isDone'] = value ?? false;
    });

    _recalculateProgress();
  }

  Future<void> _addEvidence() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles();

      if (result == null || result.files.isEmpty) {
        return;
      }

      final PlatformFile file = result.files.first;

      List<int>? bytes = file.bytes;
      final String fileName = file.name;

      if (bytes == null && file.path != null) {
        final io.File selectedFile = io.File(file.path!);
        bytes = await selectedFile.readAsBytes();
      }

      if (bytes == null) {
        throw Exception('Không thể đọc file');
      }

      final int milestoneId = (widget.milestone['id'] as num?)?.toInt() ?? 0;

      if (milestoneId == 0) {
        throw Exception('Mã mốc thời gian không hợp lệ');
      }

      bool showSpinner = false;

      if (mounted) {
        showSpinner = true;

        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            );
          },
        );
      }

      try {
        final List<Map<String, dynamic>> updatedList = await ProjectService()
            .uploadMilestoneAttachment(milestoneId, bytes, fileName);

        if (showSpinner && mounted) {
          Navigator.pop(context);
          showSpinner = false;
        }

        if (!mounted) {
          return;
        }

        setState(() {
          _attachments = updatedList;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải lên minh chứng thành công!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _primaryDarkColor,
          ),
        );
      } finally {
        if (showSpinner && mounted) {
          Navigator.pop(context);
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tải file thất bại: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  void _showDeleteConfirmation(int index) {
    if (!_isLeader) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ trưởng nhóm mới có thể xóa minh chứng.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );

      return;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFECEE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: _errorColor),
          ),
          title: const Text(
            'Xóa minh chứng?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimaryColor,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Minh chứng này sẽ chỉ bị xóa trên giao diện hiện tại.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                      side: const BorderSide(color: _borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _attachments.removeAt(index);
                      });

                      Navigator.pop(dialogContext);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _errorColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Xóa'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendReply() async {
    final String text = _replyController.text.trim();

    if (text.isEmpty) {
      return;
    }

    final int milestoneId = (widget.milestone['id'] as num?)?.toInt() ?? 0;

    if (milestoneId == 0) {
      return;
    }

    final currentUser = AuthService().currentUser;

    final String senderName =
        currentUser?.fullName ?? currentUser?.username ?? 'Học viên';

    final Map<String, dynamic> newComment = {
      'sender': senderName,
      'text': text,
    };

    setState(() {
      _commentsList.add(newComment);
      _replyController.clear();
    });

    final int percent = (_progress * 100).toInt();

    String backendStatus = 'NOT_STARTED';

    if (percent == 100) {
      backendStatus = 'COMPLETED';
    } else if (percent > 0) {
      backendStatus = 'IN_PROGRESS';
    }

    final String descriptionPayload = jsonEncode({
      'description': widget.milestone['description'] ?? '',
      'tasks': _tasksList,
      'comments': _commentsList,
    });

    try {
      await ProjectService().updateMilestoneProgress(
        milestoneId,
        percent,
        backendStatus,
        description: descriptionPayload,
      );
    } catch (error) {
      debugPrint('Failed to send comment: $error');
    }
  }

  void _onBottomNavTapped(int index) {
    Navigator.pop(context, index);
  }

  void _closeScreen() {
    Navigator.pop(context, {
      'status': _status,
      'progress': _progress,
      'tasks': _tasksList,
      'attachments': _attachments,
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
        'Chi tiết mốc thời gian',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4EDDF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: _primaryDarkColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isLeader
                  ? 'Bạn là trưởng nhóm và có thể cập nhật '
                        'tiến độ mốc thời gian.'
                  : 'Bạn là thành viên, chỉ xem tiến độ '
                        'và tài liệu đã nộp.',
              style: const TextStyle(
                color: _primaryDarkColor,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withOpacity(0.035),
            blurRadius: 22,
            offset: const Offset(0, 8),
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
                  Icons.flag_outlined,
                  color: _primaryDarkColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _milestoneTitle,
                      style: const TextStyle(
                        color: _textPrimaryColor,
                        fontSize: 19,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: _textSecondaryColor,
                          size: 15,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            _dueDate,
                            style: const TextStyle(
                              color: _textSecondaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildStatusChip(statusColor),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(height: 1, color: _borderColor),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tiến độ hiện tại',
                  style: TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${(_progress * 100).toInt()}%',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF0F3F1),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        _status,
        style: TextStyle(
          color: statusColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
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
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Danh sách công việc',
          icon: Icons.checklist_rounded,
        ),
        const SizedBox(height: 13),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
          ),
          child: _tasksList.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Chưa có công việc chi tiết cho '
                    'mốc thời gian này.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textSecondaryColor,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                )
              : Column(
                  children: List<Widget>.generate(_tasksList.length, (
                    int index,
                  ) {
                    return _buildTaskItem(index);
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(int index) {
    final Map<String, dynamic> task = _tasksList[index];

    final bool isDone = task['isDone'] == true;

    return CheckboxListTile(
      value: isDone,
      onChanged: (bool? value) {
        _toggleTask(index, value);
      },
      activeColor: _primaryColor,
      checkColor: Colors.white,
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        task['title']?.toString() ?? '',
        style: TextStyle(
          color: isDone ? _textSecondaryColor : _textPrimaryColor,
          fontSize: 13.5,
          height: 1.4,
          fontWeight: FontWeight.w500,
          decoration: isDone ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Minh chứng',
          icon: Icons.folder_open_outlined,
        ),
        const SizedBox(height: 13),
        if (_attachments.isEmpty)
          _buildEmptyAttachmentState()
        else
          ...List<Widget>.generate(_attachments.length, (int index) {
            return _buildAttachmentCard(index);
          }),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _addEvidence,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryDarkColor,
              backgroundColor: _surfaceColor,
              side: const BorderSide(color: _primaryColor, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(Icons.upload_file_rounded, size: 20),
            label: const Text(
              'Tải minh chứng',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAttachmentState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: const Column(
        children: [
          Icon(Icons.folder_off_outlined, color: Color(0xFF9AA49E), size: 29),
          SizedBox(height: 9),
          Text(
            'Chưa có minh chứng nào.',
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

  Widget _buildAttachmentCard(int index) {
    final Map<String, dynamic> attachment = _attachments[index];

    final String fileName =
        attachment['originalFileName']?.toString() ??
        attachment['fileName']?.toString() ??
        'tep_dinh_kem';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(17),
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
          if (_isLeader)
            IconButton(
              tooltip: 'Xóa minh chứng',
              onPressed: () {
                _showDeleteConfirmation(index);
              },
              style: IconButton.styleFrom(
                foregroundColor: _errorColor,
                backgroundColor: const Color(0xFFFFECEE),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title: 'Trao đổi', icon: Icons.forum_outlined),
        const SizedBox(height: 13),
        if (_commentsList.isEmpty)
          _buildEmptyCommentsState()
        else
          ..._commentsList.map(_buildCommentBubble),
        const SizedBox(height: 4),
        _buildReplyField(),
      ],
    );
  }

  Widget _buildEmptyCommentsState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: const Text(
        'Chưa có thảo luận nào.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _textSecondaryColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCommentBubble(Map<String, dynamic> comment) {
    final String sender = comment['sender']?.toString() ?? '';

    final String text = comment['text']?.toString() ?? '';

    final bool isMe = sender != 'Giáo viên';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
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
                color: isMe ? const Color(0xFFD4EDDF) : _borderColor,
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: _textPrimaryColor,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              sender,
              style: const TextStyle(
                color: Color(0xFF8B9690),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
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
                hintText: 'Nhập nội dung',
                hintStyle: TextStyle(color: Color(0xFF9AA49E), fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Gửi',
            onPressed: _sendReply,
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: _primaryColor,
            ),
            icon: const Icon(Icons.send_rounded, size: 19),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _surfaceColor,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: 2,
          onTap: _onBottomNavTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: _surfaceColor,
          elevation: 0,
          selectedItemColor: _primaryDarkColor,
          unselectedItemColor: const Color(0xFF8B9690),
          selectedFontSize: 11,
          unselectedFontSize: 10.5,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
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
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _statusColor(_status);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          return;
        }

        _closeScreen();
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: _buildAppBar(),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildPermissionBanner(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverviewCard(statusColor),
                          const SizedBox(height: 28),
                          _buildTasksSection(),
                          const SizedBox(height: 28),
                          _buildAttachmentsSection(),
                          const SizedBox(height: 28),
                          _buildCommentsSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }
}
