import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/classroom_service.dart';
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
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);
  static const Color _warningColor = Color(0xFFF59E0B);

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

    final String raw = rawValue.toString().split('T').first;
    final List<String> parts = raw.split('-');

    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }

    return raw;
  }

  String _formatBytes(dynamic sizeBytes) {
    if (sizeBytes == null) {
      return '';
    }

    final double bytes = sizeBytes is num
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
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final overview = await ClassroomService().getStudentClassroomOverview(
        widget.classroomId!,
      );

      final List<Map<String, dynamic>> rawActivities =
          List<Map<String, dynamic>>.from(overview['activities'] ?? const []);

      final List<Map<String, dynamic>> loadedActivities = [];

      for (final Map<String, dynamic> activity in rawActivities) {
        final Map<String, dynamic> submission = Map<String, dynamic>.from(
          activity['submissionSummary'] ?? const {},
        );

        final String submissionStatus =
            submission['status']?.toString() ?? 'NOT_SUBMITTED';

        final bool isDone =
            submissionStatus == 'SUBMITTED' ||
            submissionStatus == 'LATE_SUBMITTED' ||
            submissionStatus == 'GRADED';

        loadedActivities.add({
          'id': activity['id'],
          'title': activity['title'] ?? '',
          'type':
              activity['activityType'] == 'PRE_CLASS' ||
                  activity['activityType'] == 'BEFORE_CLASS'
              ? 'Trước buổi học'
              : 'Trong buổi học',
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

      final List<Map<String, dynamic>> rawMaterials =
          List<Map<String, dynamic>>.from(overview['materials'] ?? const []);

      final List<Map<String, dynamic>> loadedMaterials = rawMaterials
          .map<Map<String, dynamic>>((Map<String, dynamic> material) {
            final String type = material['materialType'] == 'VIDEO'
                ? 'video'
                : 'file';

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
          })
          .toList();

      Map<String, dynamic> loadedProject = {};

      final Map<String, dynamic> projectGroup = Map<String, dynamic>.from(
        overview['projectGroup'] ?? const {},
      );

      if (projectGroup.isNotEmpty) {
        final int? groupId = (projectGroup['id'] as num?)?.toInt();

        final List<Map<String, dynamic>> rawMilestones =
            List<Map<String, dynamic>>.from(
              projectGroup['milestones'] ?? const [],
            );

        final List<Map<String, dynamic>> milestones = rawMilestones
            .map<Map<String, dynamic>>((Map<String, dynamic> milestone) {
              final String status =
                  milestone['status']?.toString() ?? 'NOT_STARTED';

              Color color = Colors.grey;
              String displayStatus = 'Chưa bắt đầu';

              if (status == 'COMPLETED') {
                color = Colors.greenAccent;
                displayStatus = 'Hoàn thành';
              } else if (status == 'IN_PROGRESS') {
                color = Colors.amberAccent;
                displayStatus = 'Đang thực hiện';
              }

              return {
                'id': milestone['id'],
                'title': milestone['title'] ?? '',
                'description': milestone['description'] ?? '',
                'dueAt': milestone['dueAt'],
                'dueDate': 'Hạn chót: ${_formatDate(milestone['dueAt'])}',
                'progress':
                    ((milestone['progressPercent'] ?? 0) as num).toDouble() /
                    100.0,
                'progressPercent': milestone['progressPercent'] ?? 0,
                'status': displayStatus,
                'color': color,
                'attachments': milestone['attachments'] ?? const [],
                'tasks': milestone['tasks'] ?? const [],
                'activities': milestone['activities'] ?? const [],
              };
            })
            .toList();

        final List<Map<String, dynamic>> rawMembers =
            List<Map<String, dynamic>>.from(
              projectGroup['members'] ?? const [],
            );

        final Map<String, dynamic>? leader =
            projectGroup['leader'] as Map<String, dynamic>?;

        final List<Map<String, dynamic>> members = rawMembers
            .map<Map<String, dynamic>>((Map<String, dynamic> member) {
              final bool isLeader = member['id'] == leader?['id'];

              return {
                'name': member['fullName'] ?? member['userName'] ?? '',
                'role': isLeader ? 'Trưởng nhóm' : 'Thành viên',
              };
            })
            .toList();

        loadedProject = {
          'id': groupId,
          'groupName': projectGroup['groupName'] ?? '',
          'projectName': projectGroup['projectName'] ?? '',
          'leader': leader,
          'members': members,
          'membersData': rawMembers,
          'milestones': milestones,
        };
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _activities = loadedActivities;
        _materials = loadedMaterials;
        _projectInfo = loadedProject;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading student classroom detail data: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onBottomNavTapped(int index) {
    Navigator.pop(context, index);
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
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_rounded, color: _textPrimaryColor),
      ),
      titleSpacing: 0,
      title: Text(
        widget.classCodeWithName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _textPrimaryColor,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      color: _surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                index: 0,
                label: 'Hoạt động',
                icon: Icons.assignment_outlined,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                index: 1,
                label: 'Tài liệu',
                icon: Icons.folder_outlined,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                index: 2,
                label: 'Dự án',
                icon: Icons.group_work_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final bool isActive = _activeTab == index;

    return Material(
      color: isActive ? _surfaceColor : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTab = index;
          });
        },
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _textPrimaryColor.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: isActive ? _primaryDarkColor : _textSecondaryColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? _primaryDarkColor : _textSecondaryColor,
                    fontSize: 12.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubFilters() {
    return Container(
      width: double.infinity,
      color: _surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          _buildSubFilterButton(index: 0, label: 'Trước buổi học'),
          const SizedBox(width: 10),
          _buildSubFilterButton(index: 1, label: 'Trong buổi học'),
        ],
      ),
    );
  }

  Widget _buildSubFilterButton({required int index, required String label}) {
    final bool isActive = _activeSubFilter == index;

    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      showCheckmark: false,
      side: BorderSide(color: isActive ? _primaryColor : _borderColor),
      selectedColor: const Color(0xFFEAF7F0),
      backgroundColor: _surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      labelStyle: TextStyle(
        color: isActive ? _primaryDarkColor : _textSecondaryColor,
        fontSize: 12,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
      ),
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _activeSubFilter = index;
          });
        }
      },
    );
  }

  Widget _buildActivitiesContent() {
    final String subFilterType = _activeSubFilter == 0
        ? 'Trước buổi học'
        : 'Trong buổi học';

    final List<Map<String, dynamic>> filteredList = _activities.where((
      Map<String, dynamic> activity,
    ) {
      return activity['type'] == subFilterType;
    }).toList();

    if (filteredList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment_outlined,
        title: 'Chưa có hoạt động',
        description: 'Các hoạt động của lớp học sẽ xuất hiện tại đây.',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: filteredList.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (BuildContext context, int index) {
        return _buildActivityCard(filteredList[index]);
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final bool isDone = activity['status'] == 'Đã làm';

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return StudentActivityDetailScreen(activity: activity);
              },
            ),
          );

          if (mounted) {
            _loadData();
          }
        },
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: _textPrimaryColor.withOpacity(0.035),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFFEAF7F0)
                      : const Color(0xFFFFECEE),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isDone ? Icons.task_alt_rounded : Icons.assignment_outlined,
                  color: isDone ? _primaryDarkColor : _errorColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            activity['title']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textPrimaryColor,
                              fontSize: 15,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF9AA49E),
                          size: 21,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatusChip(
                          label: activity['status']?.toString() ?? 'Chưa làm',
                          color: isDone ? _primaryDarkColor : _errorColor,
                          backgroundColor: isDone
                              ? const Color(0xFFEAF7F0)
                              : const Color(0xFFFFECEE),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activity['type']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textSecondaryColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Color(0xFF8B9690),
                          size: 14,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            activity['deadline']?.toString() ?? '',
                            style: const TextStyle(
                              color: _textSecondaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialsContent() {
    if (_materials.isEmpty) {
      return _buildEmptyState(
        icon: Icons.folder_open_outlined,
        title: 'Chưa có tài liệu',
        description: 'Tài liệu được giảng viên đăng tải sẽ xuất hiện tại đây.',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _materials.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (BuildContext context, int index) {
        return _buildMaterialCard(_materials[index]);
      },
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material) {
    final bool isVideo = material['type'] == 'video';

    final String meta = [
      if ((material['size'] ?? '').toString().isNotEmpty) material['size'],
      material['date'],
    ].join(' • ');

    final Color materialColor = isVideo ? _primaryDarkColor : _errorColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: materialColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isVideo
                  ? Icons.play_circle_outline_rounded
                  : Icons.picture_as_pdf_outlined,
              color: materialColor,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material['title']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 14.5,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((material['description'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    material['description'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textSecondaryColor,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                Text(
                  meta,
                  style: const TextStyle(
                    color: Color(0xFF8B9690),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Mở tài liệu',
            style: IconButton.styleFrom(
              foregroundColor: _primaryDarkColor,
              backgroundColor: const Color(0xFFEAF7F0),
            ),
            onPressed: () async {
              final String url = material['fileUrl']?.toString() ?? '';

              if (url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tài liệu không có đường dẫn tải.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final Uri uri = Uri.parse(url);

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsContent() {
    if (_projectInfo.isEmpty) {
      return _buildEmptyState(
        icon: Icons.group_work_outlined,
        title: 'Chưa có nhóm dự án',
        description: 'Bạn chưa tham gia nhóm dự án nào trong lớp học này.',
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _buildProjectCard(),
        const SizedBox(height: 14),
        _buildPeerReviewButton(),
        const SizedBox(height: 28),
        const Text(
          'Mốc đánh giá dự án',
          style: TextStyle(
            color: _textPrimaryColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 14),
        ...(_projectInfo['milestones'] as List<dynamic>).map((
          dynamic milestone,
        ) {
          return _buildMilestoneCard(
            Map<String, dynamic>.from(milestone as Map),
          );
        }),
      ],
    );
  }

  Widget _buildProjectCard() {
    final List<dynamic> members = _projectInfo['members'] as List<dynamic>;

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return StudentProjectDetailScreen(
                  project: {
                    'id': _projectInfo['id'],
                    'title': _projectInfo['projectName'] ?? '',
                    'projectName': _projectInfo['projectName'] ?? '',
                    'leader': _projectInfo['leader'],
                    'membersList': members
                        .map((dynamic member) => member['name'] as String)
                        .toList(),
                    'milestones': _projectInfo['milestones'] ?? [],
                  },
                );
              },
            ),
          );

          if (mounted) {
            _loadData();
          }
        },
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: _textPrimaryColor.withOpacity(0.035),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7F0),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.groups_2_outlined,
                      color: _primaryDarkColor,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _projectInfo['groupName']?.toString() ?? '',
                          style: const TextStyle(
                            color: _primaryDarkColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _projectInfo['projectName']?.toString() ?? '',
                          style: const TextStyle(
                            color: _textPrimaryColor,
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9AA49E),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: _borderColor),
              const SizedBox(height: 18),
              const Text(
                'Thành viên',
                style: TextStyle(
                  color: _textPrimaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...members.map((dynamic member) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: _textSecondaryColor,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          member['name']?.toString() ?? '',
                          style: const TextStyle(
                            color: _textPrimaryColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: member['role'] == 'Trưởng nhóm'
                              ? const Color(0xFFEAF7F0)
                              : const Color(0xFFF1F4F2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          member['role']?.toString() ?? '',
                          style: TextStyle(
                            color: member['role'] == 'Trưởng nhóm'
                                ? _primaryDarkColor
                                : _textSecondaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeerReviewButton() {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) {
                return StudentPeerReviewScreen(
                  classroomId: widget.classroomId ?? 0,
                  classCode: widget.classCodeWithName.split(' - ').first,
                );
              },
            ),
          );
        },
        style: FilledButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.rate_review_outlined, size: 20),
        label: const Text(
          'Đánh giá chéo nhóm khác',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildMilestoneCard(Map<String, dynamic> milestone) {
    final double progress = (milestone['progress'] as num?)?.toDouble() ?? 0;

    final Color color = milestone['color'] as Color? ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final List<dynamic> members =
                _projectInfo['members'] as List<dynamic>;

            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) {
                  return StudentMilestoneDetailScreen(
                    milestone: milestone,
                    project: {
                      'id': _projectInfo['id'],
                      'title': _projectInfo['projectName'] ?? '',
                      'projectName': _projectInfo['projectName'] ?? '',
                      'leader': _projectInfo['leader'],
                      'membersList': members
                          .map((dynamic member) => member['name'] as String)
                          .toList(),
                    },
                  );
                },
              ),
            );

            if (mounted) {
              _loadData();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(Icons.flag_outlined, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone['title']?.toString() ?? '',
                            style: const TextStyle(
                              color: _textPrimaryColor,
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            milestone['dueDate']?.toString() ?? '',
                            style: const TextStyle(
                              color: _textSecondaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(
                      label: milestone['status']?.toString() ?? '',
                      color: color,
                      backgroundColor: color.withOpacity(0.1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: const Color(0xFFF0F3F1),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: _textSecondaryColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9AA49E),
                      size: 19,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F0),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, color: _primaryDarkColor, size: 40),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textSecondaryColor,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _surfaceColor,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: BottomNavigationBar(
        currentIndex: 1,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: _surfaceColor,
        elevation: 0,
        selectedItemColor: _primaryDarkColor,
        unselectedItemColor: const Color(0xFF8B9690),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildTabNavigation(),
            if (_activeTab == 0) _buildSubFilters(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _primaryColor,
                          ),
                        ),
                      ),
                    )
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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
