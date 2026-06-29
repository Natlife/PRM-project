import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'components/student_list_screen.dart';
import 'components/activity_detail_screen.dart';
import 'edit_class_screen.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';
import 'create_activity_screen.dart';
import '../../services/classroom_service.dart';
import '../../services/activity_service.dart';
import '../../services/material_service.dart';
import '../../services/project_service.dart';

class ClassDetailScreen extends StatefulWidget {
  final int? classroomId;
  final String className;
  final String classCode;
  final int studentsCount;

  const ClassDetailScreen({
    super.key,
    this.classroomId,
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
  late String _semester;
  late String _description;
  bool _isLoading = false;
  List<Map<String, dynamic>> _rawSchedules = [];

  late List<Map<String, dynamic>> _activities;
  late List<Map<String, dynamic>> _documents;
  late List<Map<String, dynamic>> _projects;

  @override
  void initState() {
    super.initState();
    _className = widget.className;
    _classCode = widget.classCode;
    _semester = 'SU26';
    _description = 'Lớp học Flipped Classroom dành cho sinh viên chuyên ngành';
    _schedules = [];
    _activities = [];
    _documents = [];
    _projects = [];

    _fetchClassroomDetails();
    _fetchTabData();
  }

  String _formatDate(dynamic rawValue) {
    if (rawValue == null) {
      return '';
    }
    final raw = rawValue.toString().split('T').first;
    final parts = raw.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return raw;
  }

  String _formatScheduleLabel(Map<String, dynamic> schedule) {
    final int dayNum = schedule['dayOfWeek'] ?? 0;
    final days = [
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];
    final dayStr = (dayNum >= 0 && dayNum < days.length)
        ? days[dayNum]
        : days.first;
    final slotLabel = schedule['slotLabel']?.toString() ?? 'Slot 1';

    String timeStr = '';
    final startTimeRaw = schedule['startTime'] as String?;
    final endTimeRaw = schedule['endTime'] as String?;
    if (startTimeRaw != null && endTimeRaw != null) {
      final startParts = startTimeRaw.split(':');
      final endParts = endTimeRaw.split(':');
      final startFormatted = startParts.length >= 2
          ? '${int.parse(startParts[0])}:${startParts[1]}'
          : startTimeRaw;
      final endFormatted = endParts.length >= 2
          ? '${int.parse(endParts[0])}:${endParts[1]}'
          : endTimeRaw;
      timeStr = ' ($startFormatted - $endFormatted)';
    }

    return '$dayStr: $slotLabel$timeStr';
  }

  String _formatMaterialSize(dynamic sizeBytes) {
    if (sizeBytes == null) {
      return 'Khong ro';
    }
    final bytes = sizeBytes is num
        ? sizeBytes.toDouble()
        : double.tryParse(sizeBytes.toString());
    if (bytes == null) {
      return 'Khong ro';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${bytes.toStringAsFixed(0)} B';
  }

  Map<String, dynamic> _normalizeProject(Map<String, dynamic> raw) {
    final members = List<Map<String, dynamic>>.from(raw['members'] ?? const []);
    final milestones = List<Map<String, dynamic>>.from(
      raw['milestones'] ?? const [],
    );
    final progress = milestones.isEmpty
        ? 0
        : milestones
                  .map((milestone) => milestone['progressPercent'] as num? ?? 0)
                  .fold<num>(0, (sum, item) => sum + item) /
              milestones.length;

    return {
      'id': raw['id'],
      'classroomId': raw['classroomId'] ?? widget.classroomId,
      'title': raw['projectName'] ?? raw['groupName'] ?? 'Du an',
      'projectName': raw['projectName'] ?? raw['groupName'] ?? 'Du an',
      'group': raw['groupName'] ?? 'Nhom',
      'groupName': raw['groupName'] ?? 'Nhom',
      'members': '${members.length} sinh vien',
      'membersList': members
          .map(
            (member) =>
                member['fullName'] ?? member['userName'] ?? 'Thanh vien',
          )
          .toList(),
      'membersData': members,
      'leader': raw['leader']?['fullName'],
      'leaderData': raw['leader'],
      'date': _formatDate(raw['createdAt']),
      'progress': '${progress.round()}%',
      'milestones': milestones,
    };
  }

  Future<void> _fetchClassroomDetails() async {
    if (widget.classroomId == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final detail = await ClassroomService().getTeacherClassroomDetail(
        widget.classroomId!,
      );
      setState(() {
        _className = detail['name'] ?? widget.className;
        _classCode = detail['code'] ?? widget.classCode;
        _semester = detail['semesterCode'] ?? 'SU26';
        _description =
            detail['description'] ??
            'Lớp học Flipped Classroom dành cho sinh viên chuyên ngành';

        _rawSchedules = List<Map<String, dynamic>>.from(
          detail['schedules'] ?? const [],
        );
        _schedules = _rawSchedules.map(_formatScheduleLabel).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading class details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTabData() async {
    if (widget.classroomId == null) return;
    try {
      final rawActs = await ActivityService().getTeacherActivities(
        widget.classroomId!,
      );
      final loaded = rawActs.map<Map<String, dynamic>>((act) {
        return {
          'id': act['id'],
          'title': act['title'] ?? 'Hoat dong',
          'description': act['description'] ?? '',
          'submissions': 'Xem danh sach nop bai',
          'date': _formatDate(act['dueAt']),
          'activityType': act['activityType'] ?? '',
          'status': act['status'] ?? '',
          'dueAt': act['dueAt'],
        };
      }).toList();

      List<Map<String, dynamic>> loadedMats = [];
      try {
        final rawMats = await MaterialService().getClassroomMaterials(
          widget.classroomId!,
        );
        loadedMats = rawMats.map<Map<String, dynamic>>((mat) {
          return {
            'id': mat['id'],
            'title': mat['title'] ?? '',
            'description': mat['description'] ?? '',
            'size': _formatMaterialSize(mat['sizeBytes']),
            'date': _formatDate(mat['publishedAt']),
            'fileName': mat['originalFileName'] ?? '',
            'materialType': mat['materialType'] ?? '',
            'fileUrl': mat['fileUrl'] ?? '',
          };
        }).toList();
      } catch (e) {
        debugPrint('Error loading materials: $e');
      }

      List<Map<String, dynamic>> loadedProjects = [];
      try {
        final rawProjects = await ProjectService().getClassroomProjectGroups(
          widget.classroomId!,
        );
        loadedProjects = rawProjects.map(_normalizeProject).toList();
      } catch (e) {
        debugPrint('Error loading projects: $e');
      }

      if (mounted) {
        setState(() {
          _activities = loaded;
          _documents = loadedMats;
          _projects = loadedProjects;
        });
      }
    } catch (e) {
      debugPrint('Error loading activities: \$e');
    }
  }

  Future<void> _handleCreateNew() async {
    if (_currentTab == 'Dự án') {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => CreateProjectScreen(
            fixedClassroomId: widget.classroomId,
            fixedClass: _className,
          ),
        ),
      );
      if (result != null) {
        if (!mounted) return;
        setState(() {
          _projects.insert(0, {
            'id': result['id'],
            'classroomId': widget.classroomId,
            'title': result['projectName'] ?? result['groupName'] ?? 'Du an',
            'projectName':
                result['projectName'] ?? result['groupName'] ?? 'Du an',
            'group': result['groupName'] ?? '',
            'groupName': result['groupName'] ?? '',
            'members':
                '${(result['members'] as List<dynamic>? ?? []).length} sinh vien',
            'membersList': (result['members'] as List<dynamic>? ?? [])
                .map(
                  (member) =>
                      member['fullName'] ?? member['userName'] ?? 'Thanh vien',
                )
                .toList(),
            'membersData': result['members'] ?? [],
            'leader': result['leader']?['fullName'],
            'leaderData': result['leader'],
            'date': '',
            'progress': '0%',
            'milestones': <Map<String, dynamic>>[],
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

    if (_currentTab == 'Hoạt động') {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => CreateActivityScreen(
            classroomId: widget.classroomId,
            availableClassrooms: [
              {
                'id': widget.classroomId,
                'className': _className,
                'code': _classCode,
              },
            ],
          ),
        ),
      );
      if (result != null) {
        if (!mounted) return;
        setState(() {
          _activities.insert(0, {
            'id': result['id'],
            'title': result['title'] as String,
            'description': result['description'] ?? '',
            'submissions': result['submissions'] ?? '0 người nộp',
            'date': result['date'] ?? 'Hôm nay',
            'activityType': result['activityType'] ?? '',
            'status': result['status'] ?? '',
            'className': result['className'] ?? _className,
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo thành công hoạt động mới!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (_currentTab == 'Tài liệu') {
      _showUploadMaterialSheet();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(
                      context,
                    ).pop({'className': _className, 'classCode': _classCode}),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(
                            0xFF0F172A,
                          ).withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF0F172A),
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Chi tiết lớp học',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
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
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final result =
                              await Navigator.push<Map<String, dynamic>>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditClassScreen(
                                    className: _className,
                                    classCode: _classCode,
                                    semester: _semester,
                                    description: _description,
                                    schedules: _rawSchedules,
                                  ),
                                ),
                              );
                          if (result != null) {
                            try {
                              final schedulesRequest =
                                  List<Map<String, dynamic>>.from(
                                    result['schedules'] ?? const [],
                                  );

                              if (widget.classroomId != null) {
                                await ClassroomService().updateClassroom(
                                  classroomId: widget.classroomId!,
                                  name: result['name'] as String? ?? '',
                                  description:
                                      result['description'] as String? ?? '',
                                  semesterCode:
                                      result['semesterCode'] as String? ??
                                      'SU26',
                                  schedules: schedulesRequest,
                                );
                                await _fetchClassroomDetails();
                                await _fetchTabData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Cập nhật lớp học thành công!',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Color(0xFF7EC07E),
                                  ),
                                );
                              } else {
                                setState(() {
                                  _className = result['name'] as String;
                                  _description =
                                      result['description'] as String? ??
                                      _description;
                                  _semester =
                                      result['semesterCode'] as String? ??
                                      _semester;
                                  _rawSchedules = schedulesRequest;
                                  _schedules = _rawSchedules
                                      .map(_formatScheduleLabel)
                                      .toList();
                                });
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi cập nhật lớp học: $e'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7EC07E),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Chỉnh sửa lớp',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mã lớp học',
                              style: TextStyle(
                                fontSize: 11,
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _classCode,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.copy,
                            color: Color(0xFF7EC07E),
                            size: 20,
                          ),
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
                                  classroomId: widget.classroomId ?? 0,
                                  className: _className,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: 0.04),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Tổng sinh viên',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: const Color(
                                      0xFF0F172A,
                                    ).withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${widget.studentsCount}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Xem danh sách',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF7EC07E),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(
                                0xFF0F172A,
                              ).withValues(alpha: 0.04),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Học kỳ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(
                                    0xFF0F172A,
                                  ).withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _semester,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kỳ hiện tại',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: const Color(
                                    0xFF0F172A,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7EC07E),
                        ),
                      ),
                    )
                  else
                    ..._schedules.map((s) => _buildScheduleBox(s)),
                  const SizedBox(height: 22),

                  _buildInnerTabs(),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Danh sách ${_currentTab.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A).withValues(alpha: 0.5),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _handleCreateNew,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7EC07E),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(
                          _currentTab == 'Tài liệu' ? Icons.upload : Icons.add,
                          size: 14,
                          color: const Color(0xFF0F172A),
                        ),
                        label: Text(
                          _currentTab == 'Tài liệu'
                              ? 'Tải lên'
                              : _currentTab == 'Dự án'
                              ? 'Thêm dự án'
                              : 'Tạo mới',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
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
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
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
          backgroundColor: const Color(0xFFFFFFFF),
          selectedItemColor: const Color(0xFF7EC07E),
          unselectedItemColor: const Color(0xFF0F172A).withValues(alpha: 0.4),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
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
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
        ),
      ),
      child: Text(
        scheduleText,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.bold,
        ),
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
              color: isActive
                  ? const Color(0xFF7EC07E)
                  : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? Colors.transparent
                    : const Color(0xFF0F172A).withValues(alpha: 0.04),
              ),
            ),
            child: Text(
              tab,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive
                    ? Colors.white
                    : const Color(0xFF0F172A).withValues(alpha: 0.5),
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
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Bạn có chắc chắn muốn xóa?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Tài liệu này sẽ bị xóa vĩnh viễn khỏi lớp học.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF334155), fontSize: 13),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                try {
                  final materialId = doc['id'] as int?;
                  if (materialId != null) {
                    await MaterialService().deleteMaterial(materialId);
                  }
                  if (!mounted) return;
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
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Khong the xoa tai lieu: $e'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUploadMaterialSheet() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'DOCUMENT';

    List<int>? fileBytes;
    String? fileName;

    StateSetter? sheetState;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            sheetState = setSheetState;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tải lên tài liệu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF0F172A),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tiêu đề *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: titleController,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nhập tiêu đề tài liệu',
                        hintStyle: TextStyle(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                        ),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Tiêu đề là bắt buộc';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mô tả',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: descController,
                      maxLines: 3,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nhập mô tả chi tiết tài liệu (tùy chọn)',
                        hintStyle: TextStyle(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                        ),
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Loại tài liệu *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      dropdownColor: const Color(0xFFFFFFFF),
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        fillColor: const Color(0xFFF8FAFC),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'DOCUMENT',
                          child: Text('Tài liệu (Document)'),
                        ),
                        DropdownMenuItem(value: 'VIDEO', child: Text('Video')),
                        DropdownMenuItem(
                          value: 'SLIDE',
                          child: Text('Slide bài giảng'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() {
                            selectedType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Tập tin tài liệu *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final pickerResult = await FilePicker.pickFiles(
                                type: FileType.any,
                                withData: true,
                              );
                              if (pickerResult != null &&
                                  pickerResult.files.isNotEmpty) {
                                final file = pickerResult.files.first;
                                setSheetState(() {
                                  fileBytes = file.bytes;
                                  fileName = file.name;
                                });
                              }
                            } catch (e) {
                              debugPrint('Error picking file: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF7EC07E,
                            ).withValues(alpha: 0.15),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.attach_file,
                            color: Color(0xFF7EC07E),
                            size: 16,
                          ),
                          label: const Text(
                            'Chọn tệp tin',
                            style: TextStyle(
                              color: Color(0xFF7EC07E),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            fileName ?? 'Chưa chọn tệp tin nào',
                            style: TextStyle(
                              fontSize: 12,
                              color: fileName != null
                                  ? const Color(0xFF0F172A)
                                  : const Color(
                                      0xFF0F172A,
                                    ).withValues(alpha: 0.4),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isUploading
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEC4899),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Hủy',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isUploading
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    if (fileBytes == null || fileName == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Vui lòng chọn một tệp tin.',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }
                                    setSheetState(() {
                                      isUploading = true;
                                    });
                                    try {
                                      final result = await MaterialService()
                                          .uploadMaterial(
                                            classroomId: widget.classroomId!,
                                            title: titleController.text.trim(),
                                            description: descController.text
                                                .trim(),
                                            materialType: selectedType,
                                            fileBytes: fileBytes!,
                                            fileName: fileName!,
                                          );
                                      if (!mounted) return;

                                      setState(() {
                                        _documents.insert(0, {
                                          'id': result['id'],
                                          'title': result['title'] ?? '',
                                          'description':
                                              result['description'] ?? '',
                                          'size': _formatMaterialSize(
                                            result['sizeBytes'],
                                          ),
                                          'date': _formatDate(
                                            result['publishedAt'],
                                          ),
                                          'fileName':
                                              result['originalFileName'] ?? '',
                                          'materialType':
                                              result['materialType'] ?? '',
                                          'fileUrl': result['fileUrl'] ?? '',
                                        });
                                      });

                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Tải lên tài liệu thành công!',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } catch (e) {
                                      setSheetState(() {
                                        isUploading = false;
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Lỗi tải lên tài liệu: $e',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: isUploading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Lưu',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildTabContent() {
    if (_currentTab == 'Hoạt động') {
      if (_activities.isEmpty) {
        return const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Chua co hoat dong nao.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          ),
        ];
      }
      return _activities.map((act) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityDetailScreen(
                  activityId: act['id'] as int?,
                  activityTitle: act['title'],
                  deadline: act['date'],
                  submissions: act['submissions'],
                  description: act['description'] ?? '',
                  className: _className,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act['title'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      act['submissions'],
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF0F172A).withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF7EC07E,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFF7EC07E,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _className,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7EC07E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      act['date'],
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF0F172A).withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList();
    } else if (_currentTab == 'Tài liệu') {
      if (_documents.isEmpty) {
        return const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Chua co tai lieu nao.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          ),
        ];
      }
      return _documents.map((doc) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.insert_drive_file,
                color: Color(0xFF7EC07E),
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${doc['size']} • ${doc['date']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF0F172A).withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.download_for_offline,
                  color: Color(0xFF7EC07E),
                  size: 22,
                ),
                onPressed: () async {
                  final urlStr = doc['fileUrl'] ?? '';
                  if (urlStr.isNotEmpty) {
                    final uri = Uri.parse(urlStr);
                    try {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Không thể tải xuống/mở: $urlStr'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Không thể mở tài liệu: $e'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Tài liệu không có đường dẫn trực tuyến.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEC4899),
                  size: 22,
                ),
                onPressed: () => _handleDeleteDocument(doc),
              ),
            ],
          ),
        );
      }).toList();
    } else {
      if (_projects.isEmpty) {
        return const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Chua co du an nao.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          ),
        ];
      }
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
                proj['progress'] =
                    '${(updatedProj['progress'] * 100).toInt()}%';
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proj['title'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      group,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF0F172A).withValues(alpha: 0.4),
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF0F172A).withValues(alpha: 0.4),
                      ),
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
