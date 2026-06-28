import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_service.dart';

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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleName = json['role']?['name'] ?? '';
    final role = roleName == 'ROLE_TEACHER' ? UserRole.teacher : UserRole.student;
    return UserModel(
      username: json['userName'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: role,
      avatarUrl: json['avatarUrl'] ?? '',
      id: json['institutionalId'] ?? (json['id']?.toString() ?? ''),
    );
  }
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

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await ApiService().post(
        '/auth/login',
        body: {
          'username': username.trim(),
          'password': password,
        },
      );

      final responseBody = jsonDecode(response.body);
      final authData = responseBody['data'];
      final token = authData['token'];
      final userData = authData['user'];

      ApiService().setToken(token);
      _currentUser = UserModel.fromJson(userData);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    ApiService().setToken(null);
    notifyListeners();
  }

  void updateProfile({
    required String fullName,
    required String email,
    required String phone,
    String? avatarUrl,
  }) {
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
