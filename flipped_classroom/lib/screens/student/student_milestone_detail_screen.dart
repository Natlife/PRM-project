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
      return 'Khong co thoi han';
    }
    final value = raw.toString();
    if (value.contains('Han')) {
      return value;
    }
    try {
      final dt = DateTime.parse(value);
      return 'Han: ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return value;
    }
  }

  String _normalizeStatus(dynamic raw) {
    final value = raw?.toString() ?? 'NOT_STARTED';
    if (value == 'COMPLETED' || value == 'Hoan thanh') {
      return 'Hoan thanh';
    }
    if (value == 'IN_PROGRESS' || value == 'Dang thuc hien') {
      return 'Dang thuc hien';
    }
    if (value == 'OVERDUE' || value == 'Qua han') {
      return 'Qua han';
    }
    return 'Chua bat dau';
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
      case 'Hoan thanh':
        return const Color(0xFF7EC07E);
      case 'Dang thuc hien':
        return const Color(0xFFF59E0B);
      case 'Qua han':
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

    try {
      await ProjectService().updateMilestoneProgress(milestoneId, percent, backendStatus);
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
        _status = 'Hoan thanh';
      } else if (newProgress == 0) {
        _status = 'Chua bat dau';
      } else {
        _status = 'Dang thuc hien';
      }
    });

    _updateProgressOnBackend(newProgress);
  }

  void _toggleTask(int index, bool? value) {
    if (!_isLeader) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chi truong nhom moi co the cap nhat task milestone.'),
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

  void _addEvidence() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UI upload milestone attachment chua duoc noi voi backend.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    if (!_isLeader) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chi truong nhom moi co the xoa minh chung.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoa minh chung?'),
        content: const Text('Minh chung nay se chi bi xoa tren UI hien tai.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _attachments.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Xoa'),
          ),
        ],
      ),
    );
  }

  void _sendReply() {
    _replyController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backend hien chua co API comment milestone cho student.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    Navigator.pop(context, index);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_status);

    return Scaffold(
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
          'Chi tiet milestone',
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
                          ? 'Ban la truong nhom va co the cap nhat tien do milestone.'
                          : 'Ban la thanh vien, chi xem tien do va tai lieu da nop.',
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
                      'Danh sach cong viec',
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
                              'Chua co task chi tiet cho milestone nay.',
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
                      'Minh chung',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    if (_attachments.isEmpty)
                      const Text(
                        'Chua co minh chung nao tu backend.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ...List.generate(_attachments.length, (index) {
                      final attachment = _attachments[index];
                      final fileName = attachment['fileName']?.toString().trim().isNotEmpty == true
                          ? attachment['fileName'].toString()
                          : 'tep_dinh_kem';
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
                        'Tai minh chung',
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
                      'Trao doi',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Backend hien chua co API comment rieng cho milestone o man student.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
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
                                hintText: 'Nhap noi dung',
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
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Trang chu'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'Lop hoc'),
          BottomNavigationBarItem(icon: Icon(Icons.group_work_outlined), label: 'Du an'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Thong bao'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Ca nhan'),
        ],
      ),
    );
  }
}
