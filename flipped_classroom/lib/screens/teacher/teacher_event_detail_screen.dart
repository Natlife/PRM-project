import 'package:flutter/material.dart';

class TeacherEventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const TeacherEventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<TeacherEventDetailScreen> createState() => _TeacherEventDetailScreenState();
}

class _TeacherEventDetailScreenState extends State<TeacherEventDetailScreen> {
  late String _status;
  late String _eventTitle;
  late String _classCode;
  late String _date;
  late String _duration;
  late String _description;

  // Assignment List
  final List<Map<String, String>> _assignments = [];

  // Question Bank
  final List<String> _questionBank = [
    'Bạn có thể giải thích rõ hơn về kiến trúc hệ thống?',
    'Làm thế nào để ứng dụng tối ưu hóa dung lượng bộ nhớ cache?',
    'Nhóm đã giải quyết vấn đề bảo mật thông tin người dùng như thế nào?',
    'Kế hoạch kiểm thử (testing plan) của nhóm đã đạt độ bao phủ bao nhiêu phần trăm?',
  ];

  // Scoring / Grades list
  final List<Map<String, dynamic>> _grades = [
    {'group': 'Nhóm 1', 'presenter': 'Nguyễn Minh Anh', 'score': '8.5', 'feedback': 'Thuyết trình tốt, UI đẹp'},
    {'group': 'Nhóm 2', 'presenter': 'Lê Hoàng Cường', 'score': '7.8', 'feedback': 'Sản phẩm chạy ổn, cần tối ưu database'},
    {'group': 'Nhóm 3', 'presenter': 'Trần Minh Quân', 'score': '', 'feedback': ''},
  ];

  // List of mock students for assignments dropdown
  final List<String> _mockStudents = [
    'Nguyễn Minh Anh',
    'Lê Hoàng Cường',
    'Nguyễn Vân Anh',
    'Trần Minh Quân',
    'Đỗ Hồng Hạnh',
    'Vũ Quốc Bảo',
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.event['status'] ?? 'Chưa diễn ra';
    _eventTitle = widget.event['title'] ?? 'Thuyết trình STEM';
    _classCode = widget.event['classCode'] ?? 'PRM - SE1904';
    _date = widget.event['date'] ?? '25/6/2026';
    _duration = widget.event['duration'] ?? '20';
    _description = widget.event['description'] ?? 'Lớp chia thành 4 nhóm và ra đề bài cho nhau';

    // Populate a default assignment pair to look like mockup initially
    _assignments.add({
      'presenter': 'Nguyễn Minh Anh',
      'reviewer': 'Lê Hoàng Cường',
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đang diễn ra':
        return Colors.green;
      case 'Đã diễn ra':
        return Colors.grey;
      case 'Chưa diễn ra':
      default:
        return Colors.orange;
    }
  }

  // Popup 1: Assign Student (Phân công sinh viên / Chỉnh sửa)
  void _showAssignmentDialog({int? index}) {
    String presenter = _mockStudents.first;
    String reviewer = _mockStudents[1];

    if (index != null) {
      presenter = _assignments[index]['presenter'] ?? _mockStudents.first;
      reviewer = _assignments[index]['reviewer'] ?? _mockStudents[1];
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: Text(
                index == null ? 'Phân công học viên' : 'Chỉnh sửa phân công',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Người thuyết trình (Presenter)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: presenter,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _mockStudents.map((name) {
                      return DropdownMenuItem<String>(value: name, child: Text(name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => presenter = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Người phản biện (Reviewer)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: reviewer,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _mockStudents.map((name) {
                      return DropdownMenuItem<String>(value: name, child: Text(name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => reviewer = val);
                    },
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                if (index != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _assignments.removeAt(index);
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã xóa phân công!'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
                      );
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF0F172A).withValues(alpha: 0.5)),
                  child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (presenter == reviewer) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Người thuyết trình và Người phản biện không được trùng nhau!'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
                      );
                      return;
                    }
                    setState(() {
                      if (index == null) {
                        _assignments.add({'presenter': presenter, 'reviewer': reviewer});
                      } else {
                        _assignments[index] = {'presenter': presenter, 'reviewer': reviewer};
                      }
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(index == null ? 'Phân công thành công!' : 'Cập nhật phân công thành công!'), backgroundColor: const Color(0xFF7EC07E), behavior: SnackBarBehavior.floating),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7EC07E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Popup 2: Question Bank (Ngân hàng câu hỏi)
  void _showQuestionBankDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'Ngân hàng câu hỏi',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Add question form
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            decoration: InputDecoration(
                              hintText: 'Thêm câu hỏi mới...',
                              hintStyle: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF7EC07E), size: 36),
                          onPressed: () {
                            final text = textController.text.trim();
                            if (text.isNotEmpty) {
                              setState(() {
                                _questionBank.insert(0, text);
                              });
                              setDialogState(() {
                                textController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Questions list
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _questionBank.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _questionBank[index],
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _questionBank.removeAt(index);
                                    });
                                    setDialogState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF7EC07E)),
                  child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Popup 3: View Results (Xem kết quả)
  void _showResultsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'Bảng kết quả & Đánh giá',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _grades.length,
                  itemBuilder: (context, index) {
                    final item = _grades[index];
                    final hasScore = (item['score'] as String).isNotEmpty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item['group']} - ${item['presenter']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: hasScore ? const Color(0xFF7EC07E).withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  hasScore ? '${item['score']}/10' : 'Chưa nhập điểm',
                                  style: TextStyle(
                                    color: hasScore ? const Color(0xFF7EC07E) : Colors.amber[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (hasScore)
                            Text(
                              'Nhận xét: ${item['feedback']}',
                              style: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.6), fontSize: 13),
                            ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Icons.edit, size: 14),
                              label: Text(hasScore ? 'Sửa điểm' : 'Nhập điểm'),
                              style: TextButton.styleFrom(foregroundColor: const Color(0xFF7EC07E)),
                              onPressed: () {
                                _showGradeEntryDialog(index, setDialogState);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF7EC07E)),
                  child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGradeEntryDialog(int index, StateSetter parentSetState) {
    final scoreController = TextEditingController(text: _grades[index]['score']);
    final feedbackController = TextEditingController(text: _grades[index]['feedback']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Nhập điểm cho ${_grades[index]['group']}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Điểm số (0 - 10)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: scoreController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Ví dụ: 8.5',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Nhận xét', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: feedbackController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Nhập nhận xét của giảng viên...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final score = scoreController.text.trim();
                final feedback = feedbackController.text.trim();
                if (score.isNotEmpty) {
                  final doubleScore = double.tryParse(score);
                  if (doubleScore == null || doubleScore < 0 || doubleScore > 10) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập điểm số hợp lệ từ 0 đến 10!'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                }
                setState(() {
                  _grades[index]['score'] = score;
                  _grades[index]['feedback'] = feedback;
                });
                parentSetState(() {});
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7EC07E), foregroundColor: Colors.white),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _getStatusColor(_status);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết sự kiện',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Testing dropdown/helper to cycle status
          TextButton.icon(
            onPressed: () {
              setState(() {
                if (_status == 'Chưa diễn ra') {
                  _status = 'Đang diễn ra';
                } else if (_status == 'Đang diễn ra') {
                  _status = 'Đã diễn ra';
                } else {
                  _status = 'Chưa diễn ra';
                }
              });
            },
            icon: const Icon(Icons.change_circle_outlined, size: 16, color: Colors.blue),
            label: Text(
              _status,
              style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Details Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        _classCode,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _eventTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _date,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF0F172A).withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _description,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF0F172A).withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                  const Divider(height: 24, thickness: 1),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$_duration phút/phiên',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7EC07E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Event Management (Quản lý sự kiện) Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quản lý sự kiện',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Button 1: Assign Student
                  _buildManagementButton('Phân công sinh viên', Icons.person_add_alt_1_outlined, () {
                    _showAssignmentDialog();
                  }),
                  const SizedBox(height: 12),

                  // Button 2: Event Control Panel
                  _buildManagementButton('Mở điều khiển sự kiện', Icons.settings_remote_outlined, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeacherEventControlScreen(
                          eventTitle: _eventTitle,
                          classCode: _classCode,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  // Button 3: Question Bank
                  _buildManagementButton('Ngân hàng câu hỏi', Icons.question_answer_outlined, () {
                    _showQuestionBankDialog();
                  }),
                  const SizedBox(height: 12),

                  // Button 4: View Results
                  _buildManagementButton('Xem kết quả', Icons.insights_outlined, () {
                    _showResultsDialog();
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Assignment List Section (Danh sách phân công)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Danh sách phân công',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _showAssignmentDialog();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Chỉnh sửa',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_assignments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.04)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 40, color: const Color(0xFF0F172A).withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text(
                      'Danh sách phân công trống',
                      style: TextStyle(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.4),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._assignments.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.06)),
                  ),
                  child: InkWell(
                    onTap: () => _showAssignmentDialog(index: index),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.people_outline, color: Color(0xFF2563EB), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['presenter'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Phản biện: ${item['reviewer'] ?? ""}',
                                style: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 14, color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xFF0F172A), size: 18),
        label: Text(
          label,
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF1F5F9),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
          ),
        ),
      ),
    );
  }
}

// Sub-screen: Event Control (Điều khiển sự kiện)
class TeacherEventControlScreen extends StatefulWidget {
  final String eventTitle;
  final String classCode;

  const TeacherEventControlScreen({
    super.key,
    required this.eventTitle,
    required this.classCode,
  });

  @override
  State<TeacherEventControlScreen> createState() => _TeacherEventControlScreenState();
}

class _TeacherEventControlScreenState extends State<TeacherEventControlScreen> {
  bool _isRecording = false;
  int _secondsElapsed = 0;
  JavaTimer? _timer;

  // Question list waiting for approval
  final List<Map<String, String>> _incomingQuestions = [
    {'author': 'Nguyễn Vân Anh', 'question': 'Tại sao kiến trúc này tối ưu hơn MVC?'},
    {'author': 'Đỗ Hồng Hạnh', 'question': 'Thời gian phản hồi cơ sở dữ liệu có đảm bảo dưới 200ms không?'},
  ];

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _timer = JavaTimer(
      periodic: true,
      duration: const Duration(seconds: 1),
      onTick: () {
        setState(() {
          _secondsElapsed++;
        });
      },
    );
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatDuration(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Điều khiển phòng phản biện',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Details Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.eventTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.classCode,
                    style: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Control Box (Start/Stop Recording)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRecording ? 'Đang ghi hình thuyết trình' : 'Chưa bắt đầu phiên thuyết trình',
                        style: TextStyle(
                          color: _isRecording ? Colors.red : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (_isRecording) ...[
                    const SizedBox(height: 12),
                    Text(
                      _formatDuration(_secondsElapsed),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isRecording = !_isRecording;
                          if (_isRecording) {
                            _secondsElapsed = 0;
                            _startTimer();
                          } else {
                            _stopTimer();
                          }
                        });
                      },
                      icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow, color: Colors.white),
                      label: Text(
                        _isRecording ? 'Kết thúc phiên & Lưu bản ghi' : 'Bắt đầu ghi hình sự kiện',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording ? Colors.redAccent : const Color(0xFF7EC07E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live Questions Approvals
            const Text(
              'Câu hỏi từ hội đồng phản biện',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),

            if (_incomingQuestions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text('Chưa có câu hỏi nào gửi đến', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              )
            else
              ..._incomingQuestions.asMap().entries.map((entry) {
                final idx = entry.key;
                final q = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q['author'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        q['question'] ?? '',
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _incomingQuestions.removeAt(idx);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã từ chối câu hỏi!'), backgroundColor: Colors.redAccent),
                              );
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                            child: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _incomingQuestions.removeAt(idx);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã duyệt câu hỏi và chuyển đến Presenter!'), backgroundColor: Color(0xFF7EC07E)),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7EC07E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            child: const Text('Duyệt', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// Simple periodic timer wrapper for compatibility and safety
class JavaTimer {
  final bool periodic;
  final Duration duration;
  final VoidCallback onTick;
  bool _cancelled = false;

  JavaTimer({
    required this.periodic,
    required this.duration,
    required this.onTick,
  }) {
    _run();
  }

  void _run() async {
    while (!_cancelled) {
      await Future.delayed(duration);
      if (_cancelled) break;
      onTick();
      if (!periodic) break;
    }
  }

  void cancel() {
    _cancelled = true;
  }
}
