import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

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
  State<StudentMilestoneDetailScreen> createState() => _StudentMilestoneDetailScreenState();
}

class _StudentMilestoneDetailScreenState extends State<StudentMilestoneDetailScreen> {
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
    _milestoneTitle = widget.milestone['title']?.toString() ?? 'Chi tiet milestone';
    _dueDate = _buildDueDate(widget.milestone['dueAt'] ?? widget.milestone['dueDate']);
    _status = _normalizeStatus(widget.milestone['status']);
    _progress = _normalizeProgress(widget.milestone['progressPercent'] ?? widget.milestone['progress']);
    _tasksList = widget.milestone['tasks'] != null
        ? List<Map<String, dynamic>>.from(widget.milestone['tasks'])
        : <Map<String, dynamic>>[];
    _attachments = List<Map<String, dynamic>>.from(widget.milestone['attachments'] ?? const []);
    _commentsList = widget.milestone['comments'] != null
        ? List<Map<String, dynamic>>.from(widget.milestone['comments'])
        : <Map<String, dynamic>>[];

    final currentUser = AuthService().currentUser;
    final leader = widget.project['leader'] as Map<String, dynamic>?;
    final leaderId = leader?['id']?.toString();
    final leaderUsername = leader?['userName']?.toString();
    _isLeader = leaderId == currentUser?.id || leaderUsername == currentUser?.username;
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
    final value = raw.toString();
    if (value.contains('Hạn')) {
      return value;
    }
    try {
      final dt = DateTime.parse(value);
      return 'Hạn: ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return value;
    }
  }

  String _normalizeStatus(dynamic raw) {
    final value = raw?.toString() ?? 'NOT_STARTED';
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
    final value = (raw as num).toDouble();
    return value > 1 ? value / 100.0 : value;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
        return const Color(0xFF7EC07E);
      case 'Đang thực hiện':
        return const Color(0xFFF59E0B);
      case 'Quá hạn':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateProgressOnBackend(double newProgress) async {
    final milestoneId = (widget.milestone['id'] as num?)?.toInt() ?? 0;
    if (milestoneId == 0) {
      return;
    }

    final percent = (newProgress * 100).toInt();
    String backendStatus = 'NOT_STARTED';
    if (percent == 100) {
      backendStatus = 'COMPLETED';
    } else if (percent > 0) {
      backendStatus = 'IN_PROGRESS';
    }

    final descriptionPayload = jsonEncode({
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
    } catch (e) {
      debugPrint('Failed to update milestone progress: $e');
    }
  }

  void _recalculateProgress() {
    if (_tasksList.isEmpty) {
      return;
    }

    final completedCount = _tasksList.where((task) => task['isDone'] == true).length;
    final newProgress = completedCount / _tasksList.length;

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
          content: Text('Chỉ trưởng nhóm mới có thể cập nhật công việc mốc thời gian.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
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
      final result = await FilePicker.pickFiles();
      if (result == null || result.files.isEmpty) {
        return;
      }
      final file = result.files.first;
      final fileBytes = file.bytes;
      final fileName = file.name;
      
      List<int>? bytes = fileBytes;
      if (bytes == null && file.path != null) {
        final fileIo = io.File(file.path!);
        bytes = await fileIo.readAsBytes();
      }

      if (bytes == null) {
        throw Exception('Không thể đọc file');
      }

      final milestoneId = (widget.milestone['id'] as num?)?.toInt() ?? 0;
      if (milestoneId == 0) {
        throw Exception('Mã mốc thời gian không hợp lệ');
      }

      bool showSpinner = false;
      if (mounted) {
        showSpinner = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      try {
        final updatedList = await ProjectService().uploadMilestoneAttachment(
          milestoneId,
          bytes,
          fileName,
        );

        if (showSpinner && mounted) {
          Navigator.pop(context);
          showSpinner = false;
        }

        setState(() {
          _attachments = updatedList;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tải lên minh chứng thành công!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF7EC07E),
            ),
          );
        }
      } finally {
        if (showSpinner && mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tải file thất bại: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(int index) {
    if (!_isLeader) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ trưởng nhóm mới có thể xóa minh chứng.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa minh chứng?'),
        content: const Text('Minh chứng này sẽ chỉ bị xóa trên giao diện hiện tại.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _attachments.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    final milestoneId = (widget.milestone['id'] as num?)?.toInt() ?? 0;
    if (milestoneId == 0) return;

    final currentUser = AuthService().currentUser;
    final senderName = currentUser?.fullName ?? currentUser?.username ?? 'Học viên';

    final newComment = {
      'sender': senderName,
      'text': text,
    };

    setState(() {
      _commentsList.add(newComment);
      _replyController.clear();
    });

    final percent = (_progress * 100).toInt();
    String backendStatus = 'NOT_STARTED';
    if (percent == 100) {
      backendStatus = 'COMPLETED';
    } else if (percent > 0) {
      backendStatus = 'IN_PROGRESS';
    }

    final descriptionPayload = jsonEncode({
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
    } catch (e) {
      debugPrint('Failed to send comment: $e');
    }
  }

  void _onBottomNavTapped(int index) {
    Navigator.pop(context, index);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_status);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, {
          'status': _status,
          'progress': _progress,
          'tasks': _tasksList,
          'attachments': _attachments,
        });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 18),
          onPressed: () {
            Navigator.pop(context, {
              'status': _status,
              'progress': _progress,
              'tasks': _tasksList,
              'attachments': _attachments,
            });
          },
        ),
        title: const Text(
          'Chi tiết mốc thời gian',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFFEFF6FF),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blueAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isLeader
                          ? 'Bạn là trưởng nhóm và có thể cập nhật tiến độ mốc thời gian.'
                          : 'Bạn là thành viên, chỉ xem tiến độ và tài liệu đã nộp.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _milestoneTitle,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _dueDate,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF0F172A).withOpacity(0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: 6,
                              backgroundColor: const Color(0xFF0F172A).withOpacity(0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Danh sách công việc',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
                      ),
                      child: _tasksList.isEmpty
                          ? const Text(
                              'Chưa có công việc chi tiết cho mốc thời gian này.',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            )
                          : Column(
                              children: List.generate(_tasksList.length, (index) {
                                final task = _tasksList[index];
                                return CheckboxListTile(
                                  title: Text(
                                    task['title']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: const Color(0xFF0F172A),
                                      decoration: task['isDone'] == true ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  value: task['isDone'] == true,
                                  onChanged: (value) => _toggleTask(index, value),
                                  activeColor: const Color(0xFF7EC07E),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  controlAffinity: ListTileControlAffinity.trailing,
                                );
                              }),
                            ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Minh chứng',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    if (_attachments.isEmpty)
                      const Text(
                        'Chưa có minh chứng nào.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ...List.generate(_attachments.length, (index) {
                      final attachment = _attachments[index];
                      final fileName = attachment['originalFileName']?.toString() ??
                          (attachment['fileName']?.toString() ?? 'tep_dinh_kem');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.file_present, color: Color(0xFF7EC07E), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                fileName,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                            ),
                            if (_isLeader)
                              GestureDetector(
                                onTap: () => _showDeleteConfirmation(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    ElevatedButton.icon(
                      onPressed: _addEvidence,
                      icon: const Icon(Icons.upload_file, size: 18, color: Color(0xFF7EC07E)),
                      label: const Text(
                        'Tải minh chứng',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7EC07E)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFF7EC07E), width: 1.2),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Trao đổi',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    if (_commentsList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Chưa có thảo luận nào.',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      )
                    else
                      ..._commentsList.map((comment) {
                        final sender = comment['sender']?.toString() ?? '';
                        final text = comment['text']?.toString() ?? '';
                        final isMe = sender != 'Giáo viên';

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
                                    color: const Color(0xFF0F172A).withOpacity(0.1),
                                  ),
                                ),
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  sender,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              decoration: const InputDecoration(
                                hintText: 'Nhập nội dung',
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendReply(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF7EC07E), size: 20),
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
        currentIndex: 2,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: const Color(0xFF7EC07E),
        unselectedItemColor: const Color(0xFF0F172A).withOpacity(0.4),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'Lớp học'),
          BottomNavigationBarItem(icon: Icon(Icons.group_work_outlined), label: 'Dự án'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Thông báo'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Cá nhân'),
        ],
      ),
    ),
  );
}
}
