import 'package:flutter/material.dart';
import '../student_project_detail_screen.dart';

class StudentProjectsTab extends StatefulWidget {
  final ValueChanged<int> onTabTapped;

  const StudentProjectsTab({
    super.key,
    required this.onTabTapped,
  });

  @override
  State<StudentProjectsTab> createState() => _StudentProjectsTabState();
}

class _StudentProjectsTabState extends State<StudentProjectsTab> {
  // Mock projects list matching the diagram's "Tất cả dự án" screen description
  final List<Map<String, dynamic>> _projects = [
    {
      'title': 'Ứng dụng Flipped Classroom',
      'projectName': 'Ứng dụng Flipped Classroom',
      'classCodeWithName': 'PRM - SE1904',
      'subject': 'Lập trình Thiết bị Di động',
      'membersCount': 4,
      'membersList': ['Nguyễn Văn A', 'Trần Thị B', 'Lê Văn C', 'Phạm Văn D'],
      'progress': 0.8,
      'milestones': [
        {
          'title': 'Phân tích yêu cầu',
          'dueDate': 'Hạn: 10/05/2026',
          'status': 'Hoàn thành',
          'color': Color(0xFF7EC07E),
          'progress': 1.0,
          'description': 'Lấy yêu cầu từ khách hàng, phân tích sơ đồ luồng dữ liệu (Data Flow Diagram) và thiết kế cơ sở dữ liệu Entity Relationship Diagram (ERD).'
        },
        {
          'title': 'Thiết kế hệ thống',
          'dueDate': 'Hạn: 30/05/2026',
          'status': 'Đang thực hiện',
          'color': Colors.amberAccent,
          'progress': 0.6,
          'description': 'Vẽ wireframe chi tiết các màn hình (Mobile & Web), chuẩn bị kiến trúc thư mục Flutter, viết tài liệu đặc tả chức năng (SRS).'
        },
        {
          'title': 'Hoàn thiện MVP & Demo',
          'dueDate': 'Hạn: 20/06/2026',
          'status': 'Chưa bắt đầu',
          'color': Colors.grey,
          'progress': 0.0,
          'description': 'Hoàn thành phát triển các tính năng cốt lõi (Authentication, class details, evidence upload), chạy demo thử nghiệm.'
        }
      ]
    },
    {
      'title': 'Website Bán hàng Điện tử',
      'projectName': 'Website Bán hàng Điện tử',
      'classCodeWithName': 'PRW301 - SE1905',
      'subject': 'Thiết kế Web nâng cao',
      'membersCount': 3,
      'membersList': ['Nguyễn Văn A', 'Phạm Minh E', 'Lâm Thùy F'],
      'progress': 0.45,
      'milestones': [
        {
          'title': 'Thiết kế Mockup & DB',
          'dueDate': 'Hạn: 15/05/2026',
          'status': 'Hoàn thành',
          'color': Color(0xFF7EC07E),
          'progress': 1.0,
          'description': 'Thiết kế giao diện UI/UX trên Figma và tạo các bảng quan hệ cơ sở dữ liệu MySQL.'
        },
        {
          'title': 'Xây dựng API backend',
          'dueDate': 'Hạn: 10/06/2026',
          'status': 'Đang thực hiện',
          'color': Colors.amberAccent,
          'progress': 0.3,
          'description': 'Phát triển backend RESTful API sử dụng Node.js Express, kết nối cơ sở dữ liệu.'
        }
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Tất cả dự án',
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
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          itemCount: _projects.length,
          itemBuilder: (context, index) {
            final proj = _projects[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.01),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    final targetIndex = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentProjectDetailScreen(
                          project: proj,
                        ),
                      ),
                    );
                    if (targetIndex != null && targetIndex is int) {
                      widget.onTabTapped(targetIndex);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7EC07E).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                proj['classCodeWithName'] ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF7EC07E),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${proj['membersCount']} thành viên',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF0F172A).withOpacity(0.4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          proj['projectName'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          proj['subject'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF0F172A).withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tiến độ chung:',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF0F172A).withOpacity(0.4),
                              ),
                            ),
                            Text(
                              '${(proj['progress'] * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7EC07E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: proj['progress'],
                            minHeight: 6,
                            backgroundColor: const Color(0xFF0F172A).withOpacity(0.05),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7EC07E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
