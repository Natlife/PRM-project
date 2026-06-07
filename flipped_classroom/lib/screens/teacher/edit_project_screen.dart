import 'package:flutter/material.dart';

class EditProjectScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  final List<String> availableClasses;

  const EditProjectScreen({
    super.key,
    required this.project,
    required this.availableClasses,
  });

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedClass;
  late TextEditingController _projectNameController;
  late TextEditingController _groupNameController;
  late TextEditingController _deadlineController;
  
  String? _selectedLeader;
  String? _selectedMemberDropdown;
  final List<String> _selectedMembers = [];

  final List<String> _mockStudents = [
    'Nguyễn Văn A',
    'Nguyễn Văn B',
    'Nguyễn Văn C',
    'Nguyễn Văn D',
    'Trần Thị B',
    'Lê Văn C',
    'Phạm Văn D',
    'Vũ Thị E',
  ];

  @override
  void initState() {
    super.initState();
    final proj = widget.project;
    _projectNameController = TextEditingController(text: proj['title'] ?? '');
    _groupNameController = TextEditingController(text: proj['group'] ?? proj['groupName'] ?? '');
    _deadlineController = TextEditingController(text: proj['date'] ?? '');
    _selectedClass = proj['className'] ?? proj['class'] ?? (widget.availableClasses.isNotEmpty ? widget.availableClasses.first : '');
    
    _selectedLeader = proj['leader'];
    if (_selectedLeader == null || !_mockStudents.contains(_selectedLeader)) {
      _selectedLeader = _mockStudents.contains('Nguyễn Văn B') ? 'Nguyễn Văn B' : _mockStudents.first;
    }

    if (proj['membersList'] != null) {
      _selectedMembers.addAll(List<String>.from(proj['membersList']));
    } else {
      _selectedMembers.addAll(['Nguyễn Văn C', 'Nguyễn Văn D']);
    }

    _selectedMemberDropdown = _mockStudents.first;
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _groupNameController.dispose();
    _deadlineController.dispose();
    super.dispose();
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
              primary: Color(0xFF5A57FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
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
      'progress': widget.project['progress'] ?? 0.0,
      'milestones': widget.project['milestones'] ?? [],
    };

    Navigator.of(context).pop(projectData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chỉnh sửa dự án',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Text(
                  _selectedClass,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Tên dự án *',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _projectNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nhập tên dự án',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  fillColor: const Color(0xFF1E293B),
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
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _groupNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nhập tên nhóm (ví dụ: Nhóm 1)',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  fillColor: const Color(0xFF1E293B),
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
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deadlineController,
                readOnly: true,
                onTap: () => _selectDate(context),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Chọn ngày hạn nộp',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  prefixIcon: const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
                  fillColor: const Color(0xFF1E293B),
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
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedLeader,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  fillColor: const Color(0xFF1E293B),
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
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addMember,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8EFF),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 14, color: Colors.white),
                    label: const Text(
                      'Thêm',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMemberDropdown,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  fillColor: const Color(0xFF1E293B),
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

              if (_selectedMembers.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
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
                              style: const TextStyle(color: Colors.white, fontSize: 14),
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
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
                        'Lưu',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
