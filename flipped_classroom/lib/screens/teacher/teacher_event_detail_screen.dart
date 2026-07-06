import 'package:flutter/material.dart';

class TeacherEventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const TeacherEventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<TeacherEventDetailScreen> createState() => _TeacherEventDetailScreenState();
}

class _TeacherEventDetailScreenState extends State<TeacherEventDetailScreen> {
  late String _status;
  late String _eventTitle;
  late String _classCode;
  late String _date;
  late String _duration;
  late String _description;

  // Question Bank
  final List<String> _questionBank = [
    'Bạn có thể giải thích widget này là gì và vì sao bạn dùng không?',
    'Bạn có thể sửa button này thành màu xanh được không?',
    'Tại sao kiến trúc này tối ưu hơn MVC?',
    'Làm thế nào để ứng dụng tối ưu hóa dung lượng bộ nhớ cache?',
    'Nhóm đã giải quyết vấn đề bảo mật thông tin người dùng như thế nào?',
  ];

  // Mock Students
  final List<String> _mockStudents = [
    'Nguyễn Minh Anh',
    'Lê Hoàng Cường',
    'Nguyễn Vân Anh',
    'Trần Minh Quân',
    'Đỗ Hồng Hạnh',
    'Vũ Quốc Bảo',
  ];

  // Studen Groups
  final List<Map<String, dynamic>> _groups = [
    {
      'name': 'Nhóm 1',
      'leader': 'Nguyễn Minh Anh',
      'members': ['Nguyễn Minh Anh', 'Lê Hoàng Cường'],
    }
  ];

  // Assignment List
  final List<Map<String, dynamic>> _assignments = [
    {
      'id': '1',
      'type': 'Cá nhân',
      'presenter': 'Nguyễn Minh Anh',
      'reviewer': 'Lê Hoàng Cường',
      'groupName': '',
      'documentName': 'file_1.pdf',
      'status': 'Chưa review',
      'duration': '20',
      'questions': <String>[
        'Bạn có thể giải thích widget này là gì và vì sao bạn dùng không?',
      ],
    }
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.event['status'] ?? 'Chưa diễn ra';
    _eventTitle = widget.event['title'] ?? 'Thuyết trình Dự án STEM';
    _classCode = widget.event['classCode'] ?? 'PRM393 - SE1904';
    _date = widget.event['date'] ?? '25/06/2026';
    _duration = widget.event['duration'] ?? '20';
    _description = widget.event['description'] ?? 'Lớp chia thành 4 nhóm và ra đề bài cho nhau';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đang diễn ra':
        return Colors.green;
      case 'Đã diễn ra':
        return Colors.grey;
      case 'Chưa diễn ra':
      default:
        return Colors.orange;
    }
  }

  // Popup: Create Group (Tạo nhóm mới)
  void _showCreateGroupDialog(StateSetter parentDialogState) {
    final nameController = TextEditingController();
    String leader = _mockStudents.first;
    final List<String> selectedMembers = [_mockStudents.first];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setGroupState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'Tạo nhóm mới',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tên nhóm *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Nhóm 1',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Chọn trưởng nhóm *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: leader,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _mockStudents.map((name) {
                        return DropdownMenuItem<String>(value: name, child: Text(name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setGroupState(() {
                            leader = val;
                            if (!selectedMembers.contains(val)) {
                              selectedMembers.add(val);
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Chọn thành viên *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ..._mockStudents.map((name) {
                      final isSelected = selectedMembers.contains(name);
                      return CheckboxListTile(
                        title: Text(name, style: const TextStyle(fontSize: 14)),
                        value: isSelected,
                        activeColor: const Color(0xFF7EC07E),
                        onChanged: (bool? checked) {
                          setGroupState(() {
                            if (checked == true) {
                              if (!selectedMembers.contains(name)) selectedMembers.add(name);
                            } else {
                              if (name != leader) selectedMembers.remove(name);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF0F172A).withValues(alpha: 0.5)),
                  child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập tên nhóm!'), backgroundColor: Colors.orange),
                      );
                      return;
                    }
                    if (selectedMembers.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng chọn ít nhất một thành viên!'), backgroundColor: Colors.orange),
                      );
                      return;
                    }
                    setState(() {
                      _groups.add({
                        'name': name,
                        'leader': leader,
                        'members': selectedMembers,
                      });
                    });
                    parentDialogState(() {});
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tạo nhóm thành công!'), backgroundColor: Color(0xFF7EC07E)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7EC07E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Popup: Assign Student (Phân công sinh viên) with 2 Tabs
  void _showAssignmentDialog({int? index}) {
    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              // Individual Tab state variables
              String indPresenter = _mockStudents.first;
              String indReviewer = _mockStudents[1];

              // Group Tab state variables
              Map<String, dynamic>? selectedGroup = _groups.isNotEmpty ? _groups.first : null;
              String groupPresenter = selectedGroup != null ? (selectedGroup['members'] as List).first : _mockStudents.first;
              String groupReviewer = _mockStudents[1];

              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  index == null ? 'Phân công học viên' : 'Chỉnh sửa phân công',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const TabBar(
                        labelColor: Color(0xFF7EC07E),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Color(0xFF7EC07E),
                        tabs: [
                          Tab(text: 'Cá nhân'),
                          Tab(text: 'Nhóm'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: SizedBox(
                          height: 280,
                          child: TabBarView(
                            children: [
                              // Tab 1: Cá nhân (Individual)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Chọn người thuyết trình *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: indPresenter,
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(color: Color(0xFF0F172A)),
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    items: _mockStudents.map((name) {
                                      return DropdownMenuItem<String>(value: name, child: Text(name));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setDialogState(() => indPresenter = val);
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Chọn người phản biện *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: indReviewer,
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(color: Color(0xFF0F172A)),
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    items: _mockStudents.map((name) {
                                      return DropdownMenuItem<String>(value: name, child: Text(name));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setDialogState(() => indReviewer = val);
                                    },
                                  ),
                                ],
                              ),

                              // Tab 2: Nhóm (Group)
                              SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Chọn nhóm *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                                        TextButton(
                                          onPressed: () {
                                            _showCreateGroupDialog(setDialogState);
                                          },
                                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF7EC07E)),
                                          child: const Text('+ Tạo nhóm mới', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<Map<String, dynamic>>(
                                      value: selectedGroup,
                                      dropdownColor: Colors.white,
                                      style: const TextStyle(color: Color(0xFF0F172A)),
                                      decoration: InputDecoration(
                                        fillColor: Colors.white,
                                        filled: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      items: _groups.map((group) {
                                        return DropdownMenuItem<Map<String, dynamic>>(
                                          value: group,
                                          child: Text(group['name'] ?? ''),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setDialogState(() {
                                            selectedGroup = val;
                                            groupPresenter = (val['members'] as List).first;
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('Chọn người đại diện thuyết trình *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: groupPresenter,
                                      dropdownColor: Colors.white,
                                      style: const TextStyle(color: Color(0xFF0F172A)),
                                      decoration: InputDecoration(
                                        fillColor: Colors.white,
                                        filled: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      items: selectedGroup != null
                                          ? (selectedGroup!['members'] as List).map((name) {
                                              return DropdownMenuItem<String>(value: name.toString(), child: Text(name.toString()));
                                            }).toList()
                                          : _mockStudents.map((name) {
                                              return DropdownMenuItem<String>(value: name, child: Text(name));
                                            }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setDialogState(() => groupPresenter = val);
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    const Text('Chọn người phản biện *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: groupReviewer,
                                      dropdownColor: Colors.white,
                                      style: const TextStyle(color: Color(0xFF0F172A)),
                                      decoration: InputDecoration(
                                        fillColor: Colors.white,
                                        filled: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      items: _mockStudents.map((name) {
                                        return DropdownMenuItem<String>(value: name, child: Text(name));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setDialogState(() => groupReviewer = val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                actions: [
                  if (index != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _assignments.removeAt(index);
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã xóa phân công!'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF0F172A).withValues(alpha: 0.5)),
                    child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final isTabGroup = DefaultTabController.of(context).index == 1;
                      final String presenter = isTabGroup ? groupPresenter : indPresenter;
                      final String reviewer = isTabGroup ? groupReviewer : indReviewer;

                      if (presenter == reviewer) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Người thuyết trình và Người phản biện không được trùng nhau!'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
                        );
                        return;
                      }

                      setState(() {
                        final newAssignment = {
                          'id': index == null ? DateTime.now().millisecondsSinceEpoch.toString() : _assignments[index]['id'],
                          'type': isTabGroup ? 'Nhóm' : 'Cá nhân',
                          'presenter': presenter,
                          'reviewer': reviewer,
                          'groupName': isTabGroup ? (selectedGroup != null ? selectedGroup!['name'] : '') : '',
                          'documentName': isTabGroup ? 'doc_group_presentation.pdf' : 'file_presentation.pdf',
                          'status': index == null ? 'Chưa review' : _assignments[index]['status'],
                          'duration': _duration,
                          'questions': index == null ? <String>[] : _assignments[index]['questions'],
                        };

                        if (index == null) {
                          _assignments.add(newAssignment);
                        } else {
                          _assignments[index] = newAssignment;
                        }
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(index == null ? 'Phân công thành công!' : 'Cập nhật phân công thành công!'), backgroundColor: const Color(0xFF7EC07E), behavior: SnackBarBehavior.floating),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7EC07E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // Popup: Assignment Detail (Chi tiết phân công)
  void _showAssignmentDetailDialog(Map<String, dynamic> assignment) {
    showDialog(
      context: context,
      builder: (context) {
        final presenter = assignment['presenter'] ?? '';
        final reviewer = assignment['reviewer'] ?? '';
        final docName = assignment['documentName'] ?? 'file_1.pdf';
        final groupName = assignment['groupName'] ?? '';
        final isGroup = (groupName as String).isNotEmpty;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chi tiết phân công',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isGroup) ...[
                const Text('Nhóm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(groupName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 14),
              ],
              const Text('Người thuyết trình', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(presenter, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              const SizedBox(height: 14),
              const Text('Người phản biện', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(reviewer, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              const SizedBox(height: 14),
              const Text('Tài liệu sinh viên thuyết trình upload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        docName,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF334155), overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đang hiển thị tài liệu $docName'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7EC07E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Xem', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF7EC07E)),
              child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Popup: Event Evaluation Results (Xem kết quả)
  void _showResultsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Kết quả đánh giá sự kiện',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _assignments.length,
              itemBuilder: (context, index) {
                final item = _assignments[index];
                final presenter = item['presenter'] ?? '';
                final reviewer = item['reviewer'] ?? '';
                final docName = item['documentName'] ?? 'file_1.pdf';
                final groupName = item['groupName'] ?? '';
                final isGroup = (groupName as String).isNotEmpty;
                final questionsCount = (item['questions'] as List?)?.length ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGroup ? groupName : presenter,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Người thuyết trình: $presenter',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'Người phản biện: $reviewer',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Số câu hỏi: $questionsCount',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7EC07E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Điểm: 8.5/10',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7EC07E)),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      // Document row
                      Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              docName,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF334155), overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Đang hiển thị tài liệu $docName'), behavior: SnackBarBehavior.floating),
                              );
                            },
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                            child: const Text('Xem tài liệu', style: TextStyle(fontSize: 11, color: Color(0xFF7EC07E), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // View Recording Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Close results dialog
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TeacherEventReviewScreen(
                                  eventTitle: _eventTitle,
                                  classCode: _classCode,
                                  assignment: item,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_circle_outline, size: 16, color: Colors.white),
                          label: const Text('Xem lại bản ghi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF7EC07E)),
              child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Popup: Question Bank Manager
  void _showQuestionBankDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Danh sách câu hỏi',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _showCreateQuestionDialog(setDialogState);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7EC07E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Tạo mới', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _questionBank.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _questionBank[index],
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    setDialogState(() {
                                      _questionBank.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF7EC07E)),
                  child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateQuestionDialog(StateSetter parentSetState) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Tạo câu hỏi mới',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          content: TextField(
            controller: textController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Nhập câu hỏi...',
              hintStyle: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final txt = textController.text.trim();
                if (txt.isNotEmpty) {
                  setState(() {
                    _questionBank.insert(0, txt);
                  });
                  parentSetState(() {});
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7EC07E), foregroundColor: Colors.white),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _getStatusColor(_status);

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
          'Chi tiết sự kiện',
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
            // Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        _classCode,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _eventTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _date,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF0F172A).withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _description,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF0F172A).withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                  const Divider(height: 24, thickness: 1),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$_duration phút/phiên',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7EC07E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Operations Panel
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quản lý sự kiện',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_status == 'Đã diễn ra') ...[
                    _buildManagementButton('Xem kết quả', Icons.analytics_outlined, () {
                      _showResultsDialog();
                    }),
                  ] else ...[
                    if (_status == 'Chưa diễn ra') ...[
                      _buildManagementButton('Phân công sinh viên', Icons.person_add_alt_1_outlined, () {
                        _showAssignmentDialog();
                      }),
                      const SizedBox(height: 12),
                    ],
                    _buildManagementButton('Mở điều khiển sự kiện', Icons.settings_remote_outlined, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherEventControlScreen(
                            eventTitle: _eventTitle,
                            classCode: _classCode,
                            assignments: _assignments,
                            questionBank: _questionBank,
                          ),
                        ),
                      ).then((value) => setState(() {}));
                    }),
                    const SizedBox(height: 12),
                    _buildManagementButton('Ngân hàng câu hỏi', Icons.question_answer_outlined, () {
                      _showQuestionBankDialog();
                    }),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Assignment List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Danh sách phân công',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _showAssignmentDialog();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Chỉnh sửa',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_assignments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.04)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 40, color: const Color(0xFF0F172A).withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text(
                      'Danh sách phân công trống',
                      style: TextStyle(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.4),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._assignments.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final presenter = item['presenter'] ?? '';
                final groupName = item['groupName'] ?? '';
                final isGroup = (groupName as String).isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.06)),
                  ),
                  child: InkWell(
                    onTap: () => _showAssignmentDetailDialog(item),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isGroup ? Icons.group : Icons.person,
                            color: const Color(0xFF2563EB),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isGroup ? '$groupName ($presenter)' : item['presenter'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Phản biện: ${item['reviewer'] ?? ""}',
                                style: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 14, color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xFF0F172A), size: 18),
        label: Text(
          label,
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF1F5F9),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
          ),
        ),
      ),
    );
  }
}

// Screen: Event Control (Điều khiển sự kiện)
class TeacherEventControlScreen extends StatefulWidget {
  final String eventTitle;
  final String classCode;
  final List<Map<String, dynamic>> assignments;
  final List<String> questionBank;

  const TeacherEventControlScreen({
    super.key,
    required this.eventTitle,
    required this.classCode,
    required this.assignments,
    required this.questionBank,
  });

  @override
  State<TeacherEventControlScreen> createState() => _TeacherEventControlScreenState();
}

class _TeacherEventControlScreenState extends State<TeacherEventControlScreen> {
  @override
  Widget build(BuildContext context) {
    final pendingAssignments = widget.assignments.where((item) => item['status'] != 'Đã review').toList();
    final completedAssignments = widget.assignments.where((item) => item['status'] == 'Đã review').toList();

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
          'Điều khiển phòng phản biện',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Details Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.eventTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.classCode,
                    style: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: Chưa được review (Chưa thuyết trình)
            const Text(
              'Danh sách chưa review',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            if (pendingAssignments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: const Text('Tất cả học viên đã thuyết trình', style: TextStyle(color: Colors.grey)),
              )
            else
              ...pendingAssignments.map((assignment) {
                final presenter = assignment['presenter'] ?? '';
                final reviewer = assignment['reviewer'] ?? '';
                final groupName = assignment['groupName'] ?? '';
                final isGroup = (groupName as String).isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isGroup ? '$groupName ($presenter)' : presenter,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Phản biện: $reviewer',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeacherRecordingScreen(
                                eventTitle: widget.eventTitle,
                                classCode: widget.classCode,
                                assignment: assignment,
                                questionBank: widget.questionBank,
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7EC07E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Bắt đầu', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 24),

            // Section: Đã được review
            const Text(
              'Danh sách đã review',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            if (completedAssignments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: const Text('Chưa có học viên nào hoàn thành', style: TextStyle(color: Colors.grey)),
              )
            else
              ...completedAssignments.map((assignment) {
                final presenter = assignment['presenter'] ?? '';
                final reviewer = assignment['reviewer'] ?? '';
                final groupName = assignment['groupName'] ?? '';
                final isGroup = (groupName as String).isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isGroup ? '$groupName ($presenter)' : presenter,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Phản biện: $reviewer',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeacherEventReviewScreen(
                                eventTitle: widget.eventTitle,
                                classCode: widget.classCode,
                                assignment: assignment,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Xem lại', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// Screen: Recording Screen (Màn ghi hình)
class TeacherRecordingScreen extends StatefulWidget {
  final String eventTitle;
  final String classCode;
  final Map<String, dynamic> assignment;
  final List<String> questionBank;

  const TeacherRecordingScreen({
    super.key,
    required this.eventTitle,
    required this.classCode,
    required this.assignment,
    required this.questionBank,
  });

  @override
  State<TeacherRecordingScreen> createState() => _TeacherRecordingScreenState();
}

class _TeacherRecordingScreenState extends State<TeacherRecordingScreen> {
  bool _isRecording = false;
  int _secondsElapsed = 0;
  JavaTimer? _timer;
  late List<String> _currentQuestions;

  @override
  void initState() {
    super.initState();
    _currentQuestions = List<String>.from(widget.assignment['questions'] ?? []);
    // Start recording immediately
    _isRecording = true;
    _startTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _timer = JavaTimer(
      periodic: true,
      duration: const Duration(seconds: 1),
      onTick: () {
        setState(() {
          _secondsElapsed++;
        });
      },
    );
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatDuration(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Popup: Ask Question (Đặt câu hỏi)
  void _showAskQuestionDialog() {
    String selectedQuestion = widget.questionBank.first;
    final textController = TextEditingController(text: selectedQuestion);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setAskState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'Đặt câu hỏi',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chọn câu hỏi từ ngân hàng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedQuestion,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: widget.questionBank.map((q) {
                        return DropdownMenuItem<String>(
                          value: q,
                          child: Text(q, overflow: TextOverflow.ellipsis, maxLines: 1),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setAskState(() {
                            selectedQuestion = val;
                            textController.text = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Nội dung câu hỏi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final txt = textController.text.trim();
                    if (txt.isNotEmpty) {
                      setState(() {
                        _currentQuestions.add(txt);
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7EC07E), foregroundColor: Colors.white),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final presenter = widget.assignment['presenter'] ?? '';
    final reviewer = widget.assignment['reviewer'] ?? '';
    final docName = widget.assignment['documentName'] ?? 'file_1.pdf';
    final groupName = widget.assignment['groupName'] ?? '';
    final isGroup = (groupName as String).isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A)),
          onPressed: () {
            // Confirm exit
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Thoát ghi hình?'),
                content: const Text('Bạn có chắc muốn thoát? Tiến trình ghi hình sẽ không được lưu.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Thoát'),
                  ),
                ],
              ),
            );
          },
        ),
        title: const Text(
          'Ghi hình thuyết trình',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timer card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ĐANG GHI HÌNH',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatDuration(_secondsElapsed),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Presenter Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Người/Nhóm thuyết trình', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    isGroup ? '$groupName ($presenter)' : presenter,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 14),
                  const Text('Người phản biện', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(reviewer, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            docName,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF334155), overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đang hiển thị tài liệu $docName'), behavior: SnackBarBehavior.floating),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7EC07E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Xem', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live Questions list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Câu hỏi đã đặt',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                ElevatedButton.icon(
                  onPressed: _showAskQuestionDialog,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Đặt câu hỏi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7EC07E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_currentQuestions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: const Text('Chưa có câu hỏi nào được đặt', style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            else
              ..._currentQuestions.map((q) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.04)),
                    ),
                    child: Text(q, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                  )),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _stopTimer();
                  setState(() {
                    widget.assignment['status'] = 'Đã review';
                    widget.assignment['questions'] = _currentQuestions;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lưu bản ghi thành công!'), backgroundColor: Color(0xFF7EC07E)),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9E2C2C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kết thúc phiên & Lưu bản ghi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Screen: Event Review (Xem lại bản ghi)
class TeacherEventReviewScreen extends StatelessWidget {
  final String eventTitle;
  final String classCode;
  final Map<String, dynamic> assignment;

  const TeacherEventReviewScreen({
    super.key,
    required this.eventTitle,
    required this.classCode,
    required this.assignment,
  });

  @override
  Widget build(BuildContext context) {
    final presenter = assignment['presenter'] ?? '';
    final groupName = assignment['groupName'] ?? '';
    final isGroup = (groupName as String).isNotEmpty;
    final List<dynamic> questions = assignment['questions'] ?? [];

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
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player Container Mock
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Play button icon
                  const Icon(Icons.play_circle_outline, color: Colors.white, size: 64),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('00:00 / 15:42', style: TextStyle(color: Colors.white, fontSize: 11)),
                        Expanded(
                          child: Slider(
                            value: 0,
                            onChanged: (val) {},
                            activeColor: const Color(0xFF7EC07E),
                            inactiveColor: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Event Details
            Text(
              isGroup ? '$groupName - $presenter' : presenter,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              '$eventTitle • $classCode',
              style: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.5), fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Question List
            const Text(
              'Câu hỏi đã đặt',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),

            if (questions.isEmpty)
              const Text('Không có câu hỏi nào được đặt trong bản ghi hình này', style: TextStyle(color: Colors.grey, fontSize: 13))
            else
              ...questions.map((q) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
                    ),
                    child: Text(q.toString(), style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                  )),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang tải bản ghi hình...'), behavior: SnackBarBehavior.floating),
                  );
                },
                icon: const Icon(Icons.file_download, color: Colors.white),
                label: const Text('Tải bản ghi hình', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7EC07E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple periodic timer wrapper for compatibility and safety
class JavaTimer {
  final bool periodic;
  final Duration duration;
  final VoidCallback onTick;
  bool _cancelled = false;

  JavaTimer({
    required this.periodic,
    required this.duration,
    required this.onTick,
  }) {
    _run();
  }

  void _run() async {
    while (!_cancelled) {
      await Future.delayed(duration);
      if (_cancelled) break;
      onTick();
      if (!periodic) break;
    }
  }

  void cancel() {
    _cancelled = true;
  }
}
