import 'package:flutter/material.dart';

import '../../../services/event_service.dart';
import '../student_event_detail_screen.dart';

class StudentEventsTab extends StatefulWidget {
  final ValueChanged<int> onTabTapped;

  const StudentEventsTab({
    super.key,
    required this.onTabTapped,
  });

  @override
  State<StudentEventsTab> createState() => _StudentEventsTabState();
}

class _StudentEventsTabState extends State<StudentEventsTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await EventService().getStudentEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải sự kiện: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final value = raw.toString().split('T').first;
    final parts = value.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return value;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'LIVE':
        return 'Đang diễn ra';
      case 'COMPLETED':
        return 'Đã hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      case 'SCHEDULED':
      default:
        return 'Chưa diễn ra';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'LIVE':
        return Colors.green;
      case 'COMPLETED':
        return Colors.grey;
      case 'CANCELLED':
        return Colors.redAccent;
      case 'SCHEDULED':
      default:
        return Colors.orange;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'PRESENTER':
        return 'Thuyết trình';
      case 'REVIEWER':
        return 'Phản biện';
      default:
        return 'Khán giả';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEvents,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF7EC07E)),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Tất cả sự kiện',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Xem lịch review, defense và trạng thái tham gia của bạn',
                      style: TextStyle(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_events.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Text(
                            'Chưa có sự kiện nào',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ),
                      )
                    else
                      ..._events.map((event) {
                        final status = event['status']?.toString() ?? 'SCHEDULED';
                        final role = event['myRole']?.toString() ?? 'AUDIENCE';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              event['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${event['classroomCode'] ?? ''} • ${_formatDate(event['startAt'])}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Vai trò: ${_roleLabel(role)}'),
                                ],
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _statusLabel(status),
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentEventDetailScreen(
                                    eventId: (event['id'] as num?)?.toInt() ?? 0,
                                  ),
                                ),
                              );
                              if (result != null) {
                                await _loadEvents();
                              }
                            },
                          ),
                        );
                      }),
                  ],
                ),
        ),
      ),
    );
  }
}
