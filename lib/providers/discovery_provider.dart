import 'package:flutter/material.dart';
import 'package:crush/core/constants/app_constants.dart';
import 'package:crush/core/services/mock_data_service.dart';
import 'package:crush/core/services/supabase_service.dart';
import 'package:crush/models/profile_model.dart';

enum SwipeDirection { left, right, up }

class DiscoveryProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<ProfileModel> _profiles = [];
  final List<ProfileModel> _swipedHistory = [];
  bool _isLoading = false;
  ProfileModel? _lastMatchedProfile;

  // Filters
  double _maxDistanceKm = AppConstants.defaultMaxDistanceKm;
  RangeValues _ageRange = const RangeValues(20, 32);
  String _genderPreference = 'everyone';

  List<ProfileModel> get profiles => _profiles;
  bool get isLoading => _isLoading;
  bool get canRewind => _swipedHistory.isNotEmpty;
  ProfileModel? get currentProfile => _profiles.isNotEmpty ? _profiles.first : null;
  ProfileModel? get lastMatchedProfile => _lastMatchedProfile;

  double get maxDistanceKm => _maxDistanceKm;
  RangeValues get ageRange => _ageRange;
  String get genderPreference => _genderPreference;

  DiscoveryProvider() {
    loadDiscoveryProfiles();
  }

  Future<void> loadDiscoveryProfiles() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetched = await _supabaseService.fetchDiscoveryProfiles(
        currentUserId: MockDataService.currentUser.id,
        minAge: _ageRange.start.round(),
        maxAge: _ageRange.end.round(),
        maxDistanceKm: _maxDistanceKm,
      );

      _profiles = fetched;
    } catch (e) {
      debugPrint('[DiscoveryProvider] Error loading profiles: $e');
      _profiles = List.from(MockDataService.discoveryProfiles);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> swipeRight({required String currentUserId}) async {
    return _handleSwipe(currentUserId: currentUserId, action: 'like');
  }

  Future<bool> swipeLeft({required String currentUserId}) async {
    return _handleSwipe(currentUserId: currentUserId, action: 'pass');
  }

  Future<bool> swipeUp({required String currentUserId}) async {
    return _handleSwipe(currentUserId: currentUserId, action: 'superlike');
  }

  Future<bool> _handleSwipe({
    required String currentUserId,
    required String action,
  }) async {
    if (_profiles.isEmpty) return false;

    final targetProfile = _profiles.removeAt(0);
    _swipedHistory.add(targetProfile);
    notifyListeners();

    final isMatch = await _supabaseService.recordSwipe(
      swiperId: currentUserId,
      swipedId: targetProfile.id,
      action: action,
    );

    if (isMatch) {
      _lastMatchedProfile = targetProfile;
      notifyListeners();
    }

    return isMatch;
  }

  void rewind() {
    if (_swipedHistory.isNotEmpty) {
      final lastSwiped = _swipedHistory.removeLast();
      _profiles.insert(0, lastSwiped);
      notifyListeners();
    }
  }

  void clearMatchCelebration() {
    _lastMatchedProfile = null;
    notifyListeners();
  }

  void updateFilters({
    double? maxDistance,
    RangeValues? ageRange,
    String? genderPreference,
  }) {
    if (maxDistance != null) _maxDistanceKm = maxDistance;
    if (ageRange != null) _ageRange = ageRange;
    if (genderPreference != null) _genderPreference = genderPreference;
    notifyListeners();
    loadDiscoveryProfiles();
  }
}
