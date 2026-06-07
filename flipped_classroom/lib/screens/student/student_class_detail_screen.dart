import 'package:flutter/material.dart';
import 'student_activity_detail_screen.dart';
import 'student_project_detail_screen.dart';
import 'student_milestone_detail_screen.dart';
import 'student_peer_review_screen.dart';

class StudentClassDetailScreen extends StatefulWidget {
  final String classCodeWithName;
  final String className;
  final String instructor;
  final String semester;

  const StudentClassDetailScreen({
    super.key,
    required this.classCodeWithName,
    required this.className,
    required this.instructor,
    required this.semester,
  });

  @override
  State<StudentClassDetailScreen> createState() => _StudentClassDetailScreenState();
}

class _StudentClassDetailScreenState extends State<StudentClassDetailScreen> {
  int _activeTab = 0; // 0: Hoạt động, 1: Tài liệu, 2: Dự án
  int _activeSubFilter = 0; // 0: Trước buổi học, 1: Trong buổi học

  // Mock list of activities
  late List<Map<String, dynamic>> _activities;

  @override
  void initState() {
    super.initState();
    _activities = [
      {
        'id': 'act_1',
        'title': 'Bài tập buổi 5: Thực hiện các bài lab',
        'type': 'Trước buổi học',
        'deadline': 'Hạn: 29/05/2026',
        'status': 'Chưa làm',
        'description': 'Đọc kỹ slide bài 5 và thực hiện các bài lab 1, 2, 3 trong tài liệu đính kèm. Chuẩn bị mã nguồn Github để chạy thử nghiệm trên lớp.',
        'evidence': '',
        'submissionTime': '',
      },
      {
        'id': 'act_2',
        'title': 'Bài tập buổi 1: Tìm hiểu về Dart',
        'type': 'Trước buổi học',
        'deadline': 'Hạn: 10/05/2026',
        'status': 'Đã làm',
        'description': 'Làm quen với cú pháp Dart cơ bản: biến, hàm, class, kế thừa, asynchronous programming (Future, Stream). Nộp link Github repository chứa bài tập.',
        'evidence': 'https://github.com/huynguyen/dart-prm-intro',
        'submissionTime': 'Nộp lúc: 09/05/2026 15:45',
      },
      {
        'id': 'act_3',
        'title': 'Thực hành buổi 6: Flutter Widget Layout',
        'type': 'Trong buổi học',
        'deadline': 'Hạn: 12/06/2026',
        'status': 'Chưa làm',
        'description': 'Thực hành thiết kế giao diện phức tạp bằng Row, Column, Stack, ListView. Thực hiện căn chỉnh giao diện Responsive cho các kích thước màn hình khác nhau.',
        'evidence': '',
        'submissionTime': '',
      },
      {
        'id': 'act_4',
        'title': 'Trắc nghiệm bài 3: State Management',
        'type': 'Trong buổi học',
        'deadline': 'Hạn: 25/05/2026',
        'status': 'Đã làm',
        'description': 'Hoàn thành bài kiểm tra trắc nghiệm nhanh 15 câu về cách quản lý trạng thái trong Flutter (setState, Provider, InheritedWidget).',
        'evidence': 'Kết quả: 15/15 câu đúng. Hoàn thành trực tuyến.',
        'submissionTime': 'Nộp lúc: 24/05/2026 21:10',
      },
    ];
  }

  // Mock list of materials
  final List<Map<String, dynamic>> _materials = [
    {
      'title': 'Syllabus môn học PRM393',
      'type': 'pdf',
      'size': '1.2 MB',
      'date': 'Đăng ngày: 15/05/2026',
    },
    {
      'title': 'Slide 1: Giới thiệu môn học & Dart cơ bản',
      'type': 'pdf',
      'size': '2.4 MB',
      'date': 'Đăng ngày: 16/05/2026',
    },
    {
      'title': 'Slide 2: Flutter Widgets & Giao diện Responsive',
      'type': 'pdf',
      'size': '4.1 MB',
      'date': 'Đăng ngày: 22/05/2026',
    },
    {
      'title': 'Slide 3: State Management & Flutter Architecture',
      'type': 'pdf',
      'size': '3.8 MB',
      'date': 'Đăng ngày: 28/05/2026',
    },
    {
      'title': 'Video Record: Buổi học 1 - Hướng dẫn cài đặt môi trường Flutter',
      'type': 'video',
      'duration': '1h 45m',
      'date': 'Đăng ngày: 17/05/2026',
    },
  ];

  // Mock project details
  final Map<String, dynamic> _projectInfo = {
    'groupName': 'Nhóm 1',
    'projectName': 'Ứng dụng quản lý lớp học đảo ngược (Flipped Classroom)',
    'members': [
      {'name': 'Nguyễn Văn A', 'role': 'Trưởng nhóm'},
      {'name': 'Trần Thị B', 'role': 'Thành viên'},
      {'name': 'Lê Văn C', 'role': 'Thành viên'},
      {'name': 'Phạm Văn D', 'role': 'Thành viên'},
    ],
    'milestones': [
      {
        'title': 'Milestone 1: Wireframe & Database Design',
        'dueDate': 'Hạn chót: Đã nộp (01/06/2026)',
        'progress': 1.0,
        'status': 'Đã hoàn thành',
        'color': Colors.greenAccent,
      },
      {
        'title': 'Milestone 2: MVP Front-end & Auth',
        'dueDate': 'Hạn chót: 15/06/2026',
        'progress': 0.6,
        'status': 'Đang thực hiện',
        'color': Colors.amberAccent,
      },
      {
        'title': 'Milestone 3: Final Submission & Demo',
        'dueDate': 'Hạn chót: 30/06/2026',
        'progress': 0.0,
        'status': 'Chưa bắt đầu',
        'color': Colors.white24,
      },
    ]
  };

  void _onBottomNavTapped(int index) {
    // Return selected index to Home Screen to change index
    Navigator.pop(context, index);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.classCodeWithName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18),
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
            // Top Tab Navigation Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _buildTabButton(0, 'hoạt động')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTabButton(1, 'tài liệu')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTabButton(2, 'dự án')),
                ],
              ),
            ),
            
            // Sub-filters for Activity Tab
            if (_activeTab == 0) _buildSubFilters(),

            // Main Content Area
            Expanded(
              child: IndexedStack(
                index: _activeTab,
                children: [
                  _buildActivitiesContent(),
                  _buildMaterialsContent(),
                  _buildProjectsContent(),
                ],
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
          currentIndex: 1, // Highlight 'Lớp học' tab as we are in Class details
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

  Widget _buildTabButton(int index, String label) {
    final isActive = _activeTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF7EC07E).withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: const Color(0xFF7EC07E).withOpacity(0.3), width: 1)
              : Border.all(color: Colors.transparent, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFF7EC07E) : const Color(0xFF0F172A).withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Row(
        children: [
          _buildSubFilterButton(0, 'Trước buổi học'),
          const SizedBox(width: 12),
          _buildSubFilterButton(1, 'Trong buổi học'),
        ],
      ),
    );
  }

  Widget _buildSubFilterButton(int index, String label) {
    final isActive = _activeSubFilter == index;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _activeSubFilter = index;
          });
        }
      },
      selectedColor: const Color(0xFF7EC07E),
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: isActive ? Colors.white : const Color(0xFF0F172A).withOpacity(0.6),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }

  // TAB 0 CONTENT: ACTIVITIES
  Widget _buildActivitiesContent() {
    final subFilterType = _activeSubFilter == 0 ? 'Trước buổi học' : 'Trong buổi học';
    final filteredList = _activities.where((act) => act['type'] == subFilterType).toList();

    if (filteredList.isEmpty) {
      return const Center(
        child: Text(
          'Không có hoạt động nào!',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final activity = filteredList[index];
        final isDone = activity['status'] == 'Đã làm';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
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
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentActivityDetailScreen(activity: activity),
                  ),
                );
                
                if (result != null && result is Map<String, dynamic>) {
                  setState(() {
                    activity['status'] = result['status'];
                    activity['evidenceList'] = result['evidenceList'];
                    activity['comments'] = result['comments'];
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Info Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          activity['type'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A).withOpacity(0.4),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFF7EC07E).withOpacity(0.12)
                                : Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            activity['status'] ?? 'Chưa làm',
                            style: TextStyle(
                              color: isDone ? const Color(0xFF7EC07E) : Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text(
                      activity['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: const Color(0xFF0F172A).withOpacity(0.04), height: 1),
                    const SizedBox(height: 12),
                    // Deadline Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 12, color: const Color(0xFF0F172A).withOpacity(0.4)),
                            const SizedBox(width: 6),
                            Text(
                              activity['deadline'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF0F172A).withOpacity(0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.arrow_forward_ios, size: 12, color: const Color(0xFF0F172A).withOpacity(0.3)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // TAB 1 CONTENT: MATERIALS
  Widget _buildMaterialsContent() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _materials.length,
      itemBuilder: (context, index) {
        final doc = _materials[index];
        final isPdf = doc['type'] == 'pdf';
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: const Color(0xFF0F172A).withOpacity(0.05)),
          ),
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isPdf
                  ? Colors.redAccent.withOpacity(0.1)
                  : const Color(0xFF7EC07E).withOpacity(0.1),
              radius: 20,
              child: Icon(
                isPdf ? Icons.picture_as_pdf_outlined : Icons.play_circle_outline,
                color: isPdf ? Colors.redAccent : const Color(0xFF7EC07E),
                size: 22,
              ),
            ),
            title: Text(
              doc['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '${doc['size'] ?? doc['duration'] ?? ''} • ${doc['date']}',
                style: TextStyle(fontSize: 12, color: const Color(0xFF0F172A).withOpacity(0.4)),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download_for_offline_outlined, color: Color(0xFF7EC07E)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đang tải xuống: ${doc['title']}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // TAB 2 CONTENT: PROJECTS
  Widget _buildProjectsContent() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Group Header
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () async {
              final targetIndex = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentProjectDetailScreen(
                    project: {
                      'title': _projectInfo['projectName'] ?? 'App lớp học đảo ngược',
                      'projectName': _projectInfo['projectName'] ?? 'App lớp học đảo ngược',
                      'membersList': (_projectInfo['members'] as List)
                          .map((m) => m['name'] as String)
                          .toList(),
                    },
                  ),
                ),
              );
              if (targetIndex != null && targetIndex is int) {
                _onBottomNavTapped(targetIndex);
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
                      Text(
                        _projectInfo['groupName'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7EC07E),
                        ),
                      ),
                      const Icon(Icons.group, color: Color(0xFF7EC07E), size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _projectInfo['projectName'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Thành viên:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  ...(_projectInfo['members'] as List).map((member) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: Color(0xFF7EC07E), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            member['name'] ?? '',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${member['role']})',
                            style: TextStyle(fontSize: 11, color: const Color(0xFF0F172A).withOpacity(0.4)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentPeerReviewScreen(
                  classCode: widget.classCodeWithName.split(' - ').first,
                ),
              ),
            );
          },
          icon: const Icon(Icons.rate_review, color: Colors.white, size: 18),
          label: const Text(
            'Đánh giá chéo nhóm khác',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7EC07E),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Mốc đánh giá dự án (Milestones)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),

        ...(_projectInfo['milestones'] as List).map((milestone) {
          final double progress = milestone['progress'] ?? 0.0;
          final statusColor = milestone['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentMilestoneDetailScreen(
                      milestone: milestone,
                      project: {
                        'title': _projectInfo['projectName'] ?? 'App lớp học đảo ngược',
                        'projectName': _projectInfo['projectName'] ?? 'App lớp học đảo ngược',
                        'membersList': (_projectInfo['members'] as List)
                            .map((m) => m['name'] as String)
                            .toList(),
                      },
                    ),
                  ),
                );
                
                if (result != null && result is Map<String, dynamic>) {
                  setState(() {
                    milestone['status'] = result['status'];
                    milestone['progress'] = result['progress'];
                    milestone['tasks'] = result['tasks'];
                    milestone['evidenceList'] = result['evidenceList'];
                    milestone['comments'] = result['comments'];
                    
                    if (result['status'] == 'Hoàn thành') {
                      milestone['color'] = Colors.greenAccent;
                    } else if (result['status'] == 'Chưa bắt đầu') {
                      milestone['color'] = Colors.white24;
                    } else {
                      milestone['color'] = Colors.amberAccent;
                    }
                  });
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
                        Expanded(
                          child: Text(
                            milestone['title'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          milestone['status'] ?? '',
                          style: TextStyle(
                            color: statusColor == Colors.white24 ? Colors.grey : statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      milestone['dueDate'] ?? '',
                      style: TextStyle(fontSize: 11, color: const Color(0xFF0F172A).withOpacity(0.4)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              backgroundColor: const Color(0xFF0F172A).withOpacity(0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                statusColor == Colors.white24 ? Colors.grey.shade300 : statusColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(fontSize: 11, color: const Color(0xFF0F172A).withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
