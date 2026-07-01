import 'package:flutter/material.dart';
import '../student_event_detail_screen.dart';

class StudentEventsTab extends StatefulWidget {
  final ValueChanged<int> onTabTapped;

  const StudentEventsTab({
    super.key,
    required this.onTabTapped,
  });

  @override
  State<StudentEventsTab> createState() => _StudentEventsTabState();
}

class _StudentEventsTabState extends State<StudentEventsTab> {
  final List<Map<String, dynamic>> _events = [
    {
      'id': '1',
      'title': 'Thuyết trình Dự án STEM',
      'classCode': 'PRM - SE1904',
      'date': '25/6/2026',
      'time': '09:00 - 11:30',
      'location': 'Phòng 402, Tòa nhà Gamma',
      'instructor': 'GV. Vũ Trường Giang',
      'description': 'Thuyết trình và demo sản phẩm dự án STEM cuối kỳ môn Lập trình Mobile.',
      'status': 'Sắp diễn ra',
      'statusColor': Colors.amber[800],
    },
    {
      'id': '2',
      'title': 'Bài tập chuẩn bị bài 5: Flutter State Management',
      'classCode': 'PRM - SE1904',
      'date': '28/6/2026',
      'time': 'Trước 23:59',
      'location': 'Nộp trên hệ thống Flipped Classroom',
      'instructor': 'GV. Vũ Trường Giang',
      'description': 'Xem slide và chuẩn bị code ví dụ về Provider/Bloc.',
      'status': 'Chưa làm',
      'statusColor': Colors.redAccent,
    },
    {
      'id': '3',
      'title': 'Báo cáo tiến độ Milestone 2',
      'classCode': 'PRW301 - SE1905',
      'date': '02/07/2026',
      'time': '10:00 - 12:20',
      'location': 'Phòng 205, Tòa nhà Alpha',
      'instructor': 'GV. Trần Thị B',
      'description': 'Báo cáo tiến độ hoàn thiện UI/UX và API của dự án Web.',
      'status': 'Đang diễn ra',
      'statusColor': Colors.green,
    },
    {
      'id': '4',
      'title': 'Hạn nộp báo cáo nghiên cứu công nghệ',
      'classCode': 'FLC101 - SE1906',
      'date': '04/07/2026',
      'time': 'Trước 23:59',
      'location': 'Nộp trên hệ thống Flipped Classroom',
      'instructor': 'GV. Hoàng Văn C',
      'description': 'Nộp báo cáo nghiên cứu công nghệ Front-end phục vụ cho dự án môn học.',
      'status': 'Hạn chót',
      'statusColor': Colors.red,
    },
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0, bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tất cả sự kiện',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Xem và quản lý các sự kiện lớp học, lịch báo cáo và nộp bài',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF0F172A).withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Event List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = _events[index];
                    final Color statusColor = event['statusColor'] as Color;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.06)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentEventDetailScreen(event: event),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Event name
                                Text(
                                  event['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Class & Course Name
                                Text(
                                  event['classCode'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF0F172A).withOpacity(0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Date of Event
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      event['date'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: const Color(0xFF0F172A).withOpacity(0.4),
                                      ),
                                    ),
                                    
                                    // Status Badge / Text
                                    Text(
                                      event['status'],
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _events.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 30),
            ),
          ],
        ),
      ),
    );
  }
}
