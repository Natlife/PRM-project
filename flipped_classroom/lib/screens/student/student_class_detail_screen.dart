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
  State<StudentClassDetailScreen> createState() => _StudentClassDetailScreenState();
}

class _StudentClassDetailScreenState extends State<StudentClassDetailScreen> {
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
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final rawActivities = await ActivityService().getStudentActivities(widget.classroomId!);
      final List<Map<String, dynamic>> loadedActivities = [];

      for (final activity in rawActivities) {
        Map<String, dynamic> submission = {};
        try {
          final activityId = (activity['id'] as num?)?.toInt();
          if (activityId != null) {
            submission = await ActivityService().getStudentSubmission(activityId);
          }
        } catch (e) {
          debugPrint('Error loading student submission for activity ${activity['id']}: $e');
        }

        final submissionStatus = submission['status']?.toString() ?? 'NOT_SUBMITTED';
        final isDone = submissionStatus == 'SUBMITTED' ||
            submissionStatus == 'LATE_SUBMITTED' ||
            submissionStatus == 'GRADED';

        loadedActivities.add({
          'id': activity['id'],
          'title': activity['title'] ?? '',
          'type': (activity['activityType'] == 'PRE_CLASS' ||
                  activity['activityType'] == 'BEFORE_CLASS')
              ? 'Truoc buoi hoc'
              : 'Trong buoi hoc',
          'deadline': 'Han: ${_formatDate(activity['dueAt'])}',
          'status': isDone ? 'Da lam' : 'Chua lam',
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

      final rawMaterials = await MaterialService().getClassroomMaterials(widget.classroomId!);
      final loadedMaterials = rawMaterials.map<Map<String, dynamic>>((material) {
        final type = material['materialType'] == 'VIDEO' ? 'video' : 'file';
        return {
          'id': material['id'],
          'title': material['title'] ?? '',
          'description': material['description'] ?? '',
          'originalFileName': material['originalFileName'] ?? '',
          'type': type,
          'size': _formatBytes(material['sizeBytes']),
          'date': 'Dang ngay: ${_formatDate(material['publishedAt'])}',
          'fileUrl': material['fileUrl'] ?? '',
        };
      }).toList();

      Map<String, dynamic> loadedProject = {};
      try {
        final projectGroup = await ProjectService().getStudentProjectGroup(widget.classroomId!);
        if (projectGroup.isNotEmpty) {
          final groupId = (projectGroup['id'] as num?)?.toInt();
          List<Map<String, dynamic>> milestones = [];
          if (groupId != null) {
            final rawMilestones = await ProjectService().getGroupMilestones(groupId);
            milestones = rawMilestones.map<Map<String, dynamic>>((milestone) {
              final status = milestone['status']?.toString() ?? 'NOT_STARTED';
              Color color = Colors.grey;
              String displayStatus = 'Chua bat dau';
              if (status == 'COMPLETED') {
                color = Colors.greenAccent;
                displayStatus = 'Hoan thanh';
              } else if (status == 'IN_PROGRESS') {
                color = Colors.amberAccent;
                displayStatus = 'Dang thuc hien';
              }

              return {
                'id': milestone['id'],
                'title': milestone['title'] ?? '',
                'description': milestone['description'] ?? '',
                'dueAt': milestone['dueAt'],
                'dueDate': 'Han chot: ${_formatDate(milestone['dueAt'])}',
                'progress': ((milestone['progressPercent'] ?? 0) as num).toDouble() / 100.0,
                'progressPercent': milestone['progressPercent'] ?? 0,
                'status': displayStatus,
                'color': color,
                'attachments': milestone['attachments'] ?? const [],
              };
            }).toList();
          }

          final rawMembers = List<Map<String, dynamic>>.from(projectGroup['members'] ?? const []);
          final leader = projectGroup['leader'] as Map<String, dynamic>?;
          final members = rawMembers.map<Map<String, dynamic>>((member) {
            final isLeader = member['id'] == leader?['id'];
            return {
              'name': member['fullName'] ?? member['userName'] ?? '',
              'role': isLeader ? 'Truong nhom' : 'Thanh vien',
            };
          }).toList();

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
      } catch (e) {
        debugPrint('No project group found for student: $e');
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
    } catch (e) {
      debugPrint('Error loading student classroom detail data: $e');
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    }
  }

  void _onBottomNavTapped(int index) {
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _buildTabButton(0, 'hoat dong')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTabButton(1, 'tai lieu')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTabButton(2, 'du an')),
                ],
              ),
            ),
            if (_activeTab == 0) _buildSubFilters(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: const Color(0xFF7EC07E),
        unselectedItemColor: const Color(0xFF0F172A).withOpacity(0.4),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Trang chu'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'Lop hoc'),
          BottomNavigationBarItem(icon: Icon(Icons.group_work_outlined), label: 'Du an'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Thong bao'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Ca nhan'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isActive = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF7EC07E).withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
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
          _buildSubFilterButton(0, 'Truoc buoi hoc'),
          const SizedBox(width: 12),
          _buildSubFilterButton(1, 'Trong buoi hoc'),
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
          setState(() => _activeSubFilter = index);
        }
      },
      selectedColor: const Color(0xFF7EC07E),
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: isActive ? Colors.white : const Color(0xFF0F172A).withOpacity(0.6),
      ),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }

  Widget _buildActivitiesContent() {
    final subFilterType = _activeSubFilter == 0 ? 'Truoc buoi hoc' : 'Trong buoi hoc';
    final filteredList = _activities.where((activity) => activity['type'] == subFilterType).toList();

    if (filteredList.isEmpty) {
      return const Center(
        child: Text('Khong co hoat dong nao!', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final activity = filteredList[index];
        final isDone = activity['status'] == 'Da lam';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentActivityDetailScreen(activity: activity),
                  ),
                );
                if (mounted) {
                  _loadData();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            activity['type'] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A).withOpacity(0.4),
                            ),
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
                            activity['status'] ?? 'Chua lam',
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
                    Text(
                      activity['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: const Color(0xFF0F172A).withOpacity(0.4)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            activity['deadline'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF0F172A).withOpacity(0.5),
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            size: 12, color: const Color(0xFF0F172A).withOpacity(0.3)),
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

  Widget _buildMaterialsContent() {
    if (_materials.isEmpty) {
      return const Center(
        child: Text('Khong co tai lieu nao!', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _materials.length,
      itemBuilder: (context, index) {
        final material = _materials[index];
        final isVideo = material['type'] == 'video';
        final meta = [
          if ((material['size'] ?? '').toString().isNotEmpty) material['size'],
          material['date'],
        ].join(' • ');

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
              backgroundColor: isVideo
                  ? const Color(0xFF7EC07E).withOpacity(0.1)
                  : Colors.redAccent.withOpacity(0.1),
              child: Icon(
                isVideo ? Icons.play_circle_outline : Icons.picture_as_pdf_outlined,
                color: isVideo ? const Color(0xFF7EC07E) : Colors.redAccent,
              ),
            ),
            title: Text(
              material['title'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((material['description'] ?? '').toString().isNotEmpty)
                    Text(
                      material['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF0F172A).withOpacity(0.6),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF0F172A).withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download_for_offline_outlined, color: Color(0xFF7EC07E)),
              onPressed: () async {
                final url = material['fileUrl']?.toString() ?? '';
                if (url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tai lieu khong co duong dan tai.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectsContent() {
    if (_projectInfo.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Ban chua tham gia nhom du an nao trong lop hoc nay.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentProjectDetailScreen(
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
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _projectInfo['groupName'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7EC07E),
                          ),
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Thanh vien:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(_projectInfo['members'] as List<dynamic>).map((member) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7EC07E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              member['name'] ?? '',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                          ),
                          Text(
                            '(${member['role']})',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF0F172A).withOpacity(0.4),
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
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentPeerReviewScreen(
                  classroomId: widget.classroomId ?? 0,
                  classCode: widget.classCodeWithName.split(' - ').first,
                ),
              ),
            );
          },
          icon: const Icon(Icons.rate_review, color: Colors.white, size: 18),
          label: const Text(
            'Danh gia cheo nhom khac',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7EC07E),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Moc danh gia du an',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),
        ...(_projectInfo['milestones'] as List<dynamic>).map((milestone) {
          final progress = (milestone['progress'] as num?)?.toDouble() ?? 0;
          final color = milestone['color'] as Color? ?? Colors.grey;
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
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentMilestoneDetailScreen(
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
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            milestone['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Text(
                          milestone['status'] ?? '',
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      milestone['dueDate'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF0F172A).withOpacity(0.4),
                      ),
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
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF0F172A).withOpacity(0.5),
                          ),
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
