import 'package:flutter/material.dart';

class StudentPeerReviewScreen extends StatefulWidget {
  final String classCode;

  const StudentPeerReviewScreen({
    super.key,
    required this.classCode,
  });

  @override
  State<StudentPeerReviewScreen> createState() => _StudentPeerReviewScreenState();
}

class _StudentPeerReviewScreenState extends State<StudentPeerReviewScreen> {
  // Mock peer groups in the same class (excluding current student's group, Nhóm 1)
  final List<Map<String, dynamic>> _peerGroups = [
    {
      'id': 'g_2',
      'name': 'Nhóm 2',
      'projectName': 'Hệ thống Quản lý Thư viện',
      'members': ['Phạm Minh E', 'Lâm Thùy F', 'Đỗ Hoàng G'],
      'description': 'Ứng dụng di động giúp sinh viên tra cứu, mượn trả sách, quét mã vạch và nhận thông báo nhắc nhở hạn trả sách tự động.',
      'scoreCode': 0.0,
      'scoreUI': 0.0,
      'scoreFeature': 0.0,
      'scorePresentation': 0.0,
      'comment': '',
      'isSubmitted': false,
    },
    {
      'id': 'g_3',
      'name': 'Nhóm 3',
      'projectName': 'Mạng xã hội học tập FPT',
      'members': ['Hoàng Văn H', 'Trần Mỹ I', 'Vũ Quốc K'],
      'description': 'Nền tảng mạng xã hội thu nhỏ cho phép sinh viên trao đổi bài tập, tạo nhóm tự học và chia sẻ tài liệu ôn thi các môn học.',
      'scoreCode': 0.0,
      'scoreUI': 0.0,
      'scoreFeature': 0.0,
      'scorePresentation': 0.0,
      'comment': '',
      'isSubmitted': false,
    },
    {
      'id': 'g_4',
      'name': 'Nhóm 4',
      'projectName': 'App Đặt món ăn Canteen',
      'members': ['Nguyễn Văn L', 'Lê Thị M', 'Bùi Văn N'],
      'description': 'Hệ thống đặt món ăn trực tuyến tại canteen trường giúp sinh viên đặt trước món ăn, thanh toán online và xếp hàng nhận món nhanh chóng.',
      'scoreCode': 0.0,
      'scoreUI': 0.0,
      'scoreFeature': 0.0,
      'scorePresentation': 0.0,
      'comment': '',
      'isSubmitted': false,
    }
  ];

  int? _selectedGroupIndex;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _selectGroup(int index) {
    setState(() {
      _selectedGroupIndex = index;
      _commentController.text = _peerGroups[index]['comment'] ?? '';
    });
  }

  Widget _buildStarRating(String label, double currentScore, Function(double) onRatingChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
            ),
            Text(
              currentScore == 0.0 ? 'Chưa chấm' : '${currentScore.toStringAsFixed(1)} / 5.0',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: currentScore == 0.0 ? Colors.grey : const Color(0xFF7EC07E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(5, (starIndex) {
            final double starValue = starIndex + 1.0;
            return GestureDetector(
              onTap: () => onRatingChanged(starValue),
              child: Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Icon(
                  starValue <= currentScore
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: starValue <= currentScore ? Colors.amber : const Color(0xFFCBD5E1),
                  size: 30,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _submitReview() {
    if (_selectedGroupIndex == null) return;
    final index = _selectedGroupIndex!;
    final group = _peerGroups[index];

    if (group['scoreCode'] == 0.0 ||
        group['scoreUI'] == 0.0 ||
        group['scoreFeature'] == 0.0 ||
        group['scorePresentation'] == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đánh giá đủ 4 tiêu chí sao!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      group['comment'] = _commentController.text.trim();
      group['isSubmitted'] = true;
      _selectedGroupIndex = null; // Return to list view
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã gửi đánh giá chéo cho ${group['name']} thành công!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF7EC07E),
      ),
    );
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
          onPressed: () {
            if (_selectedGroupIndex != null) {
              setState(() {
                _selectedGroupIndex = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _selectedGroupIndex != null ? 'Đánh giá chi tiết' : 'Đánh giá chéo nhóm khác',
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
        child: _selectedGroupIndex == null ? _buildGroupsList() : _buildGroupReviewDetail(),
      ),
    );
  }

  Widget _buildGroupsList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      itemCount: _peerGroups.length,
      itemBuilder: (context, index) {
        final group = _peerGroups[index];
        final isSubmitted = group['isSubmitted'] == true;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSubmitted
                    ? const Color(0xFF7EC07E).withOpacity(0.3)
                    : const Color(0xFF0F172A).withOpacity(0.05),
              ),
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
              onTap: () => _selectGroup(index),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSubmitted
                            ? const Color(0xFF7EC07E).withOpacity(0.12)
                            : const Color(0xFF0F172A).withOpacity(0.04),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isSubmitted ? Icons.check_circle : Icons.group_outlined,
                          color: isSubmitted ? const Color(0xFF7EC07E) : const Color(0xFF0F172A).withOpacity(0.5),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                group['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (isSubmitted)
                                const Text(
                                  'Đã đánh giá',
                                  style: TextStyle(
                                    color: Color(0xFF7EC07E),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            group['projectName'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF0F172A).withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Thành viên: ${group['members'].join(', ')}',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF0F172A).withOpacity(0.4),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupReviewDetail() {
    final index = _selectedGroupIndex!;
    final group = _peerGroups[index];
    final isSubmitted = group['isSubmitted'] == true;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group name and project details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF7EC07E)),
                ),
                const SizedBox(height: 6),
                Text(
                  group['projectName'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Thành viên:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  group['members'].join(', '),
                  style: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.6), fontSize: 13),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mô tả dự án:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  group['description'] ?? '',
                  style: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.6), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Chấm điểm & Nhận xét',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),

          // Rating sliders/stars
          _buildStarRating(
            'Chất lượng Mã nguồn (Code Quality)',
            group['scoreCode'],
            isSubmitted ? (_) {} : (val) => setState(() => group['scoreCode'] = val),
          ),
          _buildStarRating(
            'Giao diện & Trải nghiệm (UI/UX)',
            group['scoreUI'],
            isSubmitted ? (_) {} : (val) => setState(() => group['scoreUI'] = val),
          ),
          _buildStarRating(
            'Tính năng ứng dụng (App Features)',
            group['scoreFeature'],
            isSubmitted ? (_) {} : (val) => setState(() => group['scoreFeature'] = val),
          ),
          _buildStarRating(
            'Thuyết trình & Slide (Presentation)',
            group['scorePresentation'],
            isSubmitted ? (_) {} : (val) => setState(() => group['scorePresentation'] = val),
          ),

          // Review Comments Text Field
          const Text(
            'Ý kiến nhận xét chi tiết:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.1)),
            ),
            child: TextField(
              controller: _commentController,
              enabled: !isSubmitted,
              maxLines: 4,
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: isSubmitted ? 'Không có nhận xét nào.' : 'Nhập nhận xét chi tiết cho nhóm...',
                hintStyle: TextStyle(color: const Color(0xFF0F172A).withOpacity(0.3)),
                border: InputBorder.none,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Submit Button
          if (!isSubmitted)
            ElevatedButton(
              onPressed: _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7EC07E),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Gửi đánh giá',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7EC07E).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF7EC07E).withOpacity(0.3)),
              ),
              child: const Center(
                child: Text(
                  'Bạn đã hoàn thành đánh giá chéo cho nhóm này!',
                  style: TextStyle(color: Color(0xFF7EC07E), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
