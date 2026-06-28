import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../../services/project_service.dart';

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
  bool _isLeader = false;

  late String _milestoneTitle;
  late String _dueDate;
  late String _status;
  late double _progress;
  late List<Map<String, dynamic>> _tasksList;
  late List<String> _evidenceList;
  late List<Map<String, String>> _comments;

  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _milestoneTitle = widget.milestone['title'] ?? 'Chi tiết Milestone';

    final String dueAtStr = widget.milestone['dueAt'] ?? widget.milestone['dueDate'] ?? '';
    if (dueAtStr.isNotEmpty) {
      if (dueAtStr.contains('Hạn:')) {
        _dueDate = dueAtStr;
      } else {
        try {
          final DateTime dt = DateTime.parse(dueAtStr);
          _dueDate = 'Hạn: ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        } catch (_) {
          _dueDate = dueAtStr;
        }
      }
    } else {
      _dueDate = 'Không có thời hạn';
    }

    final String statusRaw = widget.milestone['status'] ?? 'NOT_STARTED';
    if (statusRaw == 'COMPLETED' || statusRaw == 'Hoàn thành') {
      _status = 'Hoàn thành';
    } else if (statusRaw == 'IN_PROGRESS' || statusRaw == 'Đang thực hiện') {
      _status = 'Đang thực hiện';
    } else if (statusRaw == 'OVERDUE' || statusRaw == 'Quá hạn') {
      _status = 'Quá hạn';
    } else {
      _status = 'Chưa bắt đầu';
    }

    final dynamic rawPercent = widget.milestone['progressPercent'] ?? widget.milestone['progress'];
    if (rawPercent != null) {
      if (rawPercent is int) {
        _progress = rawPercent / 100.0;
      } else {
        _progress = (rawPercent as num).toDouble();
      }
    } else {
      _progress = 0.0;
    }

    final currentUser = AuthService().currentUser;
    final leader = widget.project['leader'] as Map<String, dynamic>?;
    final leaderId = leader?['id']?.toString();
    final leaderUsername = leader?['userName']?.toString();
    _isLeader = leaderId == currentUser?.id || leaderUsername == currentUser?.username;

    _tasksList = widget.milestone['tasks'] != null
        ? List<Map<String, dynamic>>.from(widget.milestone['tasks'])
        : <Map<String, dynamic>>[];

    final List<dynamic> attachments = widget.milestone['attachments'] ?? [];
    _evidenceList = attachments.isNotEmpty
        ? attachments.map((a) => a['fileName'] as String? ?? 'tai_lieu.pdf').toList()
        : (widget.milestone['evidenceList'] != null
            ? List<String>.from(widget.milestone['evidenceList'])
            : <String>[]);

    _comments = widget.milestone['comments'] != null
        ? List<Map<String, String>>.from(widget.milestone['comments'])
        : <Map<String, String>>[];
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    Navigator.pop(context, index);
  }

  Future<void> _updateProgressOnBackend(double newProgress) async {
    final int milestoneId = widget.milestone['id'] ?? 0;
    if (milestoneId == 0) return;

    int percent = (newProgress * 100).toInt();
    String backendStatus = 'NOT_STARTED';
    if (percent == 100) {
      backendStatus = 'COMPLETED';
    } else if (percent > 0) {
      backendStatus = 'IN_PROGRESS';
    }

    try {
      await ProjectService().updateMilestoneProgress(milestoneId, percent, backendStatus);
      debugPrint('Milestone progress updated successfully on backend');
    } catch (e) {
      debugPrint('Failed to update milestone progress on backend: $e');
    }
  }

  void _recalculateProgress() {
    if (_tasksList.isEmpty) return;
    int completedCount = _tasksList.where((t) => t['isDone'] == true).length;
    double newProgress = completedCount / _tasksList.length;

    setState(() {
      _progress = newProgress;
      if (_progress == 1.0) {
        _status = 'Hoàn thành';
      } else if (_progress == 0.0) {
        _status = 'Chưa bắt đầu';
      } else {
        _status = 'Đang thực hiện';
      }
    });

    _updateProgressOnBackend(newProgress);
  }

  void _toggleTask(int index, bool? val) {
    if (!_isLeader) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ trưởng nhóm được tick hoàn thành (thành viên chỉ xem và trao đổi)!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _tasksList[index]['isDone'] = val ?? false;
      _recalculateProgress();
    });
  }

  void _addEvidence() {
    if (!_isLeader) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ trưởng nhóm được tải evidence lên (thành viên chỉ xem và trao đổi)!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tải evidence từ thiết bị chưa được nối ở màn này.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    if (!_isLeader) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ trưởng nhóm được xóa evidence!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Bạn có chắc chắn muốn xóa?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Hủy',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _evidenceList.removeAt(index);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa minh chứng.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    _replyController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bình luận milestone chưa có API backend tương ứng.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _status == 'Hoàn thành';

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
              'evidenceList': _evidenceList,
              'comments': _comments,
            });
          },
        ),
        title: const Text(
          'Chi tiết milestone',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18),
        ),
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(
            color: const Color(0xFF0F172A).withOpacity(0.06),
            width: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Simulation role banner
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
                          ? 'Bạn là trưởng nhóm, có thể cập nhật tiến độ milestone.'
                          : 'Bạn là thành viên, chỉ có thể theo dõi tiến độ milestone.',
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                _milestoneTitle,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _dueDate.startsWith('Hạn') ? _dueDate : 'Hạn chót: $_dueDate',
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
                            color: isCompleted
                                ? const Color(0xFF7EC07E).withOpacity(0.15)
                                : _status == 'Chưa bắt đầu'
                                    ? Colors.grey.withOpacity(0.12)
                                    : Colors.amberAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _status,
                            style: TextStyle(
                              color: isCompleted
                                  ? const Color(0xFF7EC07E)
                                  : _status == 'Chưa bắt đầu'
                                      ? Colors.grey.shade700
                                      : Colors.amber.shade800,
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted ? const Color(0xFF7EC07E) : const Color(0xFFF59E0B),
                              ),
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
                      child: Column(
                        children: List.generate(_tasksList.length, (index) {
                          final task = _tasksList[index];
                          return CheckboxListTile(
                            title: Text(
                              task['title'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF0F172A),
                                decoration: task['isDone'] ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            value: task['isDone'] ?? false,
                            onChanged: (val) => _toggleTask(index, val),
                            activeColor: const Color(0xFF7EC07E),
                            checkColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            controlAffinity: ListTileControlAffinity.trailing,
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Minh chứng (Evidence)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(_evidenceList.length, (index) {
                      final item = _evidenceList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.file_present, color: Color(0xFF7EC07E), size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  item,
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                                ),
                              ],
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
                        'Button upload evidence',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7EC07E)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFF7EC07E), width: 1.2),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    const Text(
                      'Trao đổi với giảng viên',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    ..._comments.map((comment) {
                      final isTeacher = comment['sender'] == 'Giáo viên';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isTeacher ? const Color(0xFFF1F5F9) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isTeacher ? Colors.transparent : const Color(0xFF0F172A).withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTeacher ? 'Hiển thị cmt của giảng viên' : 'Hiển thị câu trả lời của sinh viên',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isTeacher ? const Color(0xFF475569) : const Color(0xFF7EC07E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              comment['text'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                                height: 1.4,
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
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Nhập câu trả lời',
                                hintStyle: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.3)),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: const Color(0xFF0F172A).withOpacity(0.06),
              width: 1.2,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: 2,
          onTap: _onBottomNavTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFFFFFFF),
          selectedItemColor: const Color(0xFF7EC07E),
          unselectedItemColor: const Color(0xFF0F172A).withOpacity(0.4),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school),
              label: 'Lớp học',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_work_outlined),
              activeIcon: Icon(Icons.group_work),
              label: 'Dự án',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Thông báo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
