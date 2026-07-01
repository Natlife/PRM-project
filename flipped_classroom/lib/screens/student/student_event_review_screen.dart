import 'package:flutter/material.dart';

class StudentEventReviewScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const StudentEventReviewScreen({
    super.key,
    required this.event,
  });

  @override
  State<StudentEventReviewScreen> createState() => _StudentEventReviewScreenState();
}

class _StudentEventReviewScreenState extends State<StudentEventReviewScreen> {
  final List<Map<String, String>> _questions = [
    {
      'author': 'Lê Hoàng Cường',
      'content': 'Bạn có thể đổi button thành màu xanh được không?',
    },
    {
      'author': 'GV. Vũ Trường Giang',
      'content': 'Cơ chế đồng bộ dữ liệu ngoại tuyến (offline sync) hoạt động như thế nào trong thiết kế hiện tại?',
    },
    {
      'author': 'Nguyễn Minh Anh',
      'content': 'Thời gian phản hồi trung bình của API khi tải danh sách lớp học là bao nhiêu?',
    },
  ];

  bool _isPlayingVideo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Xem lại sự kiện',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event General Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event['title'] ?? 'Thuyết trình Dự án STEM',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.event['classCode'] ?? 'PRM - SE1904',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF0F172A).withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ngày thực hiện: ${widget.event['date'] ?? "25/6/2026"}',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF0F172A).withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Section Title: Câu hỏi
            const Text(
              'Câu hỏi đã đặt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            // Questions list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(0xFF7EC07E),
                            child: Icon(Icons.person, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            question['author'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        question['content'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF0F172A).withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Simulated Video Player
            if (_isPlayingVideo)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Simulated loading/playing screen
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7EC07E)),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Đang phát bản ghi hình thuyết trình...',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isPlayingVideo = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isPlayingVideo = true;
                    });
                  },
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text(
                    'Xem lại bản ghi hình',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7EC07E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
