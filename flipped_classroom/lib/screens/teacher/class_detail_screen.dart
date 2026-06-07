import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'components/student_list_screen.dart';
import 'components/activity_detail_screen.dart';
import 'edit_class_screen.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  final String className;
  final String classCode;
  final int studentsCount;

  const ClassDetailScreen({
    super.key,
    required this.className,
    required this.classCode,
    required this.studentsCount,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  String _currentTab = 'Hoạt động';
  
  late String _className;
  late String _classCode;
  late List<String> _schedules;

  late List<Map<String, dynamic>> _activities;
  late List<Map<String, dynamic>> _documents;
  late List<Map<String, dynamic>> _projects;

  @override
  void initState() {
    super.initState();
    _className = widget.className;
    _classCode = widget.classCode;
    _schedules = [
      'Thứ 2: Slot 1 (7:30 - 9:50)',
      'Thứ 5: Slot 2 (10:00 - 12:20)',
    ];

    _activities = [
      {
        'title': 'Chuẩn bị bài 4: Flutter Widget cơ bản',
        'submissions': '0/45 người nộp',
        'date': '19/03/2026',
      },
      {
        'title': 'Báo cáo Milestone 1: Phân tích yêu cầu',
        'submissions': '42/45 người nộp',
        'date': '15/03/2026',
      },
    ];

    _documents = [
      {
        'title': 'Slide 1: Giới thiệu môn học & Flutter SDK',
        'size': '2.4 MB',
        'date': '10/03/2026',
      },
      {
        'title': 'Tài liệu hướng dẫn cài đặt môi trường Android Studio',
        'size': '4.8 MB',
        'date': '11/03/2026',
      },
    ];

    _projects = [
      {
        'title': 'Nhóm 1: Hệ thống quản lý Flipped Classroom',
        'members': '4 thành viên',
        'progress': '80%',
      },
      {
        'title': 'Nhóm 2: Ứng dụng theo dõi sức khỏe Gymtelligent',
        'members': '3 thành viên',
        'progress': '65%',
      },
    ];
  }

  Future<void> _handleCreateNew() async {
    if (_currentTab == 'Dự án') {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => CreateProjectScreen(
            fixedClass: _className,
            availableClasses: [_classCode],
          ),
        ),
      );
      if (result != null) {
        if (!mounted) return;
        setState(() {
          _projects.insert(0, {
            'title': result['title'] as String,
            'members': result['members'] as String,
            'membersList': result['membersList'],
            'leader': result['leader'],
            'date': result['date'],
            'progress': '0%',
            'milestones': result['milestones'],
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo thành công dự án mới!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Tạo mới ${_currentTab.toLowerCase()}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nhập tiêu đề...',
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
                if (titleController.text.trim().isEmpty) return;
                setState(() {
                  final title = titleController.text.trim();
                  if (_currentTab == 'Hoạt động') {
                    _activities.insert(0, {
                      'title': title,
                      'submissions': '0/45 người nộp',
                      'date': 'Hôm nay',
                    });
                  } else if (_currentTab == 'Tài liệu') {
                    _documents.insert(0, {
                      'title': title,
                      'size': '1.2 MB',
                      'date': 'Hôm nay',
                    });
                  }
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã tạo thành công ${_currentTab.toLowerCase()} mới!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Tạo'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      'className': _className,
                      'classCode': _classCode,
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Chi tiết lớp học',
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
                    children: [
                      Expanded(
                        child: Text(
                          _className,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push<Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditClassScreen(
                                className: _className,
                                classCode: _classCode,
                                semester: 'SU26',
                                description: 'Lớp học Flipped Classroom dành cho sinh viên chuyên ngành',
                                schedules: _schedules,
                              ),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              _className = result['title'] as String;
                              _classCode = result['code'] as String;
                              if (result['schedules'] != null) {
                                _schedules = List<String>.from(result['schedules'] as Iterable);
                              }
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A57FF),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Chỉnh sửa lớp',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mã lớp học',
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _classCode,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Color(0xFF5A57FF), size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _classCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép mã lớp học!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentListScreen(
                                  className: _className,
                                  studentsCount: widget.studentsCount,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Tổng sinh viên',
                                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${widget.studentsCount}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Xem danh sách',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF8F8DFF), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Học kỳ',
                                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'HK1 2026',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kỳ hiện tại',
                                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.3)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  ..._schedules.map((s) => _buildScheduleBox(s)),
                  const SizedBox(height: 22),

                  _buildInnerTabs(),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Danh sách ${_currentTab.toLowerCase()}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      ElevatedButton.icon(
                        onPressed: _handleCreateNew,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A57FF),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(_currentTab == 'Tài liệu' ? Icons.upload : Icons.add, size: 14, color: Colors.white),
                        label: Text(
                          _currentTab == 'Tài liệu'
                              ? 'Tải lên'
                              : _currentTab == 'Dự án'
                                  ? 'Thêm dự án'
                                  : 'Tạo mới',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ..._buildTabContent(),

                  const SizedBox(height: 30),
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
              color: Colors.white.withValues(alpha: 0.06),
              width: 1.2,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: 1,
          onTap: (index) {
            Navigator.of(context).pop(index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1E293B),
          selectedItemColor: const Color(0xFF5A57FF),
          unselectedItemColor: Colors.white.withValues(alpha: 0.4),
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
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Hoạt động',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work),
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

  Widget _buildScheduleBox(String scheduleText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Text(
        scheduleText,
        style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInnerTabs() {
    final tabs = ['Hoạt động', 'Tài liệu', 'Dự án'];
    return Row(
      children: tabs.map((tab) {
        final isActive = _currentTab == tab;
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentTab = tab;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF5A57FF) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isActive ? Colors.transparent : Colors.white.withValues(alpha: 0.04)),
            ),
            child: Text(
              tab,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleDeleteDocument(Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Bạn có chắc chắn muốn xóa?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Tài liệu này sẽ bị xóa vĩnh viễn khỏi lớp học.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Hủy',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _documents.remove(doc);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa tài liệu "${doc['title']}"!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildTabContent() {
    if (_currentTab == 'Hoạt động') {
      return _activities.map((act) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityDetailScreen(
                  activityTitle: act['title'],
                  deadline: act['date'],
                  submissions: act['submissions'],
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act['title'],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      act['submissions'],
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    Text(
                      act['date'],
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList();
    } else if (_currentTab == 'Tài liệu') {
      return _documents.map((doc) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Row(
            children: [
              const Icon(Icons.insert_drive_file, color: Color(0xFFD946EF), size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc['title'],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${doc['size']} • ${doc['date']}',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_for_offline, color: Color(0xFF5A57FF), size: 22),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đang tải xuống "${doc['title']}"...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEC4899), size: 22),
                onPressed: () => _handleDeleteDocument(doc),
              ),
            ],
          ),
        );
      }).toList();
    } else {
      return _projects.map((proj) {
        final String group = proj['group'] ?? proj['groupName'] ?? 'Nhóm 1';
        final String date = proj['date'] ?? '10/8/2026';
        return GestureDetector(
          onTap: () async {
            final updatedProj = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (context) => ProjectDetailScreen(
                  project: proj,
                  availableClasses: [_classCode],
                ),
              ),
            );
            if (updatedProj != null) {
              setState(() {
                proj['title'] = updatedProj['title'];
                proj['group'] = updatedProj['group'];
                proj['groupName'] = updatedProj['groupName'];
                proj['date'] = updatedProj['date'];
                proj['members'] = updatedProj['members'];
                proj['membersList'] = updatedProj['membersList'];
                proj['leader'] = updatedProj['leader'];
                proj['milestones'] = updatedProj['milestones'];
                proj['progress'] = '${(updatedProj['progress'] * 100).toInt()}%';
              });
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proj['title'],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      group,
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    Text(
                      date,
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList();
    }
  }
}