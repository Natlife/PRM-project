import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBackButton;

  const ProfileScreen({super.key, this.showBackButton = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _primaryColor = Color(0xFF22A06B);
  static const Color _primaryDarkColor = Color(0xFF167A52);
  static const Color _backgroundColor = Color(0xFFF5F7F6);
  static const Color _surfaceColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF17211B);
  static const Color _textSecondaryColor = Color(0xFF66736B);
  static const Color _borderColor = Color(0xFFE2E8E4);
  static const Color _errorColor = Color(0xFFDC3D43);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  late final String _roleText;
  late final String _idText;

  bool _isSaving = false;
  bool _isLoggingOut = false;

  String get _displayName {
    final String name = _nameController.text.trim();
    return name.isEmpty ? 'Người dùng' : name;
  }

  String get _initials {
    final String name = _nameController.text.trim();

    if (name.isEmpty) {
      return 'U';
    }

    final List<String> nameParts = name
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();

    if (nameParts.isEmpty) {
      return 'U';
    }

    if (nameParts.length == 1) {
      return nameParts.first.substring(0, 1).toUpperCase();
    }

    final String firstInitial = nameParts.first.substring(0, 1).toUpperCase();
    final String lastInitial = nameParts.last.substring(0, 1).toUpperCase();

    return '$firstInitial$lastInitial';
  }

  @override
  void initState() {
    super.initState();

    final user = AuthService().currentUser;

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

  void _showSnackBar({required String message, required bool isSuccess}) {
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isSuccess ? _primaryDarkColor : _errorColor,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSuccess
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _saveProfile() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await AuthService().updateProfile(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        message: 'Đã cập nhật thông tin cá nhân thành công.',
        isSuccess: true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(
        message: 'Không thể cập nhật hồ sơ: $error',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: _surfaceColor,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              icon: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEE),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: _errorColor,
                  size: 27,
                ),
              ),
              title: const Text(
                'Đăng xuất?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textPrimaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: const Text(
                'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textSecondaryColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: _borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Đăng xuất',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await AuthService().logout();

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(message: 'Không thể đăng xuất: $error', isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _simulateAvatarChange() {
    FocusManager.instance.primaryFocus?.unfocus();

    _showSnackBar(
      message:
          'Tính năng cập nhật avatar sẽ được kết nối backend ở bước tiếp theo.',
      isSuccess: true,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: _borderColor,
      centerTitle: false,
      automaticallyImplyLeading: false,
      leading: widget.showBackButton
          ? IconButton(
              tooltip: 'Quay lại',
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: _textPrimaryColor,
              ),
            )
          : null,
      title: const Text(
        'Trang cá nhân',
        style: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(_errorColor),
                    ),
                  )
                : const Icon(Icons.logout_rounded, color: _errorColor),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _textPrimaryColor.withOpacity(0.045),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _simulateAvatarChange,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 35,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: _borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: _textPrimaryColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: _primaryDarkColor,
                      size: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textPrimaryColor,
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: _primaryDarkColor,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  _roleText,
                  style: const TextStyle(
                    color: _primaryDarkColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin cá nhân',
          style: TextStyle(
            color: _textPrimaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Quản lý và cập nhật thông tin tài khoản của bạn.',
          style: TextStyle(
            color: _textSecondaryColor,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildReadOnlyField(
              label: 'Mã số định danh',
              value: _idText,
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: 'Họ và tên',
              hintText: 'Nhập họ và tên',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Họ tên không được để trống';
                }

                return null;
              },
              onChanged: (_) {
                setState(() {});
              },
            ),
            const SizedBox(height: 18),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              hintText: 'Nhập địa chỉ email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                final String email = value?.trim() ?? '';

                if (email.isEmpty) {
                  return 'Email không được để trống';
                }

                final RegExp emailPattern = RegExp(
                  r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
                );

                if (!emailPattern.hasMatch(email)) {
                  return 'Email không đúng định dạng';
                }

                return null;
              },
            ),
            const SizedBox(height: 18),
            _buildTextField(
              controller: _phoneController,
              label: 'Số điện thoại',
              hintText: 'Nhập số điện thoại',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Số điện thoại không được để trống';
                }

                return null;
              },
              onFieldSubmitted: (_) {
                if (!_isSaving) {
                  _saveProfile();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F5),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF8B9690), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: _textSecondaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFFA0AAA4),
                size: 17,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          enabled: !_isSaving,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(
            color: _textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF9AA49E),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, color: _textSecondaryColor, size: 20),
            filled: true,
            fillColor: const Color(0xFFF9FBFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: _borderColor),
            ),
            errorStyle: const TextStyle(
              color: _errorColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: FilledButton.styleFrom(
          backgroundColor: _primaryColor,
          disabledBackgroundColor: _primaryColor.withOpacity(0.6),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isSaving
              ? const SizedBox(
                  key: ValueKey<String>('saving'),
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Row(
                  key: ValueKey<String>('save'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, size: 21),
                    SizedBox(width: 9),
                    Text(
                      'Lưu thay đổi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 30),
                  _buildSectionHeader(),
                  const SizedBox(height: 16),
                  _buildProfileForm(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
