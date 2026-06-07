import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _projectData = Map<String, dynamic>.from(widget.project);
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

  Future<void> _navigateToEditProject() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProjectScreen(
          availableClasses: widget.availableClasses,
          project: _projectData,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _projectData = result;
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
      setState(() {
        final miles = List<Map<String, dynamic>>.from(_projectData['milestones'] ?? []);
        miles.add(result);
        _projectData['milestones'] = miles;
      });
    }
  }


  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
        return const Color(0xFF22C55E);
      case 'Đang thực hiện':
        return const Color(0xFF2E8EFF);
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
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(_projectData),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8EFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
              ),
            ),
          ),
          title: const Text(
            'Chi tiết dự án',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (group.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  group,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF8F8DFF), fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 18),
              Center(
                child: ElevatedButton(
                  onPressed: _navigateToEditProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8EFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Chỉnh sửa',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Số lượng sinh viên',
                            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            members.isNotEmpty ? members.replaceAll(' sinh viên', '') : '3',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Thành viên',
                            style: TextStyle(fontSize: 10, color: Color(0xFF8F8DFF), fontWeight: FontWeight.bold),
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
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Hạn nộp',
                            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            date,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ngày hoàn thành',
                            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.3)),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  ElevatedButton.icon(
                    onPressed: _navigateToCreateMilestone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8EFF),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 14, color: Colors.white),
                    label: const Text(
                      'thêm',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (milestones.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text(
                      'Chưa có milestone nào',
                      style: TextStyle(color: Colors.white38),
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
                          setState(() {
                            final miles = List<Map<String, dynamic>>.from(_projectData['milestones'] ?? []);
                            miles[index] = updatedMilestone;
                            _projectData['milestones'] = miles;
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
                              mTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  mDate,
                                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
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
