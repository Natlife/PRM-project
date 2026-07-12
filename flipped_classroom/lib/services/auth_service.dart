import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

enum UserRole { teacher, student }

class UserModel {
  String username;
  String fullName;
  String email;
  String phone;
  UserRole role;
  String avatarUrl;
  String id;
  int dbId;

  UserModel({
    required this.username,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl = '',
    required this.id,
    required this.dbId,
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
      dbId: (json['id'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': dbId,
      'userName': username,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'institutionalId': id,
      'role': {
        'name': role == UserRole.teacher ? 'ROLE_TEACHER' : 'ROLE_STUDENT',
      },
    };
  }
}

class AuthService extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _rememberMeKey = 'remember_me';

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  bool _rememberMe = false;
  bool _hasRestoredSession = false;

  UserModel? get currentUser => _currentUser;
  bool get rememberMe => _rememberMe;
  bool get isLoggedIn => _currentUser != null;
  bool get hasRestoredSession => _hasRestoredSession;

  Future<void> restoreSession() async {
    if (_hasRestoredSession) return;
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    if (!_rememberMe) {
      _hasRestoredSession = true;
      return;
    }

    final token = prefs.getString(_tokenKey);
    final rawUser = prefs.getString(_userKey);
    if (token != null && token.isNotEmpty && rawUser != null && rawUser.isNotEmpty) {
      try {
        ApiService().setToken(token);
        _currentUser = UserModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(rawUser)),
        );
      } catch (e) {
        debugPrint('Restore session failed: $e');
        await _clearPersistedSession();
      }
    }
    _hasRestoredSession = true;
    notifyListeners();
  }

  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, value);
    if (!value) {
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    }
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
      final token = authData['token']?.toString() ?? '';
      final userData = Map<String, dynamic>.from(authData['user'] ?? const {});

      ApiService().setToken(token);
      _currentUser = UserModel.fromJson(userData);
      await _persistSession(token, _currentUser!);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    ApiService().setToken(null);
    await _clearPersistedSession();
    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) {
      throw Exception('Bạn chưa đăng nhập');
    }

    final response = await ApiService().put(
      '/users/me',
      body: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
    );
    final body = jsonDecode(response.body);
    final updatedUser = UserModel.fromJson(
      Map<String, dynamic>.from(body['data'] ?? const {}),
    );
    _currentUser = updatedUser;

    if (_rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
    }
    notifyListeners();
  }

  Future<void> _persistSession(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, _rememberMe);
    if (_rememberMe) {
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    } else {
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    }
  }

  Future<void> _clearPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_rememberMeKey);
    _rememberMe = false;
  }
}
