import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../student_class_detail_screen.dart';
import '../student_activity_detail_screen.dart';

class StudentDashboardTab extends StatelessWidget {
  final List<Map<String, dynamic>> myClasses;
  final VoidCallback onJoinClassPressed;
  final ValueChanged<int> onTabTapped;

  const StudentDashboardTab({
    super.key,
    required this.myClasses,
    required this.onJoinClassPressed,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Custom Header App Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => onTabTapped(4), // Quick jump to Profile tab
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF7EC07E),
                        child: Text(
                          user?.fullName.split(' ').last.substring(0, 1).toUpperCase() ?? 'SV',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, ${user?.fullName ?? "Nguyễn Văn A"} !',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bạn có 3 deadline',
                          style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Button Tham gia lớp học
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ElevatedButton.icon(
              onPressed: onJoinClassPressed,
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: const Text(
                'Tham gia lớp học',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7EC07E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),

        // Deadline sắp tới header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 28.0, bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Deadline sắp tới',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Deadline Card (Tapping redirects to activity details screen)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentActivityDetailScreen(
                        activity: {
                          'id': 'act_1',
                          'title': 'Bài tập lập trình Dart',
                          'type': 'Trước buổi học',
                          'deadline': 'Hạn: Còn 2 ngày',
                          'status': 'Chưa làm',
                          'description': 'Đọc kỹ slide bài 1, thực hiện các bài lab giới thiệu về Dart cơ bản, hướng đối tượng OOP và lập trình bất đồng bộ (Future/Stream). Nộp link Github repository chứa bài làm.',
                          'evidence': '',
                          'submissionTime': '',
                        },
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.assignment_late_outlined, color: Colors.redAccent, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bài tập lập trình Dart',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Thực hiện các bài lab',
                              style: TextStyle(
                                color: const Color(0xFF0F172A).withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Còn 2 ngày',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Lớp học của bạn header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 28.0, bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lớp học của bạn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: () => onTabTapped(1), // Jump to Classes tab
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: Color(0xFF7EC07E),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // List of up to 3 classes
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = myClasses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        final targetIndex = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentClassDetailScreen(
                              classCodeWithName: '${item['classCode']} - SE1904',
                              className: item['className'] ?? '',
                              instructor: item['instructor'] ?? '',
                              semester: item['semester'] ?? 'SU26',
                            ),
                          ),
                        );
                        if (targetIndex != null && targetIndex is int) {
                          onTabTapped(targetIndex);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7EC07E).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.school, color: Color(0xFF7EC07E), size: 22),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['classCode'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['instructor'] ?? '',
                                    style: TextStyle(
                                      color: const Color(0xFF0F172A).withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['nextSession'] ?? '',
                                    style: TextStyle(
                                      color: const Color(0xFF0F172A).withOpacity(0.4),
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: myClasses.length > 3 ? 3 : myClasses.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 30),
        ),
      ],
    );
  }
}
