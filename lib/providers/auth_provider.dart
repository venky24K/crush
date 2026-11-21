import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crush/core/constants/app_constants.dart';
import 'package:crush/core/services/mock_data_service.dart';
import 'package:crush/core/services/supabase_service.dart';
import 'package:crush/models/profile_model.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  ProfileModel? _currentProfile;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _isDemoMode = true;

  ProfileModel? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isDemoMode => _isDemoMode;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final hasRealKeys = !AppConstants.defaultSupabaseUrl.contains('your-project');
    _isDemoMode = prefs.getBool(AppConstants.prefsDemoModeKey) ?? !hasRealKeys;
    _supabaseService.enableMockMode(_isDemoMode);

    _currentProfile = await _supabaseService.getCurrentUserProfile();
    _isAuthenticated = _currentProfile != null;

    _isLoading = false;
    notifyListeners();
  }

  void toggleDemoMode(bool enable) async {
    _isDemoMode = enable;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefsDemoModeKey, enable);
    _supabaseService.enableMockMode(enable);

    _currentProfile = await _supabaseService.getCurrentUserProfile();
    _isAuthenticated = _currentProfile != null;
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_isDemoMode) {
        await Future.delayed(const Duration(milliseconds: 600));
        _currentProfile = MockDataService.currentUser;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final client = _supabaseService.client;
      if (client == null) throw Exception('Supabase not configured');

      final authResponse = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        _currentProfile = await _supabaseService.getCurrentUserProfile();
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[AuthProvider] Sign In error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required DateTime birthDate,
    required String gender,
    required List<String> photos,
    required List<String> interests,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_isDemoMode) {
        await Future.delayed(const Duration(milliseconds: 700));
        _currentProfile = ProfileModel(
          id: 'user_new_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          fullName: fullName,
          birthDate: birthDate,
          gender: gender,
          photos: photos.isNotEmpty
              ? photos
              : [
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80'
                ],
          interests: interests,
          city: 'San Francisco, CA',
        );
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final client = _supabaseService.client;
      if (client == null) throw Exception('Supabase not configured');

      final authResponse = await client.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user != null) {
        final newProfile = ProfileModel(
          id: user.id,
          email: email,
          fullName: fullName,
          birthDate: birthDate,
          gender: gender,
          photos: photos,
          interests: interests,
        );

        await _supabaseService.updateProfile(newProfile);
        _currentProfile = newProfile;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[AuthProvider] Sign Up error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> updateProfile(ProfileModel updatedProfile) async {
    _currentProfile = updatedProfile;
    notifyListeners();
    await _supabaseService.updateProfile(updatedProfile);
  }

  Future<String?> uploadPhoto(File file) async {
    if (_currentProfile == null) return null;
    return await _supabaseService.uploadProfilePhoto(_currentProfile!.id, file);
  }

  Future<void> signOut() async {
    if (!_isDemoMode && _supabaseService.client != null) {
      await _supabaseService.client!.auth.signOut();
    }
    _currentProfile = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
