import 'package:flutter/material.dart';

class StudentActivityDetailScreen extends StatefulWidget {
  final Map<String, dynamic> activity;

  const StudentActivityDetailScreen({
    super.key,
    required this.activity,
  });

  @override
  State<StudentActivityDetailScreen> createState() => _StudentActivityDetailScreenState();
}

class _StudentActivityDetailScreenState extends State<StudentActivityDetailScreen> {
  late bool _isDone;
  late List<String> _evidenceList;
  late List<Map<String, String>> _comments;
  
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isDone = widget.activity['status'] == 'Đã làm';
    
    // Initialize mock evidence if empty
    if (widget.activity['evidenceList'] != null) {
      _evidenceList = List<String>.from(widget.activity['evidenceList']);
    } else {
      _evidenceList = _isDone ? ['Ảnh evidence 1.png', 'Ảnh evidence 2.png'] : [];
    }

    // Initialize mock comments
    if (widget.activity['comments'] != null) {
      _comments = List<Map<String, String>>.from(widget.activity['comments']);
    } else {
      _comments = [
        {'sender': 'Giáo viên', 'text': 'Bài nộp đầy đủ. Cần chú ý cách phân chia Widget ở màn hình Dashboard để clean code hơn nhé.'},
        {'sender': 'Sinh viên', 'text': 'Dạ vâng em cảm ơn thầy ạ, em sẽ rút kinh nghiệm.'},
      ];
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    Navigator.pop(context, index);
  }

  void _addEvidence() {
    setState(() {
      final index = _evidenceList.length + 1;
      _evidenceList.add('Ảnh evidence $index.png');
      _isDone = true;
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
                  if (_evidenceList.isEmpty) {
                    _isDone = false;
                  }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 18),
          onPressed: () {
            // Return updated activity state back to Class Detail Screen
            Navigator.pop(context, {
              'status': _isDone ? 'Đã làm' : 'Chưa làm',
              'evidenceList': _evidenceList,
              'comments': _comments,
            });
          },
        ),
        title: const Text(
          'Chi tiết hoạt động',
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
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Activity header block
                    Text(
                      widget.activity['title'] ?? 'Tên hoạt động',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Tags and Status Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7EC07E).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.activity['type'] ?? 'Trước buổi học',
                                style: const TextStyle(
                                  color: Color(0xFF7EC07E),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A).withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'PRM',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isDone
                                ? const Color(0xFF7EC07E).withOpacity(0.15)
                                : Colors.redAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _isDone ? 'Đã làm' : 'Chưa làm',
                            style: TextStyle(
                              color: _isDone ? const Color(0xFF7EC07E) : Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Deadline
                    Text(
                      'Deadline: ${widget.activity['deadline']?.replaceAll("Hạn: ", "") ?? "10/05/2026"}',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF0F172A).withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Requirements card
                    const Text(
                      'Yêu cầu',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
                      ),
                      child: Text(
                        widget.activity['description'] ?? 'Cài đặt công cụ và tìm hiểu về ngôn ngữ Dart trong slide 1.',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF0F172A).withOpacity(0.7),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Evidence upload lists
                    ...List.generate(_evidenceList.length, (index) {
                      final item = _evidenceList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.image_outlined, color: Colors.grey, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  item,
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
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
                    
                    const SizedBox(height: 8),
                    // Upload button
                    ElevatedButton.icon(
                      onPressed: _addEvidence,
                      icon: const Icon(Icons.upload_file, size: 18, color: Color(0xFF7EC07E)),
                      label: const Text(
                        'Button tải evidence lên',
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

                    // Discussion Trao đổi với giảng viên
                    const Text(
                      'Trao đổi với giảng viên',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
                    
                    // Reply Input
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
          currentIndex: 1, // Active under classes detail flow
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
