import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

    // 1. Native Google Sign-In SDK (smooth 1-tap sheet, no Safari jump)
    try {
      // Always create a fresh GoogleSignIn instance and sign out any stale state
      // to avoid "PlatformException: sign_in_failed / network_error" on retries
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? AppConstants.googleIosClientId : null,
        serverClientId: AppConstants.googleWebClientId,
        scopes: ['email', 'profile'],
      );

      // Silently disconnect any stale cached account so the chooser always shows
      await googleSignIn.signOut().catchError((_) => null);

      final googleUser = await googleSignIn.signIn();

      // User dismissed the picker
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        debugPrint('[AuthProvider] Google idToken is null — falling back to OAuth');
        throw Exception('No idToken');
      }

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

      throw Exception('Supabase signInWithIdToken returned no user');
    } catch (e) {
      debugPrint('[AuthProvider] Native Google sign-in notice: $e');

      // If user explicitly cancelled, don't fall back to browser OAuth
      if (e.toString().contains('sign_in_canceled') ||
          e.toString().contains('canceled')) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }

    // 2. Fallback: Supabase OAuth web flow (in-app browser view)
    try {
      final success =
          await _supabaseService.signInWithOAuth(OAuthProvider.google);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('[AuthProvider] Google OAuth browser fallback error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _generateRawNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256Nonce(String rawNonce) {
    final bytes = utf8.encode(rawNonce);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> signInWithApple() async {
    _isLoading = true;
    notifyListeners();

    // 1. Try Native Apple Sign-In SDK (iOS modal bottom sheet with Face ID / Touch ID)
    if (Platform.isIOS || Platform.isMacOS) {
      try {
        final rawNonce = _generateRawNonce();
        final hashedNonce = _sha256Nonce(rawNonce);

        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
        );

        final idToken = credential.identityToken;
        if (idToken != null) {
          final res = await _supabaseService.client?.auth.signInWithIdToken(
            provider: OAuthProvider.apple,
            idToken: idToken,
            nonce: rawNonce,
          );

          if (res?.user != null) {
            // Apple only returns givenName/familyName on first authorization
            final givenName = credential.givenName;
            final familyName = credential.familyName;
            if (givenName != null || familyName != null) {
              final fullName = [givenName, familyName]
                  .where((s) => s != null && s.isNotEmpty)
                  .join(' ');
              if (fullName.isNotEmpty) {
                try {
                  await _supabaseService.client?.auth.updateUser(
                    UserAttributes(data: {'full_name': fullName}),
                  );
                } catch (_) {}
              }
            }

            _currentProfile = await _supabaseService.getCurrentUserProfile();
            _isLoading = false;
            notifyListeners();
            return true;
          }
        }
      } catch (e) {
        debugPrint('[AuthProvider] Native Apple Sign-In notice: $e');
        if (e is SignInWithAppleAuthorizationException &&
            e.code == AuthorizationErrorCode.canceled) {
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
    }

    // 2. Fallback to Supabase OAuth with inAppBrowserView (e.g. for non-iOS or browser)
    try {
      final success =
          await _supabaseService.signInWithOAuth(OAuthProvider.apple);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('[AuthProvider] Apple Sign-In OAuth error: $e');
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
              : (user?.email ?? ''));

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

  Future<bool> deleteAccount() async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _supabaseService.deleteCurrentUserAccount();
      try {
        final googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      } catch (_) {}

      _currentProfile = null;
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('[AuthProvider] deleteAccount error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
