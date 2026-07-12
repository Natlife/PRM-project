import 'package:flutter/material.dart';

import '../../../services/event_service.dart';
import '../student_event_detail_screen.dart';

class StudentEventsTab extends StatefulWidget {
  final ValueChanged<int> onTabTapped;

  const StudentEventsTab({super.key, required this.onTabTapped});

  @override
  State<StudentEventsTab> createState() => _StudentEventsTabState();
}

class _StudentEventsTabState extends State<StudentEventsTab> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _completedColor = Color(0xFF7A857F);

  bool _isLoading = true;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final events = await EventService().getStudentEvents();

      if (!mounted) {
        return;
      }

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải sự kiện: $error'),
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) {
      return '';
    }

    final String value = raw.toString().split('T').first;
    final List<String> parts = value.split('-');

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
        return _primaryColor;
      case 'COMPLETED':
        return _completedColor;
      case 'CANCELLED':
        return _errorColor;
      case 'SCHEDULED':
      default:
        return _warningColor;
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

  IconData _roleIcon(String role) {
    switch (role) {
      case 'PRESENTER':
        return Icons.record_voice_over_outlined;
      case 'REVIEWER':
        return Icons.rate_review_outlined;
      default:
        return Icons.visibility_outlined;
    }
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tất cả sự kiện',
          style: TextStyle(
            color: _textPrimaryColor,
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Xem lịch review, defense và trạng thái tham gia của bạn.',
          style: TextStyle(
            color: _textSecondaryColor,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 64, 20, 20),
      child: Column(
        children: [
          _EmptyEventIcon(),
          SizedBox(height: 22),
          Text(
            'Chưa có sự kiện',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Các sự kiện review và defense sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final Color color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        _statusLabel(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final String status = event['status']?.toString() ?? 'SCHEDULED';

    final String role = event['myRole']?.toString() ?? 'AUDIENCE';

    final String title = event['title']?.toString() ?? '';

    final String classroomCode = event['classroomCode']?.toString() ?? '';

    final String startDate = _formatDate(event['startAt']);

    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute<dynamic>(
              builder: (BuildContext context) {
                return StudentEventDetailScreen(
                  eventId: (event['id'] as num?)?.toInt() ?? 0,
                );
              },
            ),
          );

          if (result != null) {
            await _loadEvents();
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
                color: _textPrimaryColor.withValues(alpha: 0.035),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.event_outlined,
                  color: _primaryDarkColor,
                  size: 23,
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
                            title,
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
                        const SizedBox(width: 10),
                        _buildStatusChip(status),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          color: Color(0xFF8B9690),
                          size: 16,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            classroomCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textSecondaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (classroomCode.isNotEmpty &&
                            startDate.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: Color(0xFFB0B8B3),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        if (startDate.isNotEmpty) ...[
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Color(0xFF8B9690),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            startDate,
                            style: const TextStyle(
                              color: _textSecondaryColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Icon(
                          _roleIcon(role),
                          color: _primaryDarkColor,
                          size: 16,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Vai trò: ${_roleLabel(role)}',
                          style: const TextStyle(
                            color: _textSecondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 14),
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
    );
  }

  Widget _buildEventList() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      itemCount: _events.length + 1,
      separatorBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return const SizedBox(height: 22);
        }

        return const SizedBox(height: 12);
      },
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return _buildHeader();
        }

        return _buildEventCard(_events[index - 1]);
      },
    );
  }

  Widget _buildEmptyEventList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      children: [_buildHeader(), _buildEmptyState()],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEvents,
          color: _primaryColor,
          backgroundColor: _surfaceColor,
          child: _isLoading
              ? _buildLoadingState()
              : _events.isEmpty
              ? _buildEmptyEventList()
              : _buildEventList(),
        ),
      ),
    );
  }
}

class _EmptyEventIcon extends StatelessWidget {
  const _EmptyEventIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Icon(
        Icons.event_busy_outlined,
        color: Color(0xFF167A52),
        size: 40,
      ),
    );
  }
}
