import 'package:flutter/material.dart';
import '../../services/classroom_service.dart';
import '../../services/project_service.dart';

class CreateProjectScreen extends StatefulWidget {
  final int? fixedClassroomId;
  final String? fixedClass;
  final List<Map<String, dynamic>> availableClassrooms;

  const CreateProjectScreen({
    super.key,
    this.fixedClassroomId,
    this.fixedClass,
    this.availableClassrooms = const [],
  });

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _groupNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _selectedClassroomId;
  String? _selectedClassLabel;
  int? _selectedLeaderId;
  int? _selectedMemberId;
  List<Map<String, dynamic>> _students = [];
  List<int> _selectedStudentIds = [];
  bool _isLoadingStudents = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.fixedClassroomId != null) {
      _selectedClassroomId = widget.fixedClassroomId;
      _selectedClassLabel = widget.fixedClass;
      _loadStudents(widget.fixedClassroomId!);
    } else if (widget.availableClassrooms.isNotEmpty) {
      final first = widget.availableClassrooms.first;
      _selectedClassroomId = (first['id'] as num?)?.toInt();
      _selectedClassLabel = first['code'] ?? first['title'] ?? first['className'];
      if (_selectedClassroomId != null) {
        _loadStudents(_selectedClassroomId!);
      }
    }
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _groupNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents(int classroomId) async {
    setState(() {
      _isLoadingStudents = true;
      _students = [];
      _selectedStudentIds = [];
      _selectedLeaderId = null;
      _selectedMemberId = null;
    });

    try {
      final students = await ClassroomService().getTeacherClassroomStudents(
        classroomId,
      );
      if (!mounted) return;

      setState(() {
        _students = students;
        if (students.isNotEmpty) {
          _selectedLeaderId = (students.first['id'] as num?)?.toInt();
          _selectedMemberId = (students.first['id'] as num?)?.toInt();
        }
        _isLoadingStudents = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingStudents = false;
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
    if (_selectedStudentIds.contains(_selectedMemberId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sinh vien nay da co trong danh sach!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
    if (_selectedClassroomId == null) return;

    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui long them it nhat mot thanh vien vao nhom!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedLeaderId == null ||
        !_selectedStudentIds.contains(_selectedLeaderId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhom truong phai nam trong danh sach thanh vien!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await ProjectService().createProjectGroup(
        _selectedClassroomId!,
        {
          'groupName': _groupNameController.text.trim().isEmpty
              ? _projectNameController.text.trim()
              : _groupNameController.text.trim(),
          'projectName': _projectNameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'leaderId': _selectedLeaderId,
          'studentIds': _selectedStudentIds,
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(response);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tao du an that bai: $e'),
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tao du an moi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
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
                'Lop hoc *',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.fixedClassroomId != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                    ),
                  ),
                  child: Text(
                    _selectedClassLabel ?? '',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: _selectedClassroomId,
                  items: widget.availableClassrooms.map((classroom) {
                    return DropdownMenuItem<int>(
                      value: (classroom['id'] as num?)?.toInt(),
                      child: Text(
                        classroom['code'] ??
                            classroom['title'] ??
                            classroom['className'] ??
                            '',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    final match = widget.availableClassrooms.firstWhere(
                      (classroom) => (classroom['id'] as num?)?.toInt() == value,
                    );
                    setState(() {
                      _selectedClassroomId = value;
                      _selectedClassLabel =
                          match['code'] ?? match['title'] ?? match['className'];
                    });
                    if (value != null) {
                      _loadStudents(value);
                    }
                  },
                  decoration: InputDecoration(
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
                'Ten du an *',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _projectNameController,
                decoration: InputDecoration(
                  fillColor: const Color(0xFFFFFFFF),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui long nhap ten du an';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Ten nhom *',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  fillColor: const Color(0xFFFFFFFF),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui long nhap ten nhom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Mo ta',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
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
                'Nhom truong',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_isLoadingStudents)
                const LinearProgressIndicator(color: Color(0xFF7EC07E))
              else
                DropdownButtonFormField<int>(
                  initialValue: _selectedLeaderId,
                  items: _students.map((student) {
                    return DropdownMenuItem<int>(
                      value: (student['id'] as num?)?.toInt(),
                      child: Text(student['fullName'] ?? student['userName'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLeaderId = value;
                    });
                  },
                  decoration: InputDecoration(
                    fillColor: const Color(0xFFFFFFFF),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thanh vien',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoadingStudents ? null : _addMember,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7EC07E),
                    ),
                    icon: const Icon(Icons.add, size: 14, color: Color(0xFF0F172A)),
                    label: const Text(
                      'Them',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedMemberId,
                items: _students.map((student) {
                  return DropdownMenuItem<int>(
                    value: (student['id'] as num?)?.toInt(),
                    child: Text(student['fullName'] ?? student['userName'] ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMemberId = value;
                  });
                },
                decoration: InputDecoration(
                  fillColor: const Color(0xFFFFFFFF),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_selectedStudentIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    ),
                  ),
                  child: Column(
                    children: _selectedStudentIds.map((studentId) {
                      final studentName = _studentNameById(studentId);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              studentName,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Color(0xFFEC4899),
                              size: 20,
                            ),
                            onPressed: () => _removeMember(studentId),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isSubmitting ? 'Dang tao...' : 'Tao moi',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
