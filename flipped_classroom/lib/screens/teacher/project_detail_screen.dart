import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/project_service.dart';
import 'edit_project_screen.dart';
import 'create_milestone_screen.dart';
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
  late Map<String, dynamic> _projectData;
  bool _isLoadingMilestones = false;

  @override
  void initState() {
    super.initState();
    _projectData = _normalizeProjectData(widget.project);
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    final groupId = (_projectData['id'] as num?)?.toInt() ?? 0;
    if (groupId == 0) return;
    setState(() {
      _isLoadingMilestones = true;
    });
    try {
      final list = await ProjectService().getGroupMilestones(groupId);
      setState(() {
        _projectData['milestones'] = list.map((m) {
          final dueAt = m['dueAt']?.toString() ?? '';
          String formattedDate = '';
          if (dueAt.isNotEmpty) {
            try {
              final dt = DateTime.parse(dueAt);
              formattedDate = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
            } catch (_) {
              formattedDate = dueAt;
            }
          }
          final statusRaw = m['status']?.toString() ?? 'NOT_STARTED';
          String displayStatus = 'Chưa bắt đầu';
          if (statusRaw == 'COMPLETED') {
            displayStatus = 'Hoàn thành';
          } else if (statusRaw == 'IN_PROGRESS') {
            displayStatus = 'Đang thực hiện';
          } else if (statusRaw == 'OVERDUE') {
            displayStatus = 'Quá hạn';
          }
          return {
            'id': m['id'],
            'title': m['title'] ?? '',
            'date': formattedDate,
            'status': displayStatus,
            'activities': m['activities'] ?? [],
            'comments': m['comments'] ?? [],
            'evidences': m['evidences'] ?? [],
            'description': m['description'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading milestones: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMilestones = false;
        });
      }
    }
  }

  Future<void> _saveMilestoneUpdate(int milestoneId, Map<String, dynamic> data) async {
    DateTime? dueDateTime;
    final dateStr = data['date']?.toString() ?? '';
    if (dateStr.isNotEmpty) {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          dueDateTime = DateTime(year, month, day, 23, 59, 59);
        }
      }
    }
    dueDateTime ??= DateTime.now().add(const Duration(days: 7));
    final dueAtIso = dueDateTime.toIso8601String();

    final statusRaw = data['status']?.toString() ?? 'Chưa bắt đầu';
    String backendStatus = 'NOT_STARTED';
    if (statusRaw == 'Hoàn thành' || statusRaw == 'COMPLETED') {
      backendStatus = 'COMPLETED';
    } else if (statusRaw == 'Đang thực hiện' || statusRaw == 'IN_PROGRESS') {
      backendStatus = 'IN_PROGRESS';
    } else if (statusRaw == 'Quá hạn' || statusRaw == 'OVERDUE') {
      backendStatus = 'OVERDUE';
    }

    final descriptionPayload = jsonEncode({
      'description': data['description'] ?? '',
      'tasks': data['activities'] ?? [],
      'comments': data['comments'] ?? [],
    });

    final payload = {
      'title': data['title'] ?? '',
      'description': descriptionPayload,
      'dueAt': dueAtIso,
      'status': backendStatus,
    };

    try {
      await ProjectService().updateMilestone(milestoneId, payload);
      _loadMilestones();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật mốc thời gian: $e')),
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
    final rawMembers = project['members'];
    final rawMembersData = project['membersData'];
    final List<dynamic> members = (rawMembers is List)
        ? rawMembers
        : ((rawMembersData is List) ? rawMembersData : []);

    final rawMembersList = project['membersList'];
    final List<dynamic> membersList = (rawMembersList is List)
        ? rawMembersList
        : members
            .map((member) => member['fullName'] ?? member['userName'] ?? 'Thanh vien')
            .toList();

    return {
      ...project,
      'title': project['title'] ?? project['projectName'] ?? 'Du an',
      'projectName': project['projectName'] ?? project['title'] ?? 'Du an',
      'group': project['group'] ?? project['groupName'] ?? '',
      'groupName': project['groupName'] ?? project['group'] ?? '',
      'membersList': membersList,
      'membersData': members,
      'members': (project['members'] is String)
          ? project['members']
          : '${membersList.length} sinh vien',
      'leader': project['leader'] ?? project['leaderData']?['fullName'],
      'leaderData': project['leaderData'] ?? project['leader'],
      'milestones': project['milestones'] ?? [],
    };
  }

  Future<void> _navigateToEditProject() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProjectScreen(
          project: _projectData,
          classroomId: (_projectData['classroomId'] as num?)?.toInt() ?? 0,
          classLabel: _projectData['class'] ?? _projectData['className'] ?? '',
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _projectData = _normalizeProjectData(result);
      });
    }
  }

  Future<void> _navigateToCreateMilestone() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateMilestoneScreen(),
      ),
    );
    if (result != null) {
      final groupId = (_projectData['id'] as num?)?.toInt() ?? 0;
      if (groupId != 0) {
        DateTime? dueDateTime;
        final dateStr = result['date']?.toString() ?? '';
        if (dateStr.isNotEmpty) {
          final parts = dateStr.split('/');
          if (parts.length == 3) {
            final day = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            final year = int.tryParse(parts[2]);
            if (day != null && month != null && year != null) {
              dueDateTime = DateTime(year, month, day, 23, 59, 59);
            }
          }
        }
        dueDateTime ??= DateTime.now().add(const Duration(days: 7));
        final dueAtIso = dueDateTime.toIso8601String();

        final descriptionPayload = jsonEncode({
          'description': '',
          'tasks': result['activities'] ?? [],
          'comments': [],
        });

        final payload = {
          'title': result['title'] ?? '',
          'description': descriptionPayload,
          'dueAt': dueAtIso,
        };

        try {
          await ProjectService().createMilestone(groupId, payload);
          _loadMilestones();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không thể tạo mốc thời gian: $e')),
            );
          }
        }
      }
    }
    if (false) {
      setState(() {
        final miles = List<Map<String, dynamic>>.from(_projectData['milestones'] ?? []);
        miles.add(result!);
        _projectData['milestones'] = miles;
      });
    }
  }


  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
        return const Color(0xFF22C55E);
      case 'Đang thực hiện':
        return const Color(0xFF7EC07E);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> milestones = _projectData['milestones'] ?? [];
    final String title = _projectData['title'] ?? 'Dự án';
    final String group = _projectData['group'] ?? _projectData['groupName'] ?? '';
    final String date = _projectData['date'] ?? '';
    final String members = _projectData['members'] ?? '';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Pass the updated project data back
          // Widget might need result.
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(_projectData),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF7EC07E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 16),
              ),
            ),
          ),
          title: const Text(
            'Chi tiết dự án',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              if (group.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  group,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF7EC07E), fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 18),
              Center(
                child: ElevatedButton(
                  onPressed: _navigateToEditProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7EC07E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Chỉnh sửa',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.04)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Số lượng sinh viên',
                            style: TextStyle(fontSize: 11, color: const Color(0xFF0F172A).withValues(alpha: 0.4)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            members.isNotEmpty ? members.replaceAll(' sinh viên', '') : '3',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Thành viên',
                            style: TextStyle(fontSize: 10, color: Color(0xFF7EC07E), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.04)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Hạn nộp',
                            style: TextStyle(fontSize: 11, color: const Color(0xFF0F172A).withValues(alpha: 0.4)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            date,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ngày hoàn thành',
                            style: TextStyle(fontSize: 10, color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Milestone',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _navigateToCreateMilestone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7EC07E),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 14, color: Color(0xFF0F172A)),
                    label: const Text(
                      'thêm',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_isLoadingMilestones)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
                  ),
                )
              else if (milestones.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text(
                      'Chưa có milestone nào',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: milestones.length,
                  itemBuilder: (context, index) {
                    final milestone = milestones[index];
                    final String mTitle = milestone['title'] ?? '';
                    final String mDate = milestone['date'] ?? '';
                    final String mStatus = milestone['status'] ?? 'Chưa bắt đầu';
                    final Color statColor = _getStatusColor(mStatus);
 
                    return GestureDetector(
                      onTap: () async {
                        final updatedMilestone = await Navigator.push<Map<String, dynamic>>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MilestoneDetailScreen(
                              milestone: Map<String, dynamic>.from(milestone),
                            ),
                          ),
                        );
                        if (updatedMilestone != null) {
                          final mId = (milestone['id'] as num?)?.toInt() ?? 0;
                          if (mId != 0) {
                            _saveMilestoneUpdate(mId, updatedMilestone);
                          }
                        }
                        if (false) {
                          setState(() {
                            final miles = List<Map<String, dynamic>>.from(_projectData['milestones'] ?? []);
                            miles[index] = updatedMilestone!;
                            _projectData['milestones'] = miles;
                          });
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.04)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  mDate,
                                  style: TextStyle(fontSize: 12, color: const Color(0xFF0F172A).withValues(alpha: 0.4)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    mStatus,
                                    style: TextStyle(color: statColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
