import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/project_service.dart';
import 'create_milestone_screen.dart';
import 'edit_project_screen.dart';
import 'milestone_detail_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  final List<String> availableClasses;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.availableClasses,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _softGreenColor = Color(0xFFEAF7F0);
  static const Color _inputBackgroundColor = Color(0xFFF9FBFA);
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);

  late Map<String, dynamic> _projectData;

  bool _isLoadingMilestones = false;

  @override
  void initState() {
    super.initState();

    _projectData = _normalizeProjectData(widget.project);
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    final int groupId = (_projectData['id'] as num?)?.toInt() ?? 0;

    if (groupId == 0) {
      return;
    }

    setState(() {
      _isLoadingMilestones = true;
    });

    try {
      final List<dynamic> list = await ProjectService().getGroupMilestones(
        groupId,
      );

      String projectDeadline = '';

      if (list.isNotEmpty) {
        DateTime? latestDate;

        for (final dynamic milestone in list) {
          final String dueAt = milestone['dueAt']?.toString() ?? '';

          if (dueAt.isNotEmpty) {
            try {
              final DateTime dateTime = DateTime.parse(dueAt);

              if (latestDate == null || dateTime.isAfter(latestDate)) {
                latestDate = dateTime;
              }
            } catch (_) {}
          }
        }

        if (latestDate != null) {
          projectDeadline =
              '${latestDate.day.toString().padLeft(2, '0')}/'
              '${latestDate.month.toString().padLeft(2, '0')}/'
              '${latestDate.year}';
        }
      }

      setState(() {
        _projectData['date'] = projectDeadline;

        _projectData['milestones'] = list.map((dynamic milestone) {
          final String dueAt = milestone['dueAt']?.toString() ?? '';

          String formattedDate = '';

          if (dueAt.isNotEmpty) {
            try {
              final DateTime dateTime = DateTime.parse(dueAt);

              formattedDate =
                  '${dateTime.day.toString().padLeft(2, '0')}/'
                  '${dateTime.month.toString().padLeft(2, '0')}/'
                  '${dateTime.year}';
            } catch (_) {
              formattedDate = dueAt;
            }
          }

          final String statusRaw =
              milestone['status']?.toString() ?? 'NOT_STARTED';

          String displayStatus = 'Chưa bắt đầu';

          if (statusRaw == 'COMPLETED') {
            displayStatus = 'Hoàn thành';
          } else if (statusRaw == 'IN_PROGRESS') {
            displayStatus = 'Đang thực hiện';
          } else if (statusRaw == 'OVERDUE') {
            displayStatus = 'Quá hạn';
          }

          return {
            'id': milestone['id'],
            'title': milestone['title'] ?? '',
            'date': formattedDate,
            'status': displayStatus,
            'activities': milestone['activities'] ?? [],
            'comments': milestone['comments'] ?? [],
            'evidences': milestone['evidences'] ?? [],
            'description': milestone['description'] ?? '',
          };
        }).toList();
      });
    } catch (error) {
      debugPrint('Error loading milestones: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMilestones = false;
        });
      }
    }
  }

  Future<void> _saveMilestoneUpdate(
    int milestoneId,
    Map<String, dynamic> data,
  ) async {
    DateTime? dueDateTime;

    final String dateString = data['date']?.toString() ?? '';

    if (dateString.isNotEmpty) {
      final List<String> parts = dateString.split('/');

      if (parts.length == 3) {
        final int? day = int.tryParse(parts[0]);

        final int? month = int.tryParse(parts[1]);

        final int? year = int.tryParse(parts[2]);

        if (day != null && month != null && year != null) {
          dueDateTime = DateTime(year, month, day, 23, 59, 59);
        }
      }
    }

    dueDateTime ??= DateTime.now().add(const Duration(days: 7));

    final String dueAtIso = dueDateTime.toIso8601String();

    final String statusRaw = data['status']?.toString() ?? 'Chưa bắt đầu';

    String backendStatus = 'NOT_STARTED';

    if (statusRaw == 'Hoàn thành' || statusRaw == 'COMPLETED') {
      backendStatus = 'COMPLETED';
    } else if (statusRaw == 'Đang thực hiện' || statusRaw == 'IN_PROGRESS') {
      backendStatus = 'IN_PROGRESS';
    } else if (statusRaw == 'Quá hạn' || statusRaw == 'OVERDUE') {
      backendStatus = 'OVERDUE';
    }

    final String descriptionPayload = jsonEncode({
      'description': data['description'] ?? '',
      'tasks': data['activities'] ?? [],
      'comments': data['comments'] ?? [],
    });

    final Map<String, dynamic> payload = {
      'title': data['title'] ?? '',
      'description': descriptionPayload,
      'dueAt': dueAtIso,
      'status': backendStatus,
    };

    try {
      await ProjectService().updateMilestone(milestoneId, payload);

      _loadMilestones();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật mốc thời gian: $error')),
        );
      }
    }
  }

  void _unusedLegacyInit() {
    if (_projectData['milestones'] == null) {
      _projectData['milestones'] = [
        {
          'title': 'Phân tích yêu cầu',
          'date': '01/01/2027',
          'status': 'Hoàn thành',
        },
      ];
    }
  }

  Map<String, dynamic> _normalizeProjectData(Map<String, dynamic> project) {
    final dynamic rawMembers = project['members'];

    final dynamic rawMembersData = project['membersData'];

    final List<dynamic> members = rawMembers is List
        ? rawMembers
        : rawMembersData is List
        ? rawMembersData
        : [];

    final dynamic rawMembersList = project['membersList'];

    final List<dynamic> membersList = rawMembersList is List
        ? rawMembersList
        : members.map((dynamic member) {
            return member['fullName'] ?? member['userName'] ?? 'Thanh vien';
          }).toList();

    return {
      ...project,
      'title': project['title'] ?? project['projectName'] ?? 'Du an',
      'projectName': project['projectName'] ?? project['title'] ?? 'Du an',
      'group': project['group'] ?? project['groupName'] ?? '',
      'groupName': project['groupName'] ?? project['group'] ?? '',
      'membersList': membersList,
      'membersData': members,
      'members': project['members'] is String
          ? project['members']
          : '${membersList.length} sinh vien',
      'leader': project['leader'] ?? project['leaderData']?['fullName'],
      'leaderData': project['leaderData'] ?? project['leader'],
      'milestones': project['milestones'] ?? [],
    };
  }

  Future<void> _navigateToEditProject() async {
    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute<Map<String, dynamic>>(
            builder: (BuildContext context) {
              return EditProjectScreen(
                project: _projectData,
                classroomId:
                    (_projectData['classroomId'] as num?)?.toInt() ?? 0,
                classLabel:
                    _projectData['class'] ?? _projectData['className'] ?? '',
              );
            },
          ),
        );

    if (result != null) {
      setState(() {
        _projectData = _normalizeProjectData(result);
      });
    }
  }

  Future<void> _navigateToCreateMilestone() async {
    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute<Map<String, dynamic>>(
            builder: (BuildContext context) {
              return const CreateMilestoneScreen();
            },
          ),
        );

    if (result != null) {
      final int groupId = (_projectData['id'] as num?)?.toInt() ?? 0;

      if (groupId != 0) {
        DateTime? dueDateTime;

        final String dateString = result['date']?.toString() ?? '';

        if (dateString.isNotEmpty) {
          final List<String> parts = dateString.split('/');

          if (parts.length == 3) {
            final int? day = int.tryParse(parts[0]);

            final int? month = int.tryParse(parts[1]);

            final int? year = int.tryParse(parts[2]);

            if (day != null && month != null && year != null) {
              dueDateTime = DateTime(year, month, day, 23, 59, 59);
            }
          }
        }

        dueDateTime ??= DateTime.now().add(const Duration(days: 7));

        final String dueAtIso = dueDateTime.toIso8601String();

        final String descriptionPayload = jsonEncode({
          'description': '',
          'tasks': result['activities'] ?? [],
          'comments': [],
        });

        final Map<String, dynamic> payload = {
          'title': result['title'] ?? '',
          'description': descriptionPayload,
          'dueAt': dueAtIso,
        };

        try {
          await ProjectService().createMilestone(groupId, payload);

          _loadMilestones();
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không thể tạo mốc thời gian: $error')),
            );
          }
        }
      }
    }

    if (false) {
      setState(() {
        final List<Map<String, dynamic>> milestones =
            List<Map<String, dynamic>>.from(_projectData['milestones'] ?? []);

        milestones.add(result!);
        _projectData['milestones'] = milestones;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
        return const Color(0xFF22C55E);

      case 'Đang thực hiện':
        return _primaryColor;

      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Hoàn thành':
        return Icons.check_circle_outline_rounded;

      case 'Đang thực hiện':
        return Icons.timelapse_rounded;

      case 'Quá hạn':
        return Icons.error_outline_rounded;

      default:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: _borderColor,
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: 'Quay lại',
        onPressed: () {
          Navigator.of(context).pop(_projectData);
        },
        icon: const Icon(Icons.arrow_back_rounded, color: _textPrimaryColor),
      ),
      titleSpacing: 0,
      title: const Text(
        'Chi tiết dự án',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildOverviewCard({required String title, required String group}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _softGreenColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  color: _primaryDarkColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dự án',
                      style: TextStyle(
                        color: _textSecondaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textPrimaryColor,
                        fontSize: 20,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (group.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.groups_outlined,
                            color: _primaryDarkColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              group,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _primaryDarkColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _navigateToEditProject,
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryDarkColor,
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: _primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text(
                'Chỉnh sửa dự án',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics({required String members, required String date}) {
    return Row(
      children: [
        Expanded(
          child: _buildStatisticCard(
            icon: Icons.people_outline_rounded,
            label: 'Số lượng sinh viên',
            value: members.isNotEmpty
                ? members.replaceAll(' sinh viên', '')
                : '3',
            helperText: 'Thành viên',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatisticCard(
            icon: Icons.calendar_today_outlined,
            label: 'Hạn nộp',
            value: date.isNotEmpty ? date : '—',
            helperText: 'Ngày hoàn thành',
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticCard({
    required IconData icon,
    required String label,
    required String value,
    required String helperText,
  }) {
    return Container(
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
              color: _softGreenColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primaryDarkColor, size: 19),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textSecondaryColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textPrimaryColor,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            helperText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _primaryDarkColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesSection(List<dynamic> milestones) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMilestonesHeader(milestones.length),
          const SizedBox(height: 17),
          if (_isLoadingMilestones)
            _buildLoadingState()
          else if (milestones.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: milestones.length,
              itemBuilder: (BuildContext context, int index) {
                final dynamic milestone = milestones[index];

                final String milestoneTitle = milestone['title'] ?? '';

                final String milestoneDate = milestone['date'] ?? '';

                final String milestoneStatus =
                    milestone['status'] ?? 'Chưa bắt đầu';

                return _buildMilestoneCard(
                  milestone: milestone,
                  index: index,
                  title: milestoneTitle,
                  date: milestoneDate,
                  status: milestoneStatus,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMilestonesHeader(int milestonesCount) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: _softGreenColor,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.flag_outlined,
            color: _primaryDarkColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Text(
            'Mốc thời gian',
            style: TextStyle(
              color: _textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: _softGreenColor,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '$milestonesCount',
            style: const TextStyle(
              color: _primaryDarkColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 9),
        FilledButton.icon(
          onPressed: _navigateToCreateMilestone,
          style: FilledButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 17),
          label: const Text(
            'Thêm',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: _primaryColor,
            strokeWidth: 2.6,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: _inputBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: const Column(
        children: [
          Icon(Icons.flag_outlined, color: Color(0xFF9AA49E), size: 31),
          SizedBox(height: 10),
          Text(
            'Chưa có mốc thời gian nào',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard({
    required dynamic milestone,
    required int index,
    required String title,
    required String date,
    required String status,
  }) {
    final Color statusColor = _getStatusColor(status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _inputBackgroundColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () async {
            final Map<String, dynamic>? updatedMilestone =
                await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute<Map<String, dynamic>>(
                    builder: (BuildContext context) {
                      return MilestoneDetailScreen(
                        milestone: Map<String, dynamic>.from(milestone),
                      );
                    },
                  ),
                );

            if (updatedMilestone != null) {
              final int milestoneId = (milestone['id'] as num?)?.toInt() ?? 0;

              if (milestoneId != 0) {
                _saveMilestoneUpdate(milestoneId, updatedMilestone);
              }
            }

            if (false) {
              setState(() {
                final List<Map<String, dynamic>> milestones =
                    List<Map<String, dynamic>>.from(
                      _projectData['milestones'] ?? [],
                    );

                milestones[index] = updatedMilestone!;

                _projectData['milestones'] = milestones;
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: statusColor,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrimaryColor,
                          fontSize: 13.5,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 9),
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
                              date.isNotEmpty ? date : 'Chưa cập nhật',
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
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.11),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 9),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9AA49E),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required String title,
    required String group,
    required String date,
    required String members,
    required List<dynamic> milestones,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCard(title: title, group: group),
              const SizedBox(height: 14),
              _buildStatistics(members: members, date: date),
              const SizedBox(height: 14),
              _buildMilestonesSection(milestones),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> milestones = _projectData['milestones'] ?? [];

    final String title = _projectData['title'] ?? 'Dự án';

    final String group =
        _projectData['group'] ?? _projectData['groupName'] ?? '';

    final String date = _projectData['date'] ?? '';

    final String members = _projectData['members'] ?? '';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          // Pass the updated project data back.
          // Widget might need result.
        }
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: _buildAppBar(),
        body: SafeArea(
          top: false,
          child: _buildContent(
            title: title,
            group: group,
            date: date,
            members: members,
            milestones: milestones,
          ),
        ),
      ),
    );
  }
}
