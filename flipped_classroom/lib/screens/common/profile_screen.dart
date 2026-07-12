import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBackButton;

  const ProfileScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _dangerColor = Color(0xFFEF4444);

  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  late final String _roleText;
  late final String _idText;

  @override
  void initState() {
    super.initState();

    final user = _authService.currentUser;

    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');

    _idText = user?.id ?? 'N/A';
    _roleText = user?.role == UserRole.teacher ? 'Giảng viên' : 'Sinh viên';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String get _displayName {
    final name = _nameController.text.trim();
    return name.isEmpty ? 'Người dùng' : name;
  }

  String get _initials {
    final parts = _displayName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';

    final first = parts.first.characters.first.toUpperCase();
    final last = parts.length > 1 ? parts.last.characters.first.toUpperCase() : '';

    return '$first$last';
  }

  void _saveProfile() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    _authService.updateProfile(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    _showSnackBar(
      message: 'Đã cập nhật thông tin cá nhân thành công.',
      icon: Icons.check_circle_rounded,
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => const _LogoutConfirmDialog(),
    );

    if (shouldLogout != true) return;

    _authService.logout();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (_) => false,
    );
  }

  void _simulateAvatarChange() {
    _showSnackBar(
      message: 'Tính năng cập nhật avatar đang được giả lập.',
      icon: Icons.info_rounded,
    );
  }

  void _showSnackBar({
    required String message,
    required IconData icon,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? _dangerColor : _textColor,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildInfoForm(),
              const SizedBox(height: 20),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: widget.showBackButton,
      leading: widget.showBackButton
          ? IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _textColor,
                size: 20,
              ),
            )
          : null,
      title: const Text(
        'Trang cá nhân',
        style: TextStyle(
          color: _textColor,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton.filledTonal(
            onPressed: _logout,
            style: IconButton.styleFrom(
              backgroundColor: _dangerColor.withOpacity(0.1),
              foregroundColor: _dangerColor,
            ),
            icon: const Icon(Icons.logout_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _borderColor.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: _textColor.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _simulateAvatarChange,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _primaryColor,
                        _primaryColor.withOpacity(0.72),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _textColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _surfaceColor,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _primaryColor.withOpacity(0.24),
              ),
            ),
            child: Text(
              _roleText.toUpperCase(),
              style: const TextStyle(
                color: _primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoForm() {
    return Form(
      key: _formKey,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _borderColor.withOpacity(0.8)),
          boxShadow: [
            BoxShadow(
              color: _textColor.withOpacity(0.035),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _ReadOnlyInfoTile(
              label: 'Mã số định danh',
              value: _idText,
              icon: Icons.badge_outlined,
            ),
            const _SectionDivider(),
            _ProfileTextField(
              controller: _nameController,
              label: 'Họ và tên',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Họ tên không được để trống';
                }
                return null;
              },
            ),
            const _SectionDivider(),
            _ProfileTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final email = value?.trim() ?? '';

                if (email.isEmpty) {
                  return 'Email không được để trống';
                }

                final isValidEmail = RegExp(
                  r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$',
                ).hasMatch(email);

                if (!isValidEmail) {
                  return 'Email không đúng định dạng';
                }

                return null;
              },
            ),
            const _SectionDivider(),
            _ProfileTextField(
              controller: _phoneController,
              label: 'Số điện thoại',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Số điện thoại không được để trống';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _saveProfile,
        icon: const Icon(Icons.save_rounded),
        label: const Text('Lưu thay đổi'),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.validator,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _fieldColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(
        color: _textColor,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _mutedTextColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          icon,
          color: _primaryColor,
          size: 22,
        ),
        filled: true,
        fillColor: _fieldColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: _primaryColor,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.4,
          ),
        ),
        errorStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReadOnlyInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyInfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  static const Color _primaryColor = Color(0xFF7EC07E);
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _fieldColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: _fieldColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: _primaryColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _mutedTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 14);
  }
}

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog();

  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _dangerColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: const Text(
        'Đăng xuất',
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
      ),
      content: const Text(
        'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?',
        style: TextStyle(
          color: _mutedTextColor,
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: _mutedTextColor,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
          ),
          child: const Text(
            'Hủy',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _dangerColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
          ),
          child: const Text(
            'Đăng xuất',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}