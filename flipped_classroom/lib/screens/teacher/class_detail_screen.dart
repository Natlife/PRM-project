import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/activity_service.dart';
import '../../services/classroom_service.dart';
import '../../services/material_service.dart';
import '../../services/project_service.dart';
import 'components/activity_detail_screen.dart';
import 'components/student_list_screen.dart';
import 'create_activity_screen.dart';
import 'create_project_screen.dart';
import 'edit_class_screen.dart';
import 'project_detail_screen.dart';

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
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);

  String _currentTab = 'Hoạt động';

  late String _className;
  late String _classCode;
  late String _semester;
  late String _description;
  late List<String> _schedules;

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

    final String rawValueString = rawValue.toString().split('T').first;

    final List<String> parts = rawValueString.split('-');

    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }

    return rawValueString;
  }

  String _formatScheduleLabel(Map<String, dynamic> schedule) {
    final int dayNumber = schedule['dayOfWeek'] ?? 0;

    final List<String> days = [
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];

    final String dayLabel = dayNumber >= 0 && dayNumber < days.length
        ? days[dayNumber]
        : days.first;

    final String slotLabel = schedule['slotLabel']?.toString() ?? 'Slot 1';

    String timeLabel = '';

    final String? startTimeRaw = schedule['startTime'] as String?;

    final String? endTimeRaw = schedule['endTime'] as String?;

    if (startTimeRaw != null && endTimeRaw != null) {
      final List<String> startParts = startTimeRaw.split(':');

      final List<String> endParts = endTimeRaw.split(':');

      final String startFormatted = startParts.length >= 2
          ? '${int.parse(startParts[0])}:${startParts[1]}'
          : startTimeRaw;

      final String endFormatted = endParts.length >= 2
          ? '${int.parse(endParts[0])}:${endParts[1]}'
          : endTimeRaw;

      timeLabel = ' ($startFormatted - $endFormatted)';
    }

    return '$dayLabel: $slotLabel$timeLabel';
  }

  String _formatMaterialSize(dynamic sizeBytes) {
    if (sizeBytes == null) {
      return 'Không rõ';
    }

    final double? bytes = sizeBytes is num
        ? sizeBytes.toDouble()
        : double.tryParse(sizeBytes.toString());

    if (bytes == null) {
      return 'Không rõ';
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
    final List<Map<String, dynamic>> members = List<Map<String, dynamic>>.from(
      raw['members'] ?? const [],
    );

    final List<Map<String, dynamic>> milestones =
        List<Map<String, dynamic>>.from(raw['milestones'] ?? const []);

    final num progress = milestones.isEmpty
        ? 0
        : milestones
                  .map(
                    (Map<String, dynamic> milestone) =>
                        milestone['progressPercent'] as num? ?? 0,
                  )
                  .fold<num>(0, (num sum, num item) => sum + item) /
              milestones.length;

    return {
      'id': raw['id'],
      'classroomId': raw['classroomId'] ?? widget.classroomId,
      'title': raw['projectName'] ?? raw['groupName'] ?? 'Dự án',
      'projectName': raw['projectName'] ?? raw['groupName'] ?? 'Dự án',
      'group': raw['groupName'] ?? 'Nhóm',
      'groupName': raw['groupName'] ?? 'Nhóm',
      'members': '${members.length} sinh viên',
      'membersList': members
          .map(
            (Map<String, dynamic> member) =>
                member['fullName'] ?? member['userName'] ?? 'Thành viên',
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
    if (widget.classroomId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> detail = await ClassroomService()
          .getTeacherClassroomDetail(widget.classroomId!);

      if (!mounted) {
        return;
      }

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
    } catch (error) {
      debugPrint('Error loading class details: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTabData() async {
    if (widget.classroomId == null) {
      return;
    }

    try {
      final List<dynamic> rawActivities = await ActivityService()
          .getTeacherActivities(widget.classroomId!);

      final List<Map<String, dynamic>> loadedActivities = rawActivities
          .map<Map<String, dynamic>>((dynamic activity) {
            return {
              'id': activity['id'],
              'title': activity['title'] ?? 'Hoạt động',
              'description': activity['description'] ?? '',
              'submissions': 'Xem danh sách nộp bài',
              'date': _formatDate(activity['dueAt']),
              'activityType': activity['activityType'] ?? '',
              'status': activity['status'] ?? '',
              'dueAt': activity['dueAt'],
            };
          })
          .toList();

      List<Map<String, dynamic>> loadedMaterials = [];

      try {
        final List<dynamic> rawMaterials = await MaterialService()
            .getClassroomMaterials(widget.classroomId!);

        loadedMaterials = rawMaterials.map<Map<String, dynamic>>((
          dynamic material,
        ) {
          return {
            'id': material['id'],
            'title': material['title'] ?? '',
            'description': material['description'] ?? '',
            'size': _formatMaterialSize(material['sizeBytes']),
            'date': _formatDate(material['publishedAt']),
            'fileName': material['originalFileName'] ?? '',
            'materialType': material['materialType'] ?? '',
            'fileUrl': material['fileUrl'] ?? '',
          };
        }).toList();
      } catch (error) {
        debugPrint('Error loading materials: $error');
      }

      List<Map<String, dynamic>> loadedProjects = [];

      try {
        final List<dynamic> rawProjects = await ProjectService()
            .getClassroomProjectGroups(widget.classroomId!);

        loadedProjects = rawProjects
            .map<Map<String, dynamic>>(
              (dynamic project) =>
                  _normalizeProject(Map<String, dynamic>.from(project)),
            )
            .toList();
      } catch (error) {
        debugPrint('Error loading projects: $error');
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _activities = loadedActivities;
        _documents = loadedMaterials;
        _projects = loadedProjects;
      });
    } catch (error) {
      debugPrint('Error loading activities: $error');
    }
  }

  Future<void> _editClass() async {
    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute<Map<String, dynamic>>(
            builder: (BuildContext context) {
              return EditClassScreen(
                className: _className,
                classCode: _classCode,
                semester: _semester,
                description: _description,
                schedules: _rawSchedules,
              );
            },
          ),
        );

    if (result == null) {
      return;
    }

    try {
      final List<Map<String, dynamic>> schedulesRequest =
          List<Map<String, dynamic>>.from(result['schedules'] ?? const []);

      if (widget.classroomId != null) {
        await ClassroomService().updateClassroom(
          classroomId: widget.classroomId!,
          name: result['name'] as String? ?? '',
          description: result['description'] as String? ?? '',
          semesterCode: result['semesterCode'] as String? ?? 'SU26',
          schedules: schedulesRequest,
        );

        await _fetchClassroomDetails();
        await _fetchTabData();

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật lớp học thành công!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _primaryDarkColor,
          ),
        );
      } else {
        setState(() {
          _className = result['name'] as String;

          _description = result['description'] as String? ?? _description;

          _semester = result['semesterCode'] as String? ?? _semester;

          _rawSchedules = schedulesRequest;

          _schedules = _rawSchedules.map(_formatScheduleLabel).toList();
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật lớp học: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  Future<void> _handleCreateNew() async {
    if (_currentTab == 'Dự án') {
      final Map<String, dynamic>? result =
          await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute<Map<String, dynamic>>(
              builder: (BuildContext context) {
                return CreateProjectScreen(
                  fixedClassroomId: widget.classroomId,
                  fixedClass: _className,
                );
              },
            ),
          );

      if (result != null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _projects.insert(0, {
            'id': result['id'],
            'classroomId': widget.classroomId,
            'title': result['projectName'] ?? result['groupName'] ?? 'Dự án',
            'projectName':
                result['projectName'] ?? result['groupName'] ?? 'Dự án',
            'group': result['groupName'] ?? '',
            'groupName': result['groupName'] ?? '',
            'members':
                '${(result['members'] as List<dynamic>? ?? []).length} sinh viên',
            'membersList': (result['members'] as List<dynamic>? ?? [])
                .map(
                  (dynamic member) =>
                      member['fullName'] ?? member['userName'] ?? 'Thành viên',
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
      final Map<String, dynamic>? result =
          await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute<Map<String, dynamic>>(
              builder: (BuildContext context) {
                return CreateActivityScreen(
                  classroomId: widget.classroomId,
                  availableClassrooms: [
                    {
                      'id': widget.classroomId,
                      'className': _className,
                      'code': _classCode,
                    },
                  ],
                );
              },
            ),
          );

      if (result != null) {
        if (!mounted) {
          return;
        }

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
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: _borderColor,
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Quay lại',
        onPressed: () {
          Navigator.of(
            context,
          ).pop({'className': _className, 'classCode': _classCode});
        },
        icon: const Icon(Icons.arrow_back_rounded, color: _textPrimaryColor),
      ),
      titleSpacing: 0,
      title: const Text(
        'Chi tiết lớp học',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildClassOverview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: _primaryDarkColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lớp học',
                  style: TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _className,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 20,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: _editClass,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryDarkColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: _primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text(
              'Chỉnh sửa',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 15, 10, 15),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F2),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.key_outlined,
              color: _textSecondaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mã lớp học',
                  style: TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _classCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sao chép mã lớp',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _classCode));

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép mã lớp học!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(
              Icons.content_copy_rounded,
              color: _primaryDarkColor,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard({
    required IconData icon,
    required String label,
    required String value,
    required String helperText,
    VoidCallback? onTap,
  }) {
    final Widget card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primaryDarkColor, size: 19),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: _textSecondaryColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            helperText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onTap != null ? _primaryDarkColor : _textSecondaryColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: card,
      ),
    );
  }

  Widget _buildClassStatistics() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildInformationCard(
            icon: Icons.people_outline_rounded,
            label: 'Tổng sinh viên',
            value: '${widget.studentsCount}',
            helperText: 'Xem danh sách',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return StudentListScreen(
                      classroomId: widget.classroomId ?? 0,
                      className: _className,
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInformationCard(
            icon: Icons.calendar_month_outlined,
            label: 'Học kỳ',
            value: _semester,
            helperText: 'Kỳ hiện tại',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F0),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _primaryDarkColor, size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title: 'Lịch học', icon: Icons.schedule_outlined),
        const SizedBox(height: 14),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              ),
            ),
          )
        else
          ..._schedules.map(_buildScheduleBox),
      ],
    );
  }

  Widget _buildScheduleBox(String scheduleText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: _textSecondaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              scheduleText,
              style: const TextStyle(
                color: _textPrimaryColor,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInnerTabs() {
    const List<String> tabs = ['Hoạt động', 'Tài liệu', 'Dự án'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: tabs.map((String tab) {
          final bool isActive = _currentTab == tab;

          return Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentTab = tab;
                  });
                },
                borderRadius: BorderRadius.circular(13),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? _primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tab,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? Colors.white : _textSecondaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabHeader() {
    final bool isMaterialTab = _currentTab == 'Tài liệu';

    final bool isProjectTab = _currentTab == 'Dự án';

    return Row(
      children: [
        Expanded(
          child: Text(
            'Danh sách ${_currentTab.toLowerCase()}',
            style: const TextStyle(
              color: _textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: _handleCreateNew,
          style: FilledButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          icon: Icon(
            isMaterialTab ? Icons.upload_rounded : Icons.add_rounded,
            size: 17,
          ),
          label: Text(
            isMaterialTab
                ? 'Tải lên'
                : isProjectTab
                ? 'Thêm dự án'
                : 'Tạo mới',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF9AA49E), size: 34),
          const SizedBox(height: 11),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textSecondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) {
                  return ActivityDetailScreen(
                    activityId: activity['id'] as int?,
                    activityTitle: activity['title'],
                    deadline: activity['date'],
                    submissions: activity['submissions'],
                    description: activity['description'] ?? '',
                    className: _className,
                  );
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: _primaryDarkColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['title'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrimaryColor,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          const Icon(
                            Icons.assignment_turned_in_outlined,
                            color: _textSecondaryColor,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              activity['submissions'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textSecondaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: _textSecondaryColor,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              activity['date'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textSecondaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9AA49E),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> document) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.insert_drive_file_outlined,
              color: _primaryDarkColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document['title'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${document['size']} • ${document['date']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Tải xuống',
            onPressed: () async {
              final String urlString = document['fileUrl'] ?? '';

              if (urlString.isNotEmpty) {
                final Uri uri = Uri.parse(urlString);

                try {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (!mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Không thể tải xuống/mở: $urlString'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (error) {
                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Không thể mở tài liệu: $error'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tài liệu không có đường dẫn trực tuyến.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(
              Icons.download_rounded,
              color: _primaryDarkColor,
              size: 21,
            ),
          ),
          IconButton(
            tooltip: 'Xóa tài liệu',
            onPressed: () {
              _handleDeleteDocument(document);
            },
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: _errorColor,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final String group = project['group'] ?? project['groupName'] ?? 'Nhóm 1';

    final String date = project['date'] ?? '10/8/2026';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () async {
            final Map<String, dynamic>? updatedProject =
                await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute<Map<String, dynamic>>(
                    builder: (BuildContext context) {
                      return ProjectDetailScreen(
                        project: project,
                        availableClasses: [_classCode],
                      );
                    },
                  ),
                );

            if (updatedProject != null) {
              setState(() {
                project['title'] = updatedProject['title'];

                project['group'] = updatedProject['group'];

                project['groupName'] = updatedProject['groupName'];

                project['date'] = updatedProject['date'];

                project['members'] = updatedProject['members'];

                project['membersList'] = updatedProject['membersList'];

                project['leader'] = updatedProject['leader'];

                project['milestones'] = updatedProject['milestones'];

                project['progress'] =
                    '${(updatedProject['progress'] * 100).toInt()}%';
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.work_outline_rounded,
                    color: _primaryDarkColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['title'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrimaryColor,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          const Icon(
                            Icons.groups_outlined,
                            color: _textSecondaryColor,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              group,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textSecondaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: _textSecondaryColor,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textSecondaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9AA49E),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTabContent() {
    if (_currentTab == 'Hoạt động') {
      if (_activities.isEmpty) {
        return [
          _buildEmptyState(
            icon: Icons.assignment_outlined,
            message: 'Chưa có hoạt động nào.',
          ),
        ];
      }

      return _activities.map(_buildActivityCard).toList();
    }

    if (_currentTab == 'Tài liệu') {
      if (_documents.isEmpty) {
        return [
          _buildEmptyState(
            icon: Icons.insert_drive_file_outlined,
            message: 'Chưa có tài liệu nào.',
          ),
        ];
      }

      return _documents.map(_buildDocumentCard).toList();
    }

    if (_projects.isEmpty) {
      return [
        _buildEmptyState(
          icon: Icons.work_outline_rounded,
          message: 'Chưa có dự án nào.',
        ),
      ];
    }

    return _projects.map(_buildProjectCard).toList();
  }

  void _handleDeleteDocument(Map<String, dynamic> document) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          contentPadding: const EdgeInsets.fromLTRB(22, 16, 22, 4),
          actionsPadding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
          title: const Row(
            children: [
              _DeleteDialogIcon(),
              SizedBox(width: 13),
              Expanded(
                child: Text(
                  'Xóa tài liệu?',
                  style: TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Tài liệu này sẽ bị xóa vĩnh viễn khỏi lớp học.',
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSecondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: _borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      try {
                        final int? materialId = document['id'] as int?;

                        if (materialId != null) {
                          await MaterialService().deleteMaterial(materialId);
                        }

                        if (!mounted) {
                          return;
                        }

                        setState(() {
                          _documents.remove(document);
                        });

                        Navigator.of(dialogContext).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã xóa tài liệu "${document['title']}"!',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (error) {
                        if (!mounted) {
                          return;
                        }

                        Navigator.of(dialogContext).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Không thể xóa tài liệu: $error'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: _errorColor,
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Xác nhận',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  InputDecoration _buildSheetInputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9AA49E),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: _textSecondaryColor, size: 20),
      filled: true,
      fillColor: const Color(0xFFF9FBFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _errorColor, width: 1.5),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _textPrimaryColor,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _showUploadMaterialSheet() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final TextEditingController titleController = TextEditingController();

    final TextEditingController descriptionController = TextEditingController();

    String selectedType = 'DOCUMENT';

    List<int>? fileBytes;
    String? fileName;

    bool isUploading = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext sheetContext, StateSetter setSheetState) {
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _borderColor,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF7F0),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              color: _primaryDarkColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 13),
                          const Expanded(
                            child: Text(
                              'Tải lên tài liệu',
                              style: TextStyle(
                                color: _textPrimaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: isUploading
                                ? null
                                : () {
                                    Navigator.of(sheetContext).pop();
                                  },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: _textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _buildFieldLabel('Tiêu đề *'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: titleController,
                        enabled: !isUploading,
                        style: const TextStyle(
                          color: _textPrimaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildSheetInputDecoration(
                          hintText: 'Nhập tiêu đề tài liệu',
                          prefixIcon: Icons.title_rounded,
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Tiêu đề là bắt buộc';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 17),
                      _buildFieldLabel('Mô tả'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descriptionController,
                        enabled: !isUploading,
                        maxLines: 3,
                        minLines: 3,
                        style: const TextStyle(
                          color: _textPrimaryColor,
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                        decoration: _buildSheetInputDecoration(
                          hintText: 'Nhập mô tả chi tiết tài liệu (tùy chọn)',
                        ),
                      ),
                      const SizedBox(height: 17),
                      _buildFieldLabel('Loại tài liệu *'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        dropdownColor: _surfaceColor,
                        style: const TextStyle(
                          color: _textPrimaryColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildSheetInputDecoration(
                          hintText: 'Chọn loại tài liệu',
                          prefixIcon: Icons.category_outlined,
                        ),
                        items: const [
                          DropdownMenuItem<String>(
                            value: 'DOCUMENT',
                            child: Text('Tài liệu (Document)'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'VIDEO',
                            child: Text('Video'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'SLIDE',
                            child: Text('Slide bài giảng'),
                          ),
                        ],
                        onChanged: isUploading
                            ? null
                            : (String? value) {
                                if (value != null) {
                                  setSheetState(() {
                                    selectedType = value;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 17),
                      _buildFieldLabel('Tập tin tài liệu *'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FBFA),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                fileName ?? 'Chưa chọn tệp tin',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: fileName != null
                                      ? _textPrimaryColor
                                      : const Color(0xFF9AA49E),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: isUploading
                                  ? null
                                  : () async {
                                      try {
                                        final FilePickerResult? pickerResult =
                                            await FilePicker.pickFiles(
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
                                      } catch (error) {
                                        debugPrint(
                                          'Error picking file: $error',
                                        );
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryDarkColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                side: const BorderSide(color: _primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.attach_file_rounded,
                                size: 17,
                              ),
                              label: const Text(
                                'Chọn tệp',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isUploading
                                  ? null
                                  : () {
                                      Navigator.of(sheetContext).pop();
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _textSecondaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: const BorderSide(color: _borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Hủy',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: isUploading
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }

                                      if (fileBytes == null ||
                                          fileName == null) {
                                        ScaffoldMessenger.of(
                                          sheetContext,
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
                                        final Map<String, dynamic>
                                        result = await MaterialService()
                                            .uploadMaterial(
                                              classroomId: widget.classroomId!,
                                              title: titleController.text
                                                  .trim(),
                                              description: descriptionController
                                                  .text
                                                  .trim(),
                                              materialType: selectedType,
                                              fileBytes: fileBytes!,
                                              fileName: fileName!,
                                            );

                                        if (!mounted) {
                                          return;
                                        }

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
                                                result['originalFileName'] ??
                                                '',
                                            'materialType':
                                                result['materialType'] ?? '',
                                            'fileUrl': result['fileUrl'] ?? '',
                                          });
                                        });

                                        Navigator.of(sheetContext).pop();

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
                                      } catch (error) {
                                        setSheetState(() {
                                          isUploading = false;
                                        });

                                        ScaffoldMessenger.of(
                                          sheetContext,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Lỗi tải lên tài liệu: $error',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: _errorColor,
                                          ),
                                        );
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: _primaryColor
                                    .withValues(alpha: 0.65),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isUploading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Lưu',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      titleController.dispose();
      descriptionController.dispose();
    });
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _surfaceColor,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: BottomNavigationBar(
        currentIndex: 1,
        onTap: (int index) {
          Navigator.of(context).pop(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: _surfaceColor,
        selectedItemColor: _primaryDarkColor,
        unselectedItemColor: const Color(0xFF9AA49E),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school_rounded),
            label: 'Lớp học',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment_rounded),
            label: 'Hoạt động',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline_rounded),
            activeIcon: Icon(Icons.work_rounded),
            label: 'Dự án',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications_rounded),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClassOverview(),
                    const SizedBox(height: 14),
                    _buildClassCodeCard(),
                    const SizedBox(height: 14),
                    _buildClassStatistics(),
                    const SizedBox(height: 28),
                    _buildSchedulesSection(),
                    const SizedBox(height: 18),
                    _buildInnerTabs(),
                    const SizedBox(height: 24),
                    _buildTabHeader(),
                    const SizedBox(height: 14),
                    ..._buildTabContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}

class _DeleteDialogIcon extends StatelessWidget {
  const _DeleteDialogIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: Color(0xFFDC3D43),
        size: 22,
      ),
    );
  }
}
