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
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _inputBackgroundColor = Color(0xFFF9FBFA);
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
    final List<dynamic>? membersData =
        widget.project['membersData'] as List<dynamic>?;

    if (membersData != null && membersData.isNotEmpty) {
      _selectedStudentIds = membersData
          .map((dynamic member) => (member['id'] as num?)?.toInt())
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
      final List<Map<String, dynamic>> students = await ClassroomService()
          .getTeacherClassroomStudents(widget.classroomId);

      if (!mounted) {
        return;
      }

      final int? firstStudentId = students.isNotEmpty
          ? (students.first['id'] as num?)?.toInt()
          : null;

      setState(() {
        _students = students;
        _selectedLeaderId ??= firstStudentId;
        _selectedMemberId ??= firstStudentId;
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
          content: Text('Không tải được sinh viên trong lớp: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  void _addMember() {
    if (_selectedMemberId == null) {
      return;
    }

    if (_selectedStudentIds.contains(_selectedMemberId)) {
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
        _selectedLeaderId = _selectedStudentIds.isNotEmpty
            ? _selectedStudentIds.first
            : null;
      }
    });
  }

  String _studentNameById(int studentId) {
    final Map<String, dynamic>? match = _students
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (Map<String, dynamic>? student) =>
              (student?['id'] as num?)?.toInt() == studentId,
          orElse: () => null,
        );

    return match?['fullName'] ?? match?['userName'] ?? 'Sinh viên';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final int? groupId = (widget.project['id'] as num?)?.toInt();

    if (groupId == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Map<String, dynamic> response = await ProjectService()
          .updateProjectGroup(groupId, {
            'groupName': _groupNameController.text.trim(),
            'projectName': _projectNameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'leaderId': _selectedLeaderId,
            'studentIds': _selectedStudentIds,
          });

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(response);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật dự án thất bại: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: _borderColor,
      automaticallyImplyLeading: false,
      leading: IconButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.arrow_back_rounded, color: _textPrimaryColor),
      ),
      titleSpacing: 0,
      title: const Text(
        'Chỉnh sửa dự án',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          color: _primaryColor,
          strokeWidth: 2.8,
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: _primaryDarkColor,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin dự án',
                  style: TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Cập nhật thông tin dự án và danh sách '
                  'thành viên của nhóm.',
                  style: TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title: title, icon: icon),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F0),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _primaryDarkColor, size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: _errorColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9AA49E),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: _textSecondaryColor, size: 20),
      filled: true,
      fillColor: _inputBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _errorColor, width: 1.5),
      ),
    );
  }

  Widget _buildClassroomCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _inputBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: _primaryDarkColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lớp học',
                  style: TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.classLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Tên dự án', required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _projectNameController,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: _buildInputDecoration(
            hintText: 'Nhập tên dự án',
            prefixIcon: Icons.work_outline_rounded,
          ),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập tên dự án';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildGroupNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Tên nhóm', required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _groupNameController,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: _buildInputDecoration(
            hintText: 'Nhập tên nhóm',
            prefixIcon: Icons.groups_outlined,
          ),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập tên nhóm';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Mô tả'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          minLines: 3,
          maxLines: 3,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 13.5,
            height: 1.5,
          ),
          decoration: _buildInputDecoration(hintText: 'Nhập mô tả dự án'),
        ),
      ],
    );
  }

  Widget _buildLeaderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Nhóm trưởng'),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _selectedLeaderId,
          isExpanded: true,
          dropdownColor: _surfaceColor,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _textSecondaryColor,
          ),
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: _buildInputDecoration(
            hintText: 'Chọn nhóm trưởng',
            prefixIcon: Icons.workspace_premium_outlined,
          ),
          items: _students.map((Map<String, dynamic> student) {
            return DropdownMenuItem<int>(
              value: (student['id'] as num?)?.toInt(),
              child: Text(
                student['fullName'] ?? student['userName'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (int? value) {
            setState(() {
              _selectedLeaderId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMemberSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Thêm thành viên'),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _selectedMemberId,
          isExpanded: true,
          dropdownColor: _surfaceColor,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _textSecondaryColor,
          ),
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: _buildInputDecoration(
            hintText: 'Chọn thành viên',
            prefixIcon: Icons.person_add_alt_outlined,
          ),
          items: _students.map((Map<String, dynamic> student) {
            return DropdownMenuItem<int>(
              value: (student['id'] as num?)?.toInt(),
              child: Text(
                student['fullName'] ?? student['userName'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (int? value) {
            setState(() {
              _selectedMemberId = value;
            });
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addMember,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryDarkColor,
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: _primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text(
              'Thêm thành viên',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedMembers() {
    if (_selectedStudentIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Divider(height: 1, color: _borderColor),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Thành viên hiện tại',
                style: TextStyle(
                  color: _textPrimaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F0),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${_selectedStudentIds.length} thành viên',
                style: const TextStyle(
                  color: _primaryDarkColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        ..._selectedStudentIds.map((int studentId) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.fromLTRB(13, 10, 5, 10),
            decoration: BoxDecoration(
              color: _inputBackgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F0),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: _primaryDarkColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    _studentNameById(studentId),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textPrimaryColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _removeMember(studentId);
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _errorColor,
                    size: 19,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primaryColor.withOpacity(0.65),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : const Text(
                'Lưu thay đổi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 14),
                _buildFormSection(
                  title: 'Thông tin cơ bản',
                  icon: Icons.info_outline_rounded,
                  children: [
                    _buildClassroomCard(),
                    const SizedBox(height: 18),
                    _buildProjectNameField(),
                    const SizedBox(height: 18),
                    _buildGroupNameField(),
                    const SizedBox(height: 18),
                    _buildDescriptionField(),
                  ],
                ),
                const SizedBox(height: 14),
                _buildFormSection(
                  title: 'Phân công thành viên',
                  icon: Icons.groups_outlined,
                  children: [
                    _buildLeaderField(),
                    const SizedBox(height: 18),
                    _buildMemberSelector(),
                    _buildSelectedMembers(),
                  ],
                ),
                const SizedBox(height: 22),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: _isLoading ? _buildLoadingState() : _buildContent(),
      ),
    );
  }
}
