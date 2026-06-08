import 'package:flutter/material.dart';

class CreateProjectScreen extends StatefulWidget {
  final String? fixedClass;
  final List<String> availableClasses;

  const CreateProjectScreen({
    super.key,
    this.fixedClass,
    required this.availableClasses,
  });

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClass;
  final _projectNameController = TextEditingController();
  final _groupNameController = TextEditingController();
  final _deadlineController = TextEditingController();
  
  String? _selectedLeader;
  String? _selectedMemberDropdown;
  final List<String> _selectedMembers = [];

  final List<String> _mockStudents = [
    'Nguyễn Văn A',
    'Trần Thị B',
    'Lê Văn C',
    'Phạm Văn D',
    'Vũ Thị E',
    'Hoàng Văn F',
    'Đỗ Thị G',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.fixedClass != null) {
      _selectedClass = widget.fixedClass;
    } else if (widget.availableClasses.isNotEmpty) {
      _selectedClass = widget.availableClasses.first;
    }
    _selectedLeader = _mockStudents.first;
    _selectedMemberDropdown = _mockStudents.first;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime tomorrow = now.add(const Duration(days: 1));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF7EC07E),
              onPrimary: Colors.white,
              surface: Color(0xFFFFFFFF),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _deadlineController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _addMember() {
    if (_selectedMemberDropdown == null) return;
    if (_selectedMembers.contains(_selectedMemberDropdown!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thành viên này đã có trong danh sách!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _selectedMembers.add(_selectedMemberDropdown!);
    });
  }

  void _removeMember(String member) {
    setState(() {
      _selectedMembers.remove(member);
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất một thành viên vào nhóm!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final projectData = {
      'title': _projectNameController.text.trim(),
      'group': _groupNameController.text.trim(),
      'groupName': _groupNameController.text.trim(),
      'className': _selectedClass,
      'class': _selectedClass,
      'date': _deadlineController.text,
      'leader': _selectedLeader,
      'members': '${_selectedMembers.length} sinh viên',
      'membersList': _selectedMembers,
      'progress': 0.0,
      'milestones': <Map<String, dynamic>>[],
    };

    Navigator.of(context).pop(projectData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tạo dự án mới',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lớp học *',
                style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (widget.fixedClass != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.05)),
                  ),
                  child: Text(
                    widget.fixedClass!,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedClass,
                  dropdownColor: const Color(0xFFFFFFFF),
                  style: const TextStyle(color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    fillColor: const Color(0xFFFFFFFF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: widget.availableClasses.map((cls) {
                    return DropdownMenuItem<String>(
                      value: cls,
                      child: Text(cls),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedClass = val),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Vui lòng chọn lớp học';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 18),

              const Text(
                'Tên dự án *',
                style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _projectNameController,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Nhập tên dự án',
                  hintStyle: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                  fillColor: const Color(0xFFFFFFFF),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Tên dự án là bắt buộc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              const Text(
                'Tên nhóm',
                style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _groupNameController,
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Nhập tên nhóm (ví dụ: Nhóm 1)',
                  hintStyle: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                  fillColor: const Color(0xFFFFFFFF),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Hạn nộp *',
                style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deadlineController,
                readOnly: true,
                onTap: () => _selectDate(context),
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Chọn ngày hạn nộp',
                  hintStyle: TextStyle(color: const Color(0xFF0F172A).withValues(alpha: 0.3)),
                  prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF334155), size: 18),
                  fillColor: const Color(0xFFFFFFFF),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Hạn nộp là bắt buộc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              const Text(
                'Nhóm trưởng',
                style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedLeader,
                dropdownColor: const Color(0xFFFFFFFF),
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  fillColor: const Color(0xFFFFFFFF),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _mockStudents.map((student) {
                  return DropdownMenuItem<String>(
                    value: student,
                    child: Text(student),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedLeader = val),
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thành viên',
                    style: TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addMember,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7EC07E),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 14, color: Color(0xFF0F172A)),
                    label: const Text(
                      'Thêm',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedMemberDropdown,
                dropdownColor: const Color(0xFFFFFFFF),
                style: const TextStyle(color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  fillColor: const Color(0xFFFFFFFF),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _mockStudents.map((student) {
                  return DropdownMenuItem<String>(
                    value: student,
                    child: Text(student),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedMemberDropdown = val),
              ),
              const SizedBox(height: 12),

              // Selected Members list representation
              if (_selectedMembers.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.04)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedMembers.length,
                    itemBuilder: (context, index) {
                      final member = _selectedMembers[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              member,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFEC4899), size: 20),
                              onPressed: () => _removeMember(member),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC4899),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Tạo mới',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
