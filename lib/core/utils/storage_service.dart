import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
  }
  
  Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConstants.tokenKey);
  }
  
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
  }
  
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _prefs?.setString(AppConstants.userKey, jsonString);
  }
  
  Future<Map<String, dynamic>?> getUserData() async {
    final jsonString = _prefs?.getString(AppConstants.userKey);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }
  
  Future<void> saveActiveRole(String role) async {
    await _prefs?.setString(AppConstants.activeRoleKey, role);
  }
  
  Future<String?> getActiveRole() async {
    return _prefs?.getString(AppConstants.activeRoleKey);
  }
  
  Future<void> setLoggedIn(bool value) async {
    await _prefs?.setBool(AppConstants.isLoggedInKey, value);
  }
  
  Future<bool> isLoggedIn() async {
    return _prefs?.getBool(AppConstants.isLoggedInKey) ?? false;
  }
  
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs?.clear();
  }
  
  Future<void> saveString(String key, String value) async {
    await _prefs?.setString(key, value);
  }
  
  String? getString(String key) {
    return _prefs?.getString(key);
  }
  
  Future<void> saveBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }
  
  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }
  
  Future<void> saveInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }
  
  int? getInt(String key) {
    return _prefs?.getInt(key);
  }
  
  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }
}
