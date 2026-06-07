import 'package:flutter/material.dart';
import '../submission_detail_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentName;
  final String studentEmail;
  final int submissionsCount;
  final int progressPercentage;

  const StudentDetailScreen({
    super.key,
    required this.studentName,
    required this.studentEmail,
    required this.submissionsCount,
    required this.progressPercentage,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final List<Map<String, dynamic>> _activitiesList = [
    {
      'title': 'Thực hành Lab 1',
      'date': '19/03/2026',
      'status': 'Đã được đánh giá',
      'statusColor': Color(0xFF22C55E),
      'score': 9.0,
      'submitted': true,
    },
    {
      'title': 'Thực hành Lab 2',
      'date': '22/03/2026',
      'status': 'Chưa chấm',
      'statusColor': const Color(0xFF7EC07E),
      'score': null,
      'submitted': true,
    },
    {
      'title': 'Thực hành Lab 3',
      'date': '-',
      'status': 'Chưa nộp',
      'statusColor': Colors.redAccent,
      'score': null,
      'submitted': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Determine completed/total activities dynamically
    final completedCount = _activitiesList.where((a) => a['submitted'] as bool).length;
    final totalCount = _activitiesList.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Blue Back Button matching mockup
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7EC07E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Chi tiết sinh viên',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: [
                  // Student name & email identity text
                  Text(
                    widget.studentName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.studentEmail,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),

                  // Student progress card matching mockup
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tiến độ',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              '$completedCount/$totalCount',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalCount > 0 ? completedCount / totalCount : 0,
                            backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.08),
                            color: const Color(0xFF7EC07E),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.progressPercentage}% hoạt động đã được hoàn thành',
                          style: TextStyle(fontSize: 11, color: const Color(0xFF0F172A).withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Danh sách bài nộp',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),

                  // Submission list
                  ..._activitiesList.map((activity) {
                    final bool isSubmitted = activity['submitted'] as bool;
                    final Color statusColor = activity['statusColor'] as Color;

                    return GestureDetector(
                      onTap: () {
                        if (isSubmitted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SubmissionDetailScreen(
                                studentName: widget.studentName,
                                submittedTime: activity['date'],
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sinh viên chưa nộp bài hoạt động này!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.04)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity['title'],
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isSubmitted ? 'Nộp ngày: ${activity['date']}' : 'Chưa nộp bài',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                activity['status'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
