import 'package:flutter/material.dart';

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
  // Role simulation state: true = Trưởng nhóm (Leader), false = Thành viên (Member)
  bool _isLeader = true; 

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
    _milestoneTitle = widget.milestone['title'] ?? 'Thiết kế hệ thống';
    _dueDate = widget.milestone['dueDate'] ?? 'Hạn: 30/5/2026';
    _status = widget.milestone['status'] ?? 'Đang thực hiện';
    _progress = widget.milestone['progress'] ?? 0.6;

    // Subtasks for checklist
    _tasksList = widget.milestone['tasks'] != null
        ? List<Map<String, dynamic>>.from(widget.milestone['tasks'])
        : [
            {'title': 'Tạo database', 'isDone': true},
            {'title': 'Xây dựng giao diện', 'isDone': false},
          ];

    // Evidence list
    _evidenceList = widget.milestone['evidenceList'] != null
        ? List<String>.from(widget.milestone['evidenceList'])
        : ['srs_document.pdf', 'database_design.png'];

    // Comments list
    _comments = widget.milestone['comments'] != null
        ? List<Map<String, String>>.from(widget.milestone['comments'])
        : [
            {'sender': 'Giáo viên', 'text': 'Sơ đồ database cần bổ sung thêm bảng log lịch sử hoạt động nhé.'},
            {'sender': 'Sinh viên', 'text': 'Dạ vâng ạ, chúng em sẽ cập nhật thiết kế cơ sở dữ liệu.'},
          ];
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    // Return index to main navigation system
    Navigator.pop(context, index);
  }

  // Calculate progress based on completed tasks
  void _recalculateProgress() {
    if (_tasksList.isEmpty) return;
    int completedCount = _tasksList.where((t) => t['isDone'] == true).length;
    setState(() {
      _progress = completedCount / _tasksList.length;
      if (_progress == 1.0) {
        _status = 'Hoàn thành';
      } else if (_progress == 0.0) {
        _status = 'Chưa bắt đầu';
      } else {
        _status = 'Đang thực hiện';
      }
    });
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

    setState(() {
      final index = _evidenceList.length + 1;
      _evidenceList.add('minh_chung_milestone_$index.png');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã tải minh chứng lên thành công!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF7EC07E),
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
                Navigator.pop(context); // Close dialog, do nothing (Hủy)
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
                Navigator.pop(context); // Close dialog (Xác nhận)
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

    setState(() {
      _comments.add({
        'sender': 'Sinh viên',
        'text': text,
      });
      _replyController.clear();
    });
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
            // Return updated details back to Project screen
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
            // Simulation bar for changing member/leader role
            Container(
              color: const Color(0xFFEFF6FF),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_outlined, color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Mô phỏng vai trò:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Trưởng nhóm'),
                        selected: _isLeader,
                        onSelected: (selected) {
                          if (selected) setState(() => _isLeader = true);
                        },
                        selectedColor: Colors.blueAccent,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isLeader ? Colors.white : Colors.blueAccent,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: Colors.blueAccent, width: 1),
                        showCheckmark: false,
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Thành viên'),
                        selected: !_isLeader,
                        onSelected: (selected) {
                          if (selected) setState(() => _isLeader = false);
                        },
                        selectedColor: Colors.blueAccent,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: !_isLeader ? Colors.white : Colors.blueAccent,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: Colors.blueAccent, width: 1),
                        showCheckmark: false,
                      ),
                    ],
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
                    // Milestone title and status row
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

                    // Progress indicator
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

                    // Task checklist block
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

                    // Evidence upload block
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

                    // Teacher discussion block
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

                    // Reply Input field
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
          currentIndex: 2, // Active under Projects tab navigation flow
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
