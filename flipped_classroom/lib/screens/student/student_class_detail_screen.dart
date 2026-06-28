import 'package:flutter/material.dart';
import 'student_activity_detail_screen.dart';
import 'student_project_detail_screen.dart';
import 'student_milestone_detail_screen.dart';
import 'student_peer_review_screen.dart';
import '../../services/activity_service.dart';
import '../../services/material_service.dart';
import '../../services/project_service.dart';

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
  int _activeTab = 0; // 0: Hoạt động, 1: Tài liệu, 2: Dự án
  int _activeSubFilter = 0; // 0: Trước buổi học, 1: Trong buổi học

  bool _isLoading = true;
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _materials = [];
  Map<String, dynamic> _projectInfo = {};

  @override
  void initState() {
    super.initState();
    _loadData();
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
      // 1. Fetch activities
      final rawActs = await ActivityService().getStudentActivities(widget.classroomId!);
      final List<Map<String, dynamic>> loadedActivities = rawActs.map((act) {
        final String dueStr = act['dueAt'] != null
            ? act['dueAt'].toString().split('T').first
            : 'N/A';
        final String status = (act['status'] == 'SUBMITTED' ||
                act['status'] == 'GRADED' ||
                act['status'] == 'RETURNED' ||
                act['status'] == 'Đã làm')
            ? 'Đã làm'
            : 'Chưa làm';
        return {
          'id': act['id'].toString(),
          'title': act['title'] ?? 'Bài tập',
          'type': act['activityType'] == 'PRE_CLASS' ? 'Trước buổi học' : 'Trong buổi học',
          'deadline': 'Hạn: $dueStr',
          'status': status,
          'description': act['description'] ?? '',
          'evidence': '',
          'submissionTime': '',
        };
      }).toList();

      // 2. Fetch materials
      final rawMats = await MaterialService().getClassroomMaterials(widget.classroomId!);
      final List<Map<String, dynamic>> loadedMaterials = rawMats.map((mat) {
        final String type = mat['materialType'] == 'VIDEO' ? 'video' : 'pdf';
        final String dateStr = mat['createdAt'] != null
            ? mat['createdAt'].toString().split('T').first
            : 'N/A';
        return {
          'title': mat['title'] ?? '',
          'type': type,
          'size': type == 'pdf' ? '2.5 MB' : null,
          'duration': type == 'video' ? '1h 20m' : null,
          'date': 'Đăng ngày: $dateStr',
        };
      }).toList();

      // 3. Fetch project info and milestones
      Map<String, dynamic> loadedProject = {};
      try {
        final projectGroup = await ProjectService().getStudentProjectGroup(widget.classroomId!);
        if (projectGroup.isNotEmpty) {
          final int? groupId = projectGroup['id'];
          List<Map<String, dynamic>> milestones = [];
          if (groupId != null) {
            final rawMilestones = await ProjectService().getGroupMilestones(groupId);
            milestones = rawMilestones.map((m) {
              final double progress = (m['progressPercent'] ?? 0) / 100.0;
              final String status = m['status'] ?? 'Chưa bắt đầu';
              Color color = Colors.white24;
              if (status == 'COMPLETED' || status == 'Hoàn thành') {
                color = Colors.greenAccent;
              } else if (status == 'IN_PROGRESS' || status == 'Đang thực hiện') {
                color = Colors.amberAccent;
              }
              final String dueStr = m['dueAt'] != null
                  ? m['dueAt'].toString().split('T').first
                  : 'N/A';
              return {
                'id': m['id'],
                'title': m['title'] ?? '',
                'dueDate': 'Hạn chót: $dueStr',
                'progress': progress,
                'status': status == 'COMPLETED' ? 'Đã hoàn thành' : (status == 'IN_PROGRESS' ? 'Đang thực hiện' : 'Chưa bắt đầu'),
                'color': color,
              };
            }).toList();
          }

          final List<dynamic> rawMembers = projectGroup['members'] ?? [];
          final List<Map<String, dynamic>> members = rawMembers.map((m) {
            final isLeader = m['id'] == projectGroup['leader']?['id'];
            return {
              'name': m['fullName'] ?? m['userName'] ?? '',
              'role': isLeader ? 'Trưởng nhóm' : 'Thành viên',
            };
          }).toList();

          loadedProject = {
            'id': groupId,
            'groupName': projectGroup['groupName'] ?? 'Nhóm chưa đặt tên',
            'projectName': projectGroup['projectName'] ?? 'Dự án chưa đặt tên',
            'leader': projectGroup['leader'],
            'members': members,
            'membersData': rawMembers,
            'milestones': milestones,
          };
        }
      } catch (e) {
        debugPrint('No project group found for student: $e');
      }

      setState(() {
        _activities = loadedActivities;
        _materials = loadedMaterials;
        _projectInfo = loadedProject;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading student classroom detail data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

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
    if (_projectInfo.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Bạn chưa tham gia nhóm dự án nào trong lớp học này.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ),
      );
    }

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
                      'id': _projectInfo['id'],
                      'title': _projectInfo['projectName'] ?? 'App lớp học đảo ngược',
                      'projectName': _projectInfo['projectName'] ?? 'App lớp học đảo ngược',
                      'leader': _projectInfo['leader'],
                      'membersList': (_projectInfo['members'] as List)
                          .map((m) => m['name'] as String)
                          .toList(),
                      'milestones': _projectInfo['milestones'] ?? [],
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
                  classroomId: widget.classroomId ?? 0,
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
                        'id': _projectInfo['id'],
                        'title': _projectInfo['projectName'] ?? 'App lớp học đảo ngược',
                        'projectName': _projectInfo['projectName'] ?? 'App lớp học đảo ngược',
                        'leader': _projectInfo['leader'],
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
