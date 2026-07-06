import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/project_service.dart';
import 'edit_milestone_screen.dart';

class MilestoneDetailScreen extends StatefulWidget {
  final Map<String, dynamic> milestone;

  const MilestoneDetailScreen({
    super.key,
    required this.milestone,
  });

  @override
  State<MilestoneDetailScreen> createState() => _MilestoneDetailScreenState();
}

class _MilestoneDetailScreenState extends State<MilestoneDetailScreen> {
  late Map<String, dynamic> _milestoneData;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _milestoneData = Map<String, dynamic>.from(widget.milestone);
    
    _milestoneData['activities'] ??= [];
    _milestoneData['comments'] ??= [];
    _milestoneData['evidences'] ??= [];
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
      case 'COMPLETED':
        return const Color(0xFF22C55E);
      case 'Đang thực hiện':
      case 'IN_PROGRESS':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Future<void> _saveMilestoneChanges() async {
    final milestoneId = (_milestoneData['id'] as num?)?.toInt() ?? 0;
    if (milestoneId == 0) return;

    DateTime? dueDateTime;
    final dateStr = _milestoneData['date']?.toString() ?? '';
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

    final statusRaw = _milestoneData['status']?.toString() ?? 'Chưa bắt đầu';
    String backendStatus = 'NOT_STARTED';
    if (statusRaw == 'Hoàn thành' || statusRaw == 'COMPLETED') {
      backendStatus = 'COMPLETED';
    } else if (statusRaw == 'Đang thực hiện' || statusRaw == 'IN_PROGRESS') {
      backendStatus = 'IN_PROGRESS';
    } else if (statusRaw == 'Quá hạn' || statusRaw == 'OVERDUE') {
      backendStatus = 'OVERDUE';
    }

    final descriptionPayload = jsonEncode({
      'description': _milestoneData['description'] ?? '',
      'tasks': _milestoneData['activities'] ?? [],
      'comments': _milestoneData['comments'] ?? [],
    });

    final payload = {
      'title': _milestoneData['title'] ?? '',
      'description': descriptionPayload,
      'dueAt': dueAtIso,
      'status': backendStatus,
    };

    try {
      await ProjectService().updateMilestone(milestoneId, payload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật mốc thời gian: $e')),
        );
      }
    }
  }

  void _changeActivityStatus(int index) {
    final List<dynamic> activities = List.from(_milestoneData['activities'] ?? []);
    final act = Map<String, dynamic>.from(activities[index]);
    final currentStatus = act['status'] ?? 'Chưa bắt đầu';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cập nhật trạng thái hoạt động'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Chưa bắt đầu'),
                leading: Radio<String>(
                  value: 'Chưa bắt đầu',
                  groupValue: currentStatus,
                  onChanged: (val) {
                    Navigator.pop(context, 'Chưa bắt đầu');
                  },
                ),
                onTap: () => Navigator.pop(context, 'Chưa bắt đầu'),
              ),
              ListTile(
                title: const Text('Đang thực hiện'),
                leading: Radio<String>(
                  value: 'Đang thực hiện',
                  groupValue: currentStatus,
                  onChanged: (val) {
                    Navigator.pop(context, 'Đang thực hiện');
                  },
                ),
                onTap: () => Navigator.pop(context, 'Đang thực hiện'),
              ),
              ListTile(
                title: const Text('Hoàn thành'),
                leading: Radio<String>(
                  value: 'Hoàn thành',
                  groupValue: currentStatus,
                  onChanged: (val) {
                    Navigator.pop(context, 'Hoàn thành');
                  },
                ),
                onTap: () => Navigator.pop(context, 'Hoàn thành'),
              ),
            ],
          ),
        );
      },
    ).then((selectedStatus) {
      if (selectedStatus != null && selectedStatus != currentStatus) {
        setState(() {
          act['status'] = selectedStatus;
          act['isDone'] = selectedStatus == 'Hoàn thành';
          activities[index] = act;
          _milestoneData['activities'] = activities;

          // Recalculate milestone progress based on completed activities
          final completedCount = activities.where((a) => a['isDone'] == true || a['status'] == 'Hoàn thành').length;
          final double newProgress = activities.isEmpty ? 0.0 : completedCount / activities.length;
          
          if (newProgress == 1.0) {
            _milestoneData['status'] = 'Hoàn thành';
          } else if (newProgress == 0.0) {
            _milestoneData['status'] = 'Chưa bắt đầu';
          } else {
            _milestoneData['status'] = 'Đang thực hiện';
          }
        });
        _saveMilestoneChanges();
      }
    });
  }

  Future<void> _navigateToEditMilestone() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditMilestoneScreen(milestone: _milestoneData),
      ),
    );
    if (result != null) {
      setState(() {
        _milestoneData = result;
      });
      _saveMilestoneChanges();
    }
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      final list = List<Map<String, dynamic>>.from(_milestoneData['comments'] ?? []);
      list.add({
        'sender': 'Giáo viên',
        'text': text,
      });
      _milestoneData['comments'] = list;
      _commentController.clear();
    });
    _saveMilestoneChanges();
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> activities = _milestoneData['activities'] ?? [];
    final List<dynamic> comments = _milestoneData['comments'] ?? [];
    final List<dynamic> evidences = _milestoneData['attachments'] ?? _milestoneData['evidences'] ?? [];
    final String title = _milestoneData['title'] ?? 'Mốc thời gian';
    final String status = _milestoneData['status'] ?? 'Chưa bắt đầu';
    final String date = _milestoneData['date'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(_milestoneData),
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
          'Chi tiết mốc thời gian',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Milestone Title Header
                  Text(
                    title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  
                  // Status & Deadline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(status),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hạn: $date',
                            style: TextStyle(fontSize: 12, color: const Color(0xFF0F172A).withValues(alpha: 0.4)),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _navigateToEditMilestone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7EC07E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          'Chỉnh sửa',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Activities
                  Text(
                    'Hoạt động (${activities.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  if (activities.isEmpty)
                    const Center(
                      child: Text(
                        'Chưa có hoạt động nào',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    )
                  else
                    ...List.generate(activities.length, (index) {
                      final act = activities[index];
                      final actTitle = act['title'] ?? '';
                      final actStatus = act['status'] ?? 'Chưa bắt đầu';
                      return GestureDetector(
                        onTap: () => _changeActivityStatus(index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.04)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  actTitle,
                                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    actStatus,
                                    style: TextStyle(color: _getStatusColor(actStatus), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.edit, size: 14, color: _getStatusColor(actStatus)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),

                  // Evidence
                  const Text(
                    'Minh chứng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  if (evidences.isEmpty)
                    const Center(
                      child: Text(
                        'Chưa tải lên minh chứng nào',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    )
                  else
                    ...evidences.map((ev) {
                      final fName = ev['originalFileName'] ?? ev['fileName'] ?? 'minh_chung.pdf';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.04)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                fName,
                                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đang tải và mở: $fName'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Xem',
                                  style: TextStyle(color: Color(0xFF0F172A), fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 24),

                  // Comments
                  const Text(
                    'Trao đổi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  if (comments.isEmpty)
                    const Center(
                      child: Text(
                        'Chưa có thảo luận nào',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    )
                  else
                    ...comments.map((comment) {
                      final sender = comment['sender'] ?? '';
                      final text = comment['text'] ?? '';
                      final isTeacher = sender == 'Giáo viên';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        alignment: isTeacher
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isTeacher
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF0F172A).withOpacity(0.1),
                                ),
                              ),
                              child: Text(
                                text,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                sender,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
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
          
          // Bottom Comment Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              border: Border(
                top: BorderSide(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Nhập nhận xét của bạn...',
                      hintStyle: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (v) => _sendComment(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF7EC07E)),
                  onPressed: _sendComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
