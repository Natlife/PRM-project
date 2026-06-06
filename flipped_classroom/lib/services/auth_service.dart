import 'package:flutter/material.dart';

enum UserRole { teacher, student }

class UserModel {
  String username;
  String fullName;
  String email;
  String phone;
  UserRole role;
  String avatarUrl;
  String id; // Student ID or Teacher ID

  UserModel({
    required this.username,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl = '',
    required this.id,
  });
}

class AuthService extends ChangeNotifier {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  bool _rememberMe = false;

  UserModel? get currentUser => _currentUser;
  bool get rememberMe => _rememberMe;
  bool get isLoggedIn => _currentUser != null;

  // Mock accounts database
  final Map<String, UserModel> _mockUsers = {
    'teacher': UserModel(
      username: 'teacher',
      fullName: 'GV. Nguyễn Văn A',
      email: 'anv@flippedclassroom.edu.vn',
      phone: '0912345678',
      role: UserRole.teacher,
      id: 'GV001',
    ),
    'student': UserModel(
      username: 'student',
      fullName: 'SV. Trần Thị B',
      email: 'btt@flippedclassroom.edu.vn',
      phone: '0987654321',
      role: UserRole.student,
      id: 'HE160123',
    ),
  };

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 800));

    final normalizedUser = username.trim().toLowerCase();
    
    // Simple validation rule: if it matches mock database
    if (_mockUsers.containsKey(normalizedUser) && password == '${normalizedUser}123') {
      _currentUser = _mockUsers[normalizedUser];
      notifyListeners();
      return true;
    }
    
    // Dynamic generation if username contains teacher or student for testing flexibility
    if (normalizedUser.contains('teacher') && password.isNotEmpty) {
      _currentUser = UserModel(
        username: normalizedUser,
        fullName: 'GV. Nguyễn Văn Test',
        email: '$normalizedUser@flippedclassroom.edu.vn',
        phone: '0900000001',
        role: UserRole.teacher,
        id: 'GV999',
      );
      notifyListeners();
      return true;
    } else if (normalizedUser.contains('student') && password.isNotEmpty) {
      _currentUser = UserModel(
        username: normalizedUser,
        fullName: 'SV. Nguyễn Văn Học Sinh',
        email: '$normalizedUser@flippedclassroom.edu.vn',
        phone: '0900000002',
        role: UserRole.student,
        id: 'HE999999',
      );
      notifyListeners();
      return true;
    }

    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void updateProfile({required String fullName, required String email, required String phone, String? avatarUrl}) {
    if (_currentUser != null) {
      _currentUser!.fullName = fullName;
      _currentUser!.email = email;
      _currentUser!.phone = phone;
      if (avatarUrl != null) {
        _currentUser!.avatarUrl = avatarUrl;
      }
      notifyListeners();
    }
  }
}
