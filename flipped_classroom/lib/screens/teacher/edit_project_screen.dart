import 'package:flutter/material.dart';
import '../../services/classroom_service.dart';
import '../../services/project_service.dart';

class EditProjectScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  final int classroomId;
  final String classLabel;

  const EditProjectScreen({
    super.key,
    required this.project,
    required this.classroomId,
    required this.classLabel,
  });

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _projectNameController;
  late final TextEditingController _groupNameController;
  late final TextEditingController _descriptionController;

  List<Map<String, dynamic>> _students = [];
  List<int> _selectedStudentIds = [];
  int? _selectedLeaderId;
  int? _selectedMemberId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _projectNameController = TextEditingController(
      text: widget.project['projectName'] ?? widget.project['title'] ?? '',
    );
    _groupNameController = TextEditingController(
      text: widget.project['groupName'] ?? widget.project['group'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.project['description'] ?? '',
    );
    _hydrateSelectedMembers();
    _loadStudents();
  }

  void _hydrateSelectedMembers() {
    final membersData = widget.project['membersData'] as List<dynamic>?;
    if (membersData != null && membersData.isNotEmpty) {
      _selectedStudentIds = membersData
          .map((member) => (member['id'] as num?)?.toInt())
          .whereType<int>()
          .toList();
    }
    _selectedLeaderId = (widget.project['leaderData']?['id'] as num?)?.toInt();
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _groupNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await ClassroomService().getTeacherClassroomStudents(
        widget.classroomId,
      );
      if (!mounted) return;
      final firstStudentId = students.isNotEmpty
          ? (students.first['id'] as num?)?.toInt()
          : null;
      setState(() {
        _students = students;
        _selectedLeaderId ??= firstStudentId;
        _selectedMemberId ??= firstStudentId;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Khong tai duoc sinh vien trong lop: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _addMember() {
    if (_selectedMemberId == null) return;
    if (_selectedStudentIds.contains(_selectedMemberId)) return;
    setState(() {
      _selectedStudentIds.add(_selectedMemberId!);
    });
  }

  void _removeMember(int studentId) {
    setState(() {
      _selectedStudentIds.remove(studentId);
      if (_selectedLeaderId == studentId) {
        _selectedLeaderId =
            _selectedStudentIds.isNotEmpty ? _selectedStudentIds.first : null;
      }
    });
  }

  String _studentNameById(int studentId) {
    final match = _students.cast<Map<String, dynamic>?>().firstWhere(
      (student) => (student?['id'] as num?)?.toInt() == studentId,
      orElse: () => null,
    );
    return match?['fullName'] ?? match?['userName'] ?? 'Sinh vien';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final groupId = (widget.project['id'] as num?)?.toInt();
    if (groupId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await ProjectService().updateProjectGroup(groupId, {
        'groupName': _groupNameController.text.trim(),
        'projectName': _projectNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'leaderId': _selectedLeaderId,
        'studentIds': _selectedStudentIds,
      });

      if (!mounted) return;
      Navigator.of(context).pop(response);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cap nhat du an that bai: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
          'Chinh sua du an',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7EC07E)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.classLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _projectNameController,
                      decoration: const InputDecoration(labelText: 'Ten du an'),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Vui long nhap ten du an'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _groupNameController,
                      decoration: const InputDecoration(labelText: 'Ten nhom'),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Vui long nhap ten nhom'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Mo ta'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedLeaderId,
                      items: _students.map((student) {
                        return DropdownMenuItem<int>(
                          value: (student['id'] as num?)?.toInt(),
                          child: Text(student['fullName'] ?? student['userName'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedLeaderId = value),
                      decoration: const InputDecoration(labelText: 'Nhom truong'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedMemberId,
                            items: _students.map((student) {
                              return DropdownMenuItem<int>(
                                value: (student['id'] as num?)?.toInt(),
                                child: Text(student['fullName'] ?? student['userName'] ?? ''),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedMemberId = value),
                            decoration: const InputDecoration(labelText: 'Them thanh vien'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _addMember,
                          child: const Text('Them'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._selectedStudentIds.map((studentId) {
                      return ListTile(
                        title: Text(_studentNameById(studentId)),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _removeMember(studentId),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        child: Text(_isSubmitting ? 'Dang luu...' : 'Luu'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
