import 'package:flutter/material.dart';

import 'student_milestone_detail_screen.dart';

class StudentProjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const StudentProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  State<StudentProjectDetailScreen> createState() => _StudentProjectDetailScreenState();
}

class _StudentProjectDetailScreenState extends State<StudentProjectDetailScreen> {
  late List<Map<String, dynamic>> _milestones;

  @override
  void initState() {
    super.initState();
    _milestones = widget.project['milestones'] != null
        ? List<Map<String, dynamic>>.from(widget.project['milestones'])
        : [];
  }

  void _onBottomNavTapped(int index) {
    Navigator.pop(context, index);
  }

  @override
  Widget build(BuildContext context) {
    final membersList = widget.project['membersList'] != null
        ? List<String>.from(widget.project['membersList'])
        : <String>[];
    final groupName = widget.project['groupName']?.toString() ?? '';
    final projectName = widget.project['projectName']?.toString() ?? '';
    final description = widget.project['description']?.toString() ?? '';
    final classCodeWithName = widget.project['classCodeWithName']?.toString() ?? '';

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
        title: const Text(
          'Chi tiet du an',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (classCodeWithName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7EC07E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    classCodeWithName,
                    style: const TextStyle(
                      color: Color(0xFF7EC07E),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (classCodeWithName.isNotEmpty) const SizedBox(height: 12),
              Text(
                projectName.isNotEmpty ? projectName : (widget.project['title']?.toString() ?? groupName),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (groupName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  groupName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7EC07E).withOpacity(0.85),
                  ),
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF0F172A).withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thanh vien (${membersList.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (membersList.isEmpty)
                      Text(
                        'Chua co du lieu thanh vien tu backend.',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF0F172A).withOpacity(0.5),
                        ),
                      )
                    else
                      ...membersList.map((memberName) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.1)),
                          ),
                          child: Center(
                            child: Text(
                              memberName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Milestone',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              ..._milestones.map((milestone) {
                final statusRaw = milestone['status']?.toString() ?? 'NOT_STARTED';
                String displayStatus = 'Chua bat dau';
                Color statusColor = Colors.grey;
                if (statusRaw == 'COMPLETED' || statusRaw == 'Hoan thanh') {
                  displayStatus = 'Hoan thanh';
                  statusColor = const Color(0xFF7EC07E);
                } else if (statusRaw == 'IN_PROGRESS' || statusRaw == 'Dang thuc hien') {
                  displayStatus = 'Dang thuc hien';
                  statusColor = Colors.amberAccent;
                } else if (statusRaw == 'OVERDUE' || statusRaw == 'Qua han') {
                  displayStatus = 'Qua han';
                  statusColor = Colors.redAccent;
                }

                final dueAtStr = milestone['dueAt']?.toString() ?? milestone['dueDate']?.toString() ?? '';
                String formattedDue = '';
                if (dueAtStr.isNotEmpty) {
                  if (dueAtStr.contains('Han:')) {
                    formattedDue = dueAtStr;
                  } else {
                    try {
                      final dt = DateTime.parse(dueAtStr);
                      formattedDue =
                          'Han: ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                    } catch (_) {
                      formattedDue = dueAtStr;
                    }
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentMilestoneDetailScreen(
                              milestone: milestone,
                              project: widget.project,
                            ),
                          ),
                        );
                        if (!context.mounted) {
                          return;
                        }
                        if (result is int) {
                          Navigator.pop(context, result);
                        } else if (result is Map<String, dynamic>) {
                          setState(() {
                            milestone['status'] = result['status'];
                            milestone['progress'] = result['progress'];
                            milestone['progressPercent'] = (result['progress'] * 100).toInt();
                            milestone['tasks'] = result['tasks'];
                            milestone['attachments'] = result['attachments'];
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    milestone['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  displayStatus,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formattedDue,
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF0F172A).withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
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
          currentIndex: 2,
          onTap: _onBottomNavTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFFFFFFF),
          selectedItemColor: const Color(0xFF7EC07E),
          unselectedItemColor: const Color(0xFF0F172A).withOpacity(0.4),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Trang chu'),
            BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'Lop hoc'),
            BottomNavigationBarItem(icon: Icon(Icons.group_work_outlined), label: 'Du an'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Thong bao'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Ca nhan'),
          ],
        ),
      ),
    );
  }
}
