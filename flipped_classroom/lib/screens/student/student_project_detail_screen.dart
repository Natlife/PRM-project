import 'package:flutter/material.dart';
import 'student_milestone_detail_screen.dart';

class StudentProjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const StudentProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  State<StudentProjectDetailScreen> createState() => _StudentProjectDetailScreenState();
}

class _StudentProjectDetailScreenState extends State<StudentProjectDetailScreen> {
  late List<Map<String, dynamic>> _milestones;

  @override
  void initState() {
    super.initState();
    // Initialize milestones from project details, or use default list matching diagram
    _milestones = widget.project['milestones'] != null
        ? List<Map<String, dynamic>>.from(widget.project['milestones'])
        : [
            {
              'title': 'Phân tích yêu cầu',
              'dueDate': 'Hạn: 10/5/2026',
              'status': 'Hoàn thành',
              'color': Colors.greenAccent,
              'progress': 1.0,
              'description': 'Lấy yêu cầu từ khách hàng, phân tích sơ đồ luồng dữ liệu (Data Flow Diagram) và thiết kế cơ sở dữ liệu Entity Relationship Diagram (ERD).'
            },
            {
              'title': 'Thiết kế hệ thống',
              'dueDate': 'Hạn: 30/5/2026',
              'status': 'Đang thực hiện',
              'color': Colors.amberAccent,
              'progress': 0.6,
              'description': 'Vẽ wireframe chi tiết các màn hình (Mobile & Web), chuẩn bị kiến trúc thư mục Flutter, viết tài liệu đặc tả chức năng (SRS).'
            },
          ];
  }

  void _onBottomNavTapped(int index) {
    Navigator.pop(context, index);
  }

  @override
  Widget build(BuildContext context) {
    // Get members from project state, default to Nguyễn Văn A & Nguyễn Thị B if empty
    final membersList = widget.project['membersList'] != null
        ? List<String>.from(widget.project['membersList'])
        : ['Nguyễn Văn A', 'Nguyễn Thị B'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 18),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Chi tiết dự án',
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Title
              Text(
                widget.project['title'] ?? widget.project['projectName'] ?? 'App lớp học đảo ngược',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),

              // Members card box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.01),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thành viên (${membersList.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Render member cards
                    ...membersList.map((memberName) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.1)),
                        ),
                        child: Center(
                          child: Text(
                            memberName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Milestone Header
              const Text(
                'Milestone',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              // Milestone list cards
              ..._milestones.map((milestone) {
                final String status = milestone['status'] ?? 'Chưa bắt đầu';
                final isCompleted = status == 'Hoàn thành';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.01),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentMilestoneDetailScreen(
                              milestone: milestone,
                              project: widget.project,
                            ),
                          ),
                        );
                        if (!context.mounted) return;
                        if (result != null) {
                          if (result is int) {
                            Navigator.pop(context, result);
                          } else if (result is Map<String, dynamic>) {
                            setState(() {
                              milestone['status'] = result['status'];
                              milestone['progress'] = result['progress'];
                              milestone['tasks'] = result['tasks'];
                              milestone['evidenceList'] = result['evidenceList'];
                              milestone['comments'] = result['comments'];
                            });
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  milestone['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted
                                        ? const Color(0xFF7EC07E)
                                        : const Color(0xFF0F172A).withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              milestone['dueDate'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF0F172A).withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
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
