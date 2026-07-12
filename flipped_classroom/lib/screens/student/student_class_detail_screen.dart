import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/activity_service.dart';
import '../../services/material_service.dart';
import '../../services/project_service.dart';
import 'student_activity_detail_screen.dart';
import 'student_milestone_detail_screen.dart';
import 'student_peer_review_screen.dart';
import 'student_project_detail_screen.dart';

class StudentClassDetailScreen extends StatefulWidget {
  final int? classroomId;
  final String classCodeWithName;
  final String className;
  final String instructor;
  final String semester;

  const StudentClassDetailScreen({
    super.key,
    this.classroomId,
    required this.classCodeWithName,
    required this.className,
    required this.instructor,
    required this.semester,
  });

  @override
  State<StudentClassDetailScreen> createState() =>
      _StudentClassDetailScreenState();
}

class _StudentClassDetailScreenState extends State<StudentClassDetailScreen> {
  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _dangerColor = Color(0xFFEF4444);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _fieldColor = Color(0xFFF8FAFC);

  final ActivityService _activityService = ActivityService();
  final MaterialService _materialService = MaterialService();
  final ProjectService _projectService = ProjectService();

  int _activeTab = 0;
  int _activeSubFilter = 0;

  bool _isLoading = true;
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _materials = [];
  Map<String, dynamic> _projectInfo = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _formatDate(dynamic rawValue) {
    if (rawValue == null) {
      return 'N/A';
    }

    final raw = rawValue.toString().split('T').first;
    final parts = raw.split('-');

    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }

    return raw;
  }

  String _formatBytes(dynamic sizeBytes) {
    if (sizeBytes == null) {
      return '';
    }

    final bytes = sizeBytes is num
        ? sizeBytes.toDouble()
        : double.tryParse(sizeBytes.toString()) ?? 0;

    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${bytes.toStringAsFixed(0)} B';
  }

  Future<void> _loadData() async {
    if (widget.classroomId == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final activities = await _loadActivities();
      final materials = await _loadMaterials();
      final projectInfo = await _loadProjectInfo();

      if (!mounted) return;

      setState(() {
        _activities = activities;
        _materials = materials;
        _projectInfo = projectInfo;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading student classroom detail data: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadActivities() async {
    final rawActivities =
        await _activityService.getStudentActivities(widget.classroomId!);

    final loadedActivities = <Map<String, dynamic>>[];

    for (final activity in rawActivities) {
      Map<String, dynamic> submission = {};

      try {
        final activityId = (activity['id'] as num?)?.toInt();

        if (activityId != null) {
          submission = await _activityService.getStudentSubmission(activityId);
        }
      } catch (e) {
        debugPrint(
          'Error loading student submission for activity ${activity['id']}: $e',
        );
      }

      final submissionStatus =
          submission['status']?.toString() ?? 'NOT_SUBMITTED';

      final isDone = submissionStatus == 'SUBMITTED' ||
          submissionStatus == 'LATE_SUBMITTED' ||
          submissionStatus == 'GRADED';

      loadedActivities.add({
        'id': activity['id'],
        'title': activity['title'] ?? '',
        'type': _mapActivityType(activity['activityType']),
        'deadline': 'Hạn: ${_formatDate(activity['dueAt'])}',
        'status': isDone ? 'Đã làm' : 'Chưa làm',
        'description': activity['description'] ?? '',
        'maxScore': activity['maxScore'],
        'activityWorkflowStatus': activity['status']?.toString() ?? '',
        'submissionId': submission['id'],
        'submissionStatus': submissionStatus,
        'submissionTime': submission['submittedAt']?.toString(),
        'attachmentCount': submission['attachmentCount'] ?? 0,
        'commentCount': submission['commentCount'] ?? 0,
        'teacherFeedback': submission['teacherFeedback'] ?? '',
        'score': submission['score'],
      });
    }

    return loadedActivities;
  }

  Future<List<Map<String, dynamic>>> _loadMaterials() async {
    final rawMaterials =
        await _materialService.getClassroomMaterials(widget.classroomId!);

    return rawMaterials.map<Map<String, dynamic>>((material) {
      final type = material['materialType'] == 'VIDEO' ? 'video' : 'file';

      return {
        'id': material['id'],
        'title': material['title'] ?? '',
        'description': material['description'] ?? '',
        'originalFileName': material['originalFileName'] ?? '',
        'type': type,
        'size': _formatBytes(material['sizeBytes']),
        'date': 'Đăng ngày: ${_formatDate(material['publishedAt'])}',
        'fileUrl': material['fileUrl'] ?? '',
      };
    }).toList();
  }

  Future<Map<String, dynamic>> _loadProjectInfo() async {
    try {
      final projectGroup =
          await _projectService.getStudentProjectGroup(widget.classroomId!);

      if (projectGroup.isEmpty) {
        return {};
      }

      final groupId = (projectGroup['id'] as num?)?.toInt();
      final milestones = groupId == null ? <Map<String, dynamic>>[] : await _loadMilestones(groupId);

      final rawMembers = List<Map<String, dynamic>>.from(
        projectGroup['members'] ?? const [],
      );

      final leader = projectGroup['leader'] as Map<String, dynamic>?;

      final members = rawMembers.map<Map<String, dynamic>>((member) {
        final isLeader = member['id'] == leader?['id'];

        return {
          'name': member['fullName'] ?? member['userName'] ?? '',
          'role': isLeader ? 'Trưởng nhóm' : 'Thành viên',
        };
      }).toList();

      return {
        'id': groupId,
        'groupName': projectGroup['groupName'] ?? '',
        'projectName': projectGroup['projectName'] ?? '',
        'leader': leader,
        'members': members,
        'membersData': rawMembers,
        'milestones': milestones,
      };
    } catch (e) {
      debugPrint('No project group found for student: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _loadMilestones(int groupId) async {
    final rawMilestones = await _projectService.getGroupMilestones(groupId);

    return rawMilestones.map<Map<String, dynamic>>((milestone) {
      final status = milestone['status']?.toString() ?? 'NOT_STARTED';
      final displayStatus = _mapMilestoneStatus(status);
      final color = _getMilestoneColor(status);

      return {
        'id': milestone['id'],
        'title': milestone['title'] ?? '',
        'description': milestone['description'] ?? '',
        'dueAt': milestone['dueAt'],
        'dueDate': 'Hạn chót: ${_formatDate(milestone['dueAt'])}',
        'progress':
            ((milestone['progressPercent'] ?? 0) as num).toDouble() / 100.0,
        'progressPercent': milestone['progressPercent'] ?? 0,
        'status': displayStatus,
        'color': color,
        'attachments': milestone['attachments'] ?? const [],
        'tasks': milestone['tasks'] ?? const [],
        'activities': milestone['activities'] ?? const [],
      };
    }).toList();
  }

  String _mapActivityType(dynamic value) {
    final type = value?.toString();

    if (type == 'PRE_CLASS' || type == 'BEFORE_CLASS') {
      return 'Trước buổi học';
    }

    return 'Trong buổi học';
  }

  String _mapMilestoneStatus(String status) {
    if (status == 'COMPLETED') {
      return 'Hoàn thành';
    }

    if (status == 'IN_PROGRESS') {
      return 'Đang thực hiện';
    }

    return 'Chưa bắt đầu';
  }

  Color _getMilestoneColor(String status) {
    if (status == 'COMPLETED') {
      return _primaryColor;
    }

    if (status == 'IN_PROGRESS') {
      return _warningColor;
    }

    return _mutedTextColor;
  }

  void _onBottomNavTapped(int index) {
    Navigator.pop(context, index);
  }

  void _changeTab(int index) {
    setState(() {
      _activeTab = index;
    });
  }

  void _changeSubFilter(int index) {
    setState(() {
      _activeSubFilter = index;
    });
  }

  Future<void> _openActivityDetail(Map<String, dynamic> activity) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentActivityDetailScreen(activity: activity),
      ),
    );

    if (mounted) {
      _loadData();
    }
  }

  Future<void> _openProjectDetail() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentProjectDetailScreen(
          project: {
            'id': _projectInfo['id'],
            'title': _projectInfo['projectName'] ?? '',
            'projectName': _projectInfo['projectName'] ?? '',
            'leader': _projectInfo['leader'],
            'membersList': (_projectInfo['members'] as List<dynamic>)
                .map((member) => member['name'] as String)
                .toList(),
            'milestones': _projectInfo['milestones'] ?? [],
          },
        ),
      ),
    );

    if (mounted) {
      _loadData();
    }
  }

  Future<void> _openMilestoneDetail(Map<String, dynamic> milestone) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentMilestoneDetailScreen(
          milestone: milestone,
          project: {
            'id': _projectInfo['id'],
            'title': _projectInfo['projectName'] ?? '',
            'projectName': _projectInfo['projectName'] ?? '',
            'leader': _projectInfo['leader'],
            'membersList': (_projectInfo['members'] as List<dynamic>)
                .map((member) => member['name'] as String)
                .toList(),
          },
        ),
      ),
    );

    if (mounted) {
      _loadData();
    }
  }

  void _openPeerReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentPeerReviewScreen(
          classroomId: widget.classroomId ?? 0,
          classCode: widget.classCodeWithName.split(' - ').first,
        ),
      ),
    );
  }

  Future<void> _openMaterial(Map<String, dynamic> material) async {
    final url = material['fileUrl']?.toString() ?? '';

    if (url.isEmpty) {
      _showSnackBar('Tài liệu không có đường dẫn tải.');
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      _showSnackBar('Đường dẫn tài liệu không hợp lệ.');
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    _showSnackBar('Không thể mở tài liệu này.');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _textColor,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _ClassTabs(
              activeTab: _activeTab,
              onTabChanged: _changeTab,
            ),
            if (_activeTab == 0)
              _ActivitySubFilters(
                activeFilter: _activeSubFilter,
                onFilterChanged: _changeSubFilter,
              ),
            Expanded(
              child: _isLoading
                  ? const _LoadingView()
                  : IndexedStack(
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
      bottomNavigationBar: _ClassBottomNavigationBar(
        onTap: _onBottomNavTapped,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _textColor,
          size: 20,
        ),
      ),
      title: Text(
        widget.classCodeWithName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _textColor,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  Widget _buildActivitiesContent() {
    final subFilterType =
        _activeSubFilter == 0 ? 'Trước buổi học' : 'Trong buổi học';

    final filteredList = _activities
        .where((activity) => activity['type'] == subFilterType)
        .toList();

    if (filteredList.isEmpty) {
      return const _EmptyState(
        icon: Icons.task_alt_rounded,
        title: 'Không có hoạt động nào',
        message: 'Các hoạt động của lớp sẽ xuất hiện tại đây.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      itemCount: filteredList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final activity = filteredList[index];

        return _ActivityCard(
          activity: activity,
          onTap: () => _openActivityDetail(activity),
        );
      },
    );
  }

  Widget _buildMaterialsContent() {
    if (_materials.isEmpty) {
      return const _EmptyState(
        icon: Icons.folder_open_rounded,
        title: 'Không có tài liệu nào',
        message: 'Khi giảng viên đăng tài liệu, chúng sẽ hiển thị tại đây.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      itemCount: _materials.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final material = _materials[index];

        return _MaterialCard(
          material: material,
          onOpen: () => _openMaterial(material),
        );
      },
    );
  }

  Widget _buildProjectsContent() {
    if (_projectInfo.isEmpty) {
      return const _EmptyState(
        icon: Icons.groups_2_outlined,
        title: 'Bạn chưa tham gia nhóm dự án',
        message: 'Khi bạn có nhóm dự án trong lớp, thông tin sẽ xuất hiện ở đây.',
      );
    }

    final milestones = List<Map<String, dynamic>>.from(
      _projectInfo['milestones'] ?? const [],
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _ProjectSummaryCard(
          projectInfo: _projectInfo,
          onTap: _openProjectDetail,
        ),
        const SizedBox(height: 16),
        _PeerReviewButton(
          onPressed: _openPeerReview,
        ),
        const SizedBox(height: 28),
        const _SectionTitle(title: 'Mốc đánh giá dự án'),
        const SizedBox(height: 12),
        if (milestones.isEmpty)
          const _EmptyInlineCard(
            message: 'Dự án hiện chưa có mốc đánh giá nào.',
          )
        else
          ...milestones.map(
            (milestone) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MilestoneCard(
                milestone: milestone,
                onTap: () => _openMilestoneDetail(milestone),
              ),
            ),
          ),
      ],
    );
  }
}

class _ClassTabs extends StatelessWidget {
  final int activeTab;
  final ValueChanged<int> onTabChanged;

  const _ClassTabs({
    required this.activeTab,
    required this.onTabChanged,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            _TabItem(
              label: 'Hoạt động',
              isActive: activeTab == 0,
              onTap: () => onTabChanged(0),
            ),
            _TabItem(
              label: 'Tài liệu',
              isActive: activeTab == 1,
              onTap: () => onTabChanged(1),
            ),
            _TabItem(
              label: 'Dự án',
              isActive: activeTab == 2,
              onTap: () => onTabChanged(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isActive ? _surfaceColor : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: _textColor.withOpacity(0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? _primaryColor : _textColor.withOpacity(0.55),
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivitySubFilters extends StatelessWidget {
  final int activeFilter;
  final ValueChanged<int> onFilterChanged;

  const _ActivitySubFilters({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _fieldColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Row(
        children: [
          _FilterChipButton(
            label: 'Trước buổi học',
            isActive: activeFilter == 0,
            onTap: () => onFilterChanged(0),
          ),
          const SizedBox(width: 10),
          _FilterChipButton(
            label: 'Trong buổi học',
            isActive: activeFilter == 1,
            onTap: () => onFilterChanged(1),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _fieldColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ChoiceChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: _primaryColor,
        backgroundColor: _fieldColor,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: TextStyle(
          color: isActive ? Colors.white : _textColor.withOpacity(0.62),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.activity,
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _dangerColor = Color(0xFFEF4444);
  static const Color _borderColor = Color(0xFFE2E8F0);

  bool get _isDone {
    return activity['status'] == 'Đã làm';
  }

  @override
  Widget build(BuildContext context) {
    final title = activity['title']?.toString() ?? '';
    final type = activity['type']?.toString() ?? '';
    final deadline = activity['deadline']?.toString() ?? '';
    final status = activity['status']?.toString() ?? 'Chưa làm';
    final statusColor = _isDone ? _primaryColor : _dangerColor;

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _borderColor.withOpacity(0.85)),
            boxShadow: [
              BoxShadow(
                color: _textColor.withOpacity(0.035),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _isDone
                      ? Icons.check_circle_outline_rounded
                      : Icons.assignment_late_outlined,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Hoạt động chưa có tiêu đề' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 15.5,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (type.isNotEmpty)
                          _SmallChip(
                            label: type,
                            foregroundColor: _mutedTextColor,
                            backgroundColor: const Color(0xFFF8FAFC),
                          ),
                        _SmallChip(
                          label: status,
                          foregroundColor: statusColor,
                          backgroundColor: statusColor.withOpacity(0.09),
                        ),
                      ],
                    ),
                    if (deadline.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: _mutedTextColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              deadline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _mutedTextColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: _mutedTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final Map<String, dynamic> material;
  final VoidCallback onOpen;

  const _MaterialCard({
    required this.material,
    required this.onOpen,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _dangerColor = Color(0xFFEF4444);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final isVideo = material['type'] == 'video';
    final title = material['title']?.toString() ?? '';
    final description = material['description']?.toString() ?? '';
    final meta = [
      if ((material['size'] ?? '').toString().isNotEmpty) material['size'],
      material['date'],
    ].where((item) => item != null && item.toString().isNotEmpty).join(' • ');

    final color = isVideo ? _primaryColor : _dangerColor;

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _borderColor.withOpacity(0.85)),
          boxShadow: [
            BoxShadow(
              color: _textColor.withOpacity(0.035),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isVideo
                    ? Icons.play_circle_outline_rounded
                    : Icons.picture_as_pdf_outlined,
                color: color,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Tài liệu chưa có tiêu đề' : title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textColor,
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onOpen,
              style: IconButton.styleFrom(
                backgroundColor: _primaryColor.withOpacity(0.1),
                foregroundColor: _primaryColor,
              ),
              icon: const Icon(Icons.open_in_new_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectSummaryCard extends StatelessWidget {
  final Map<String, dynamic> projectInfo;
  final VoidCallback onTap;

  const _ProjectSummaryCard({
    required this.projectInfo,
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final members = List<Map<String, dynamic>>.from(
      projectInfo['members'] ?? const [],
    );

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: _textColor.withOpacity(0.035),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.groups_2_rounded,
                      color: _primaryColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          projectInfo['groupName'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          projectInfo['projectName'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textColor,
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _mutedTextColor,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Thành viên',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ...members.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MemberRow(
                    name: member['name'] ?? '',
                    role: member['role'] ?? '',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final String name;
  final String role;

  const _MemberRow({
    required this.name,
    required this.role,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: _primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          role,
          style: const TextStyle(
            color: _mutedTextColor,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PeerReviewButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PeerReviewButton({
    required this.onPressed,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.rate_review_rounded),
        label: const Text('Đánh giá chéo nhóm khác'),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final Map<String, dynamic> milestone;
  final VoidCallback onTap;

  const _MilestoneCard({
    required this.milestone,
    required this.onTap,
  });

  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _fieldColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final progress = (milestone['progress'] as num?)?.toDouble() ?? 0;
    final color = milestone['color'] as Color? ?? _mutedTextColor;
    final percent = (progress * 100).toInt();

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _borderColor.withOpacity(0.85)),
            boxShadow: [
              BoxShadow(
                color: _textColor.withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      milestone['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 14.5,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _SmallChip(
                    label: milestone['status'] ?? '',
                    foregroundColor: color,
                    backgroundColor: color.withOpacity(0.1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                milestone['dueDate'] ?? '',
                style: const TextStyle(
                  color: _mutedTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor: _fieldColor,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      color: _mutedTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  const _SmallChip({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  static const Color _textColor = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _textColor,
        fontSize: 17,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _EmptyInlineCard extends StatelessWidget {
  final String message;

  const _EmptyInlineCard({
    required this.message,
  });

  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _mutedTextColor,
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _mutedTextColor,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClassBottomNavigationBar extends StatelessWidget {
  final ValueChanged<int> onTap;

  const _ClassBottomNavigationBar({
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: const Border(
          top: BorderSide(
            color: _borderColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: _textColor.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: 1,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: _surfaceColor,
          selectedItemColor: _primaryColor,
          unselectedItemColor: _textColor.withOpacity(0.42),
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
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
              icon: Icon(Icons.group_work_outlined),
              activeIcon: Icon(Icons.group_work_rounded),
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
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  static const Color _primaryColor = Color(0xFF7EC07E);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: _primaryColor,
        ),
      ),
    );
  }
}