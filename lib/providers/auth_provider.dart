import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crush/core/constants/app_constants.dart';
import 'package:crush/core/services/supabase_service.dart';
import 'package:crush/models/profile_model.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  ProfileModel? _currentProfile;
  bool _isLoading = false;

  ProfileModel? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;

  /// True if the user has an active Supabase auth session
  bool get hasSession => _supabaseService.client?.auth.currentUser != null;

  /// True if the user has a completed profile in public.profiles
  bool get hasProfile => _currentProfile != null;

  /// Fully authenticated (signed in AND profile exists in database)
  bool get isAuthenticated => hasSession && hasProfile;

  /// Authenticated in Supabase Auth (e.g. via Google/Apple) but needs to complete onboarding
  bool get needsOnboarding => hasSession && !hasProfile;

  User? get currentUser => _supabaseService.client?.auth.currentUser;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabaseService.client?.auth.currentUser;
      if (user != null) {
        _currentProfile = await _supabaseService.getCurrentUserProfile();
      } else {
        _currentProfile = null;
      }
    } catch (e) {
      debugPrint('[AuthProvider] _init error: $e');
    }

    _isLoading = false;
    notifyListeners();

    // Listen to real-time Supabase auth state changes (OAuth redirects, token refresh, sign out)
    _supabaseService.client?.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      debugPrint('[AuthProvider] onAuthStateChange event: $event');

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.userUpdated ||
          event == AuthChangeEvent.tokenRefreshed) {
        _isLoading = true;
        notifyListeners();

        _currentProfile = await _supabaseService.getCurrentUserProfile();
        _isLoading = false;
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _currentProfile = null;
        _isLoading = false;
        notifyListeners();
      }
    });
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

    // 1. Try Native Google Sign-In SDK (smooth native 1-tap sheet, no Safari app jump)
    try {
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? AppConstants.googleIosClientId : null,
        serverClientId: AppConstants.googleWebClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = googleAuth.accessToken;

        if (idToken != null) {
          final res = await _supabaseService.client?.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );
          if (res?.user != null) {
            _currentProfile = await _supabaseService.getCurrentUserProfile();
            _isLoading = false;
            notifyListeners();
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint(
          '[AuthProvider] Native Google Sign-In notice: $e. Using in-app browser OAuth fallback...');
    }

    // 2. Fallback to Supabase OAuth with inAppBrowserView (clean modal sheet)
    try {
      final success =
          await _supabaseService.signInWithOAuth(OAuthProvider.google);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('[AuthProvider] Google Sign-In OAuth error: $e');
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

      // Upload any local photos to Supabase Storage if possible
      final List<String> finalPhotos = [];
      for (final p in photos) {
        if (p.startsWith('http://') || p.startsWith('https://')) {
          finalPhotos.add(p);
        } else {
          try {
            final cleanPath = p.replaceFirst('file://', '');
            final file = File(cleanPath);
            if (await file.exists()) {
              final uploadedUrl =
                  await _supabaseService.uploadProfilePhoto(userId, file);
              if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
                finalPhotos.add(uploadedUrl);
              } else {
                finalPhotos.add(p);
              }
            } else {
              finalPhotos.add(p);
            }
          } catch (e) {
            debugPrint('[AuthProvider] Photo upload error: $e');
            finalPhotos.add(p);
          }
        }
      }

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
        photos: finalPhotos.isNotEmpty ? finalPhotos : photos,
        interests: interests,
      );

      if (_supabaseService.client != null) {
        await _supabaseService.updateProfile(profile);
      }

      _currentProfile = profile;
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
    _isLoading = true;
    notifyListeners();

    try {
      final userId = updatedProfile.id;
      final List<String> finalPhotos = [];
      for (final p in updatedProfile.photos) {
        if (p.startsWith('http://') || p.startsWith('https://')) {
          finalPhotos.add(p);
        } else {
          try {
            final cleanPath = p.replaceFirst('file://', '');
            final file = File(cleanPath);
            if (await file.exists()) {
              final uploadedUrl =
                  await _supabaseService.uploadProfilePhoto(userId, file);
              if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
                finalPhotos.add(uploadedUrl);
              } else {
                finalPhotos.add(p);
              }
            } else {
              finalPhotos.add(p);
            }
          } catch (e) {
            debugPrint('[AuthProvider] Update photo upload error: $e');
            finalPhotos.add(p);
          }
        }
      }

      final profileToSave = updatedProfile.copyWith(photos: finalPhotos);
      _currentProfile = profileToSave;
      if (_supabaseService.client != null) {
        await _supabaseService.updateProfile(profileToSave);
      }
    } catch (e) {
      debugPrint('[AuthProvider] updateProfile error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> uploadPhoto(File file) async {
    if (_currentProfile == null) return null;
    return await _supabaseService.uploadProfilePhoto(_currentProfile!.id, file);
  }

  Future<void> signOut() async {
    try {
      if (_supabaseService.client != null) {
        await _supabaseService.client!.auth.signOut();
      }
      try {
        final googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      } catch (_) {}
    } catch (e) {
      debugPrint('[AuthProvider] Sign out error: $e');
    }
    _currentProfile = null;
    _isLoading = false;
    notifyListeners();
  }
}
