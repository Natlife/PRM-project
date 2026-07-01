import 'package:flutter/material.dart';

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
  String _selectedFilter = 'Tất cả';

  final List<Map<String, dynamic>> _events = [
    {
      'id': '1',
      'title': 'Báo cáo tiến độ Milestone 2 - PRM393',
      'category': 'Học tập',
      'date': '02/07/2026',
      'time': '09:00 - 11:30',
      'location': 'Phòng 402, Tòa nhà Gamma',
      'instructor': 'GV. Vũ Trường Giang',
      'description': 'Tất cả các nhóm chuẩn bị slides thuyết trình và demo ứng dụng di động trên thiết bị thực hoặc máy ảo. Trình bày tiến độ phát triển các chức năng cốt lõi của ứng dụng.',
      'status': 'Sắp diễn ra',
      'statusColor': Colors.amber,
    },
    {
      'id': '2',
      'title': 'Hội thảo: Xu hướng Công nghệ Flutter 2026',
      'category': 'Hội thảo',
      'date': '05/07/2026',
      'time': '14:00 - 16:30',
      'location': 'Hội trường Alpha',
      'instructor': 'Diễn giả khách mời từ Google',
      'description': 'Chia sẻ về các tính năng mới của Flutter và Dart trong năm 2026, ứng dụng AI trong lập trình di động và cơ hội nghề nghiệp cho lập trình viên Flutter.',
      'status': 'Đã đăng ký',
      'statusColor': Colors.green,
    },
    {
      'id': '3',
      'title': 'Họp nhóm Dự án: Thống nhất thiết kế DB',
      'category': 'Nhóm',
      'date': '03/07/2026',
      'time': '19:30 - 21:00',
      'location': 'Google Meet (Online)',
      'instructor': 'Trưởng nhóm: Nguyễn Văn A',
      'description': 'Họp nhóm thảo luận và thống nhất sơ đồ thực thể mối quan hệ (ERD) và viết các script SQL khởi tạo cơ sở dữ liệu cho dự án.',
      'status': 'Đang diễn ra',
      'statusColor': Colors.redAccent,
    },
    {
      'id': '4',
      'title': 'Hạn nộp báo cáo nghiên cứu - PRW301',
      'category': 'Hạn nộp',
      'date': '04/07/2026',
      'time': 'Trước 23:59',
      'location': 'Nộp trên hệ thống Flipped',
      'instructor': 'GV. Trần Thị B',
      'description': 'Nộp báo cáo nghiên cứu công nghệ Front-end (Next.js/React) phục vụ cho dự án môn học.',
      'status': 'Hạn chót',
      'statusColor': Colors.red,
    },
    {
      'id': '5',
      'title': 'Workshop: Git & Github nâng cao cho dự án nhóm',
      'category': 'Hội thảo',
      'date': '28/06/2026',
      'time': '09:00 - 11:30',
      'location': 'Phòng 201, Tòa nhà Beta',
      'instructor': 'CLB Lập trình',
      'description': 'Hướng dẫn giải quyết conflict, quản lý branch hiệu quả, sử dụng Pull Request và Github Actions CI/CD cơ bản.',
      'status': 'Đã kết thúc',
      'statusColor': Colors.grey,
    }
  ];

  List<Map<String, dynamic>> get _filteredEvents {
    if (_selectedFilter == 'Tất cả') {
      return _events;
    }
    return _events.where((event) => event['category'] == _selectedFilter).toList();
  }

  void _showEventDetail(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (event['statusColor'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event['category'],
                      style: TextStyle(
                        color: event['statusColor'] as Color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    event['status'],
                    style: TextStyle(
                      color: event['statusColor'] as Color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                event['title'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow(Icons.calendar_today_outlined, 'Ngày:', event['date']),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.access_time, 'Thời gian:', event['time']),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.location_on_outlined, 'Địa điểm:', event['location']),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.person_outline, 'Người phụ trách/Tổ chức:', event['instructor']),
              const SizedBox(height: 20),
              const Text(
                'Mô tả chi tiết',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event['description'],
                style: TextStyle(
                  color: const Color(0xFF0F172A).withOpacity(0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7EC07E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0F172A).withOpacity(0.5)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF0F172A).withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['Tất cả', 'Học tập', 'Hội thảo', 'Nhóm', 'Hạn nộp'];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sự kiện & Lịch trình',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Theo dõi các hoạt động, sự kiện và hạn nộp quan trọng của bạn',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF0F172A).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Filter pills
        SliverToBoxAdapter(
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      }
                    },
                    selectedColor: const Color(0xFF7EC07E).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF7EC07E),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF7EC07E) : const Color(0xFF0F172A).withOpacity(0.6),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF7EC07E) : const Color(0xFF0F172A).withOpacity(0.08),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Event List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final event = _filteredEvents[index];
                final Color statusColor = event['statusColor'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _showEventDetail(event),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date box
                            Container(
                              width: 60,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    event['date'].split('/')[0],
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Th ${event['date'].split('/')[1]}',
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Event details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          event['category'],
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        event['status'],
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    event['title'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: const Color(0xFF0F172A).withOpacity(0.4),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        event['time'],
                                        style: TextStyle(
                                          color: const Color(0xFF0F172A).withOpacity(0.4),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: const Color(0xFF0F172A).withOpacity(0.4),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          event['location'],
                                          style: TextStyle(
                                            color: const Color(0xFF0F172A).withOpacity(0.4),
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                  ),
                );
              },
              childCount: _filteredEvents.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 30),
        ),
      ],
    );
  }
}
