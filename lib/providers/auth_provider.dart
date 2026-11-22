import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crush/core/services/supabase_service.dart';
import 'package:crush/models/profile_model.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  ProfileModel? _currentProfile;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  ProfileModel? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    _currentProfile = await _supabaseService.getCurrentUserProfile();
    _isAuthenticated = _currentProfile != null;

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = _supabaseService.client;
      if (client == null) throw Exception('Supabase not configured');

      final authResponse = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        _currentProfile = await _supabaseService.getCurrentUserProfile();
        _isAuthenticated = _currentProfile != null;
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

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final success =
          await _supabaseService.signInWithOAuth(OAuthProvider.google);
      _currentProfile = await _supabaseService.getCurrentUserProfile();
      _isAuthenticated = _currentProfile != null;
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('[AuthProvider] Google Sign-In error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    _isLoading = true;
    notifyListeners();

    try {
      final success =
          await _supabaseService.signInWithOAuth(OAuthProvider.apple);
      _currentProfile = await _supabaseService.getCurrentUserProfile();
      _isAuthenticated = _currentProfile != null;
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('[AuthProvider] Apple Sign-In error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeOnboarding({
    required String fullName,
    required DateTime birthDate,
    required String gender,
    required List<String> lookingFor,
    required List<String> photos,
    required List<String> interests,
    String bio = '',
    String occupation = '',
    String city = 'San Francisco, CA',
    String? email,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabaseService.client?.auth.currentUser;
      final userId = user?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

      final userEmail = email ??
          (_currentProfile?.email.isNotEmpty == true
              ? _currentProfile!.email
              : (user?.email ?? 'user@crush.app'));

      final profile = ProfileModel(
        id: userId,
        email: userEmail,
        fullName: fullName,
        birthDate: birthDate,
        gender: gender,
        lookingFor: lookingFor,
        bio: bio,
        occupation: occupation,
        city: city,
        photos: photos,
        interests: interests,
      );

      if (_supabaseService.client != null) {
        await _supabaseService.updateProfile(profile);
      }

      _currentProfile = profile;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AuthProvider] completeOnboarding error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
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
    if (_supabaseService.client != null) {
      await _supabaseService.client!.auth.signOut();
    }
    _currentProfile = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
