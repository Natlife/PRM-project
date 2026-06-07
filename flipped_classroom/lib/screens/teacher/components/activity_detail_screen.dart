import 'package:flutter/material.dart';
import '../edit_activity_screen.dart';
import '../submission_detail_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final String activityTitle;
  final String deadline;
  final String submissions;
  final String description;

  const ActivityDetailScreen({
    super.key,
    required this.activityTitle,
    required this.deadline,
    required this.submissions,
    this.description = 'Hoàn thiện đầy đủ các yêu cầu của bài tập thực hành',
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late String _activityTitle;
  late String _deadline;
  late String _description;

  final List<Map<String, dynamic>> _submissionsList = [
    {'name': 'Nguyễn Văn A', 'code': 'HE170123', 'submitted': true, 'time': '19/03/2026', 'score': 9.0},
    {'name': 'Trần Thị B', 'code': 'HE170456', 'submitted': true, 'time': '18/03/2026', 'score': 8.5},
    {'name': 'Lê Văn C', 'code': 'HE170789', 'submitted': false, 'time': '', 'score': null},
    {'name': 'Phạm Minh D', 'code': 'HE170999', 'submitted': true, 'time': '19/03/2026', 'score': null},
    {'name': 'Hoàng Văn E', 'code': 'HE171111', 'submitted': true, 'time': '17/03/2026', 'score': 7.5},
    {'name': 'Đỗ Thị F', 'code': 'HE171222', 'submitted': false, 'time': '', 'score': null},
    {'name': 'Nguyễn Đức G', 'code': 'HE171333', 'submitted': true, 'time': '18/03/2026', 'score': null},
  ];

  @override
  void initState() {
    super.initState();
    _activityTitle = widget.activityTitle;
    _deadline = widget.deadline;
    _description = widget.description;
  }

  void _showGradeDialog(int index) {
    final submission = _submissionsList[index];
    final scoreController = TextEditingController(
      text: submission['score'] != null ? submission['score'].toString() : '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Chấm điểm: ${submission['name']}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: scoreController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nhập điểm (0 - 10)',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              fillColor: const Color(0xFF0F172A),
              filled: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                final double? score = double.tryParse(scoreController.text);
                if (score != null && score >= 0 && score <= 10) {
                  setState(() {
                    _submissionsList[index]['score'] = score;
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã chấm điểm ${score.toString()} cho ${submission['name']}!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập điểm hợp lệ từ 0 đến 10!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalStudents = _submissionsList.length;
    final submittedStudents = _submissionsList.where((s) => s['submitted'] as bool).length;
    final percentage = totalStudents > 0 ? (submittedStudents / totalStudents * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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
                        color: const Color(0xFF2E8EFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Chi tiết hoạt động',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
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
                                if (result != null) {
                                  setState(() {
                                    _activityTitle = result['title'] as String;
                                    _deadline = result['deadline'] as String;
                                    _description = result['description'] as String;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E8EFF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Chỉnh sửa',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                    ),
                    child: Text(
                      'Hạn nộp: $_deadline',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tiến độ',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              '$submittedStudents/$totalStudents',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalStudents > 0 ? submittedStudents / totalStudents : 0,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            color: const Color(0xFF2E8EFF),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$percentage% sinh viên đã hoàn thành',
                          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  const Text(
                    'Danh sách bài nộp',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),

                  ...List.generate(_submissionsList.length, (index) {
                    final submission = _submissionsList[index];
                    final isSubmitted = submission['submitted'] as bool;
                    final hasScore = submission['score'] != null;

                    return GestureDetector(
                      onTap: () {
                        if (isSubmitted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SubmissionDetailScreen(
                                studentName: submission['name'],
                                submittedTime: submission['time'],
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sinh viên chưa nộp bài!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isSubmitted ? const Color(0xFF2E8EFF).withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.06),
                              radius: 18,
                              child: Icon(
                                isSubmitted ? Icons.check_circle_outline : Icons.pending_outlined,
                                color: isSubmitted ? const Color(0xFF2E8EFF) : Colors.white24,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    submission['name'],
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isSubmitted ? 'Nộp lúc: ${submission['time']}' : 'Chưa nộp bài',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSubmitted ? Colors.white54 : Colors.redAccent.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSubmitted) ...[
                              if (hasScore) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5A57FF).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${submission['score']} đ',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF8F8DFF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              ElevatedButton(
                                onPressed: () => _showGradeDialog(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5A57FF),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  hasScore ? 'Sửa' : 'Chấm',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ] else ...[
                              const Text(
                                '-',
                                style: TextStyle(color: Colors.white24, fontSize: 16),
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
