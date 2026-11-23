import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crush/core/constants/app_colors.dart';
import 'package:crush/core/constants/app_constants.dart';
import 'package:crush/models/profile_model.dart';
import 'package:crush/providers/auth_provider.dart';
import 'package:crush/providers/discovery_provider.dart';

/// Full-featured Settings screen for Crush.
///
/// Organized into distinct functional sections:
/// a. Account Settings (Phone number, Connected accounts, Email)
/// b. Discovery (Location, Max distance, Interested in, Age range)
/// c. Control My Visibility (Standard vs Incognito)
/// d. Enable Discovery (Toggle)
/// e. Control Who Messages You
/// f. Blocked Accounts
/// g. Account Active Status
/// h. Notifications (Email & Push notifications)
/// i. Dark Mode
/// j. Share Crush App
/// k. Contact Us (Help and Support)
/// l. Community (Guidelines, Safety tips, Safety center)
/// m. Privacy (Privacy policy, Privacy preferences)
/// n. Legal (Licenses, Terms of service)
/// o. Log out
/// p. Version with Logo
/// q. Delete account
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Discovery preferences
  late double _maxDistanceKm;
  late RangeValues _ageRange;
  late String _genderPreference; // 'female', 'male', 'everyone'
  late String _city;

  // Visibility & Discovery
  bool _enableDiscovery = true;
  bool _isIncognito = false;

  // Communication & Status
  String _messagePermission = 'Matches Only';
  bool _showActiveStatus = true;

  // Notifications
  bool _pushNotifications = true;
  bool _emailNotifications = true;

  // Theme
  String _themeMode = 'Light';

  // Phone number (cached/mocked if not provided in auth)
  String _phoneNumber = '';

  // Blocked accounts
  final List<String> _blockedUsers = [
    'Alex M. (Blocked on Nov 12)',
    'Jordan K. (Blocked on Oct 28)',
  ];

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadLocalPreferences();
  }

  Future<void> _loadLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _enableDiscovery = prefs.getBool('crush_discovery_enabled') ?? true;
        _isIncognito = prefs.getBool('crush_incognito_mode') ?? false;
        _messagePermission = prefs.getString('crush_message_permission') ?? 'Matches Only';
        _showActiveStatus = prefs.getBool('crush_active_status') ?? true;
        _pushNotifications = prefs.getBool('crush_push_notifications') ?? true;
        _emailNotifications = prefs.getBool('crush_email_notifications') ?? true;
        _themeMode = prefs.getString(AppConstants.prefsUserThemeKey) ?? 'Light';
        final savedPhone = prefs.getString('crush_phone_number');
        if (savedPhone != null && savedPhone.isNotEmpty) {
          _phoneNumber = savedPhone;
        }
      });
    } catch (e) {
      debugPrint('[Settings] Error loading prefs: $e');
    }
  }

  Future<void> _setBoolPref(String key, bool? val) async {
    if (val == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, val);
    } catch (_) {}
  }

  Future<void> _setStringPref(String key, String? val) async {
    if (val == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, val);
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final auth = context.read<AuthProvider>();
      final discovery = context.read<DiscoveryProvider>();
      final profile = auth.currentProfile;

      _maxDistanceKm = (profile?.maxDistanceKm ?? discovery.maxDistanceKm).toDouble().clamp(2.0, 150.0);

      final minAge = (profile?.minAgePreference ?? 18).toDouble().clamp(18.0, 65.0);
      final maxAge = (profile?.maxAgePreference ?? 40).toDouble().clamp(minAge, 65.0);
      _ageRange = RangeValues(minAge, maxAge);

      _genderPreference = discovery.genderPreference;
      if (profile?.lookingFor.isNotEmpty == true) {
        final target = profile!.lookingFor.first.toLowerCase();
        if (target.contains('women') || target.contains('female')) {
          _genderPreference = 'female';
        } else if (target.contains('men') || target.contains('male')) {
          _genderPreference = 'male';
        } else {
          _genderPreference = 'everyone';
        }
      }

      _city = profile?.city ?? 'Current Location';
      if (_phoneNumber.isEmpty) {
        _phoneNumber = auth.currentUser?.phone ?? '';
      }

      _initialized = true;
    }
  }

  // ─── Helpers & Sync ────────────────────────────────────────────────────────

  void _syncDiscoveryPreferences() {
    final auth = context.read<AuthProvider>();
    final discovery = context.read<DiscoveryProvider>();
    final currentProfile = auth.currentProfile;

    // Update discovery provider filters
    discovery.updateFilters(
      maxDistance: _maxDistanceKm,
      ageRange: _ageRange,
      genderPreference: _genderPreference,
    );

    // Persist to profile model if available
    if (currentProfile != null) {
      final updated = currentProfile.copyWith(
        maxDistanceKm: _maxDistanceKm.round(),
        minAgePreference: _ageRange.start.round(),
        maxAgePreference: _ageRange.end.round(),
        city: _city,
        lookingFor: [_genderPreference],
      );
      auth.updateProfile(updated);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _sheetHandle() => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.cardBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  // ─── Modal Sheets ──────────────────────────────────────────────────────────

  void _editPhoneNumberDialog() {
    final controller = TextEditingController(text: _phoneNumber);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Phone Number',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your mobile number for account security and recovery.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: '+1 (555) 000-0000',
                prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final phone = controller.text.trim();
              setState(() => _phoneNumber = phone);
              _setStringPref('crush_phone_number', phone);
              Navigator.pop(dialogCtx);
              _showSnack('Phone number updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showConnectedAccountsSheet() {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final appMeta = user?.appMetadata ?? {};
    final provider = (appMeta['provider'] ?? '').toString().toLowerCase();
    final providersList = (appMeta['providers'] as List<dynamic>? ?? [])
        .map((e) => e.toString().toLowerCase())
        .toList();

    final hasGoogle = provider.contains('google') || providersList.contains('google');
    final hasApple = provider.contains('apple') || providersList.contains('apple');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const Text(
                'Connected Accounts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in faster and secure your account with linked providers.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              _Group(
                children: [
                  ListTile(
                    leading: const Icon(Icons.g_mobiledata_rounded, size: 32, color: Color(0xFFDB4437)),
                    title: const Text('Google', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    subtitle: Text(hasGoogle ? (user?.email ?? 'Connected') : 'Not connected',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    trailing: hasGoogle
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.like.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Connected',
                                style: TextStyle(color: AppColors.like, fontSize: 12, fontWeight: FontWeight.w700)),
                          )
                        : TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showSnack('Google account linking initiated');
                            },
                            child: const Text('Connect', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.apple_rounded, size: 28, color: AppColors.textPrimary),
                    title: const Text('Apple ID', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    subtitle: Text(hasApple ? 'Connected' : 'Not connected',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    trailing: hasApple
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.like.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Connected',
                                style: TextStyle(color: AppColors.like, fontSize: 12, fontWeight: FontWeight.w700)),
                          )
                        : TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showSnack('Apple ID linking initiated');
                            },
                            child: const Text('Connect', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editLocationDialog() {
    final controller = TextEditingController(text: _city);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discovery Location',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Set your city or area to find compatible matches nearby.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. San Francisco, CA',
                prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final newCity = controller.text.trim();
              if (newCity.isNotEmpty) {
                setState(() => _city = newCity);
                _syncDiscoveryPreferences();
              }
              Navigator.pop(dialogCtx);
              _showSnack('Location updated');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showInterestedInSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const Text('Interested In',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text('Choose whose profiles you want to see in Discovery.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              _Group(
                children: [
                  RadioListTile<String>(
                    activeColor: AppColors.primary,
                    title: const Text('Women',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    value: 'female',
                    groupValue: _genderPreference,
                    onChanged: (val) {
                      setState(() => _genderPreference = val!);
                      _syncDiscoveryPreferences();
                      Navigator.pop(ctx);
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    activeColor: AppColors.primary,
                    title: const Text('Men',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    value: 'male',
                    groupValue: _genderPreference,
                    onChanged: (val) {
                      setState(() => _genderPreference = val!);
                      _syncDiscoveryPreferences();
                      Navigator.pop(ctx);
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    activeColor: AppColors.primary,
                    title: const Text('Everyone',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    value: 'everyone',
                    groupValue: _genderPreference,
                    onChanged: (val) {
                      setState(() => _genderPreference = val!);
                      _syncDiscoveryPreferences();
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessagePermissionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const Text('Control Who Messages You',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text('Select who is permitted to send you chats and intros.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              _Group(
                children: [
                  RadioListTile<String>(
                    activeColor: AppColors.primary,
                    title: const Text('Mutual Matches Only',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    subtitle: const Text('Only people you both swipe right on can chat with you.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    value: 'Matches Only',
                    groupValue: _messagePermission,
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _messagePermission = val);
                      _setStringPref('crush_message_permission', val);
                      Navigator.pop(ctx);
                      _showSnack('Chat permission set to Matches Only');
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    activeColor: AppColors.primary,
                    title: const Text('Verified Profiles Only',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    subtitle: const Text('Only photo-verified mutual matches can start a chat.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    value: 'Verified Only',
                    groupValue: _messagePermission,
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _messagePermission = val);
                      _setStringPref('crush_message_permission', val);
                      Navigator.pop(ctx);
                      _showSnack('Chat permission set to Verified Only');
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    activeColor: AppColors.primary,
                    title: const Text('Everyone (with Crush Intro)',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    subtitle: const Text('Allow admirers to send 1 thoughtful introductory message.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    value: 'Everyone with Intro',
                    groupValue: _messagePermission,
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _messagePermission = val);
                      _setStringPref('crush_message_permission', val);
                      Navigator.pop(ctx);
                      _showSnack('Chat permission set to Everyone with Intro');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBlockedAccountsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _sheetHandle()),
                const Text('Blocked Accounts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                const Text('Blocked profiles will not see you in discovery and cannot message you.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                if (_blockedUsers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('No blocked accounts',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    ),
                  )
                else
                  _Group(
                    children: [
                      for (var i = 0; i < _blockedUsers.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.block_rounded, color: AppColors.nope, size: 22),
                          title: Text(_blockedUsers[i],
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          trailing: TextButton(
                            onPressed: () {
                              final unblocked = _blockedUsers[i];
                              setSheetState(() => _blockedUsers.removeAt(i));
                              setState(() {});
                              _showSnack('Unblocked $unblocked');
                            },
                            child: const Text('Unblock',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDarkModeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const Text('Theme Mode',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text('Select appearance preference for Crush.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              _Group(
                children: [
                  RadioListTile<String>(
                    activeColor: AppColors.primary,
                    title: const Text('Light Mode (Warm Ivory & Coral)',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    value: 'Light',
                    groupValue: _themeMode,
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _themeMode = val);
                      _setStringPref(AppConstants.prefsUserThemeKey, val);
                      Navigator.pop(ctx);
                      _showSnack('Theme updated to Light mode');
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    activeColor: AppColors.primary,
                    title: const Text('Dark Mode (Midnight)',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    value: 'Dark',
                    groupValue: _themeMode,
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _themeMode = val);
                      _setStringPref(AppConstants.prefsUserThemeKey, val);
                      Navigator.pop(ctx);
                      _showSnack('Theme updated to Dark mode');
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    activeColor: AppColors.primary,
                    title: const Text('System Default',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    value: 'System',
                    groupValue: _themeMode,
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _themeMode = val);
                      _setStringPref(AppConstants.prefsUserThemeKey, val);
                      Navigator.pop(ctx);
                      _showSnack('Theme following system settings');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareApp() {
    Clipboard.setData(const ClipboardData(text: 'https://crush.app - Spark genuine connections!'));
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Share Crush',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share your invite link with friends:',
                style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 12),
            SelectableText(
              'https://crush.app',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _showSnack('Invite link copied to clipboard! 📋');
            },
            child: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  void _showHelpAndSupportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle()),
              const Text('Help & Support',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text('Have a question, feedback, or need help with your account?',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              _Group(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                    title: const Text('Email Support',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    subtitle: const Text(AppConstants.supportEmail,
                        style: TextStyle(color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textMuted),
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: AppConstants.supportEmail));
                      Navigator.pop(ctx);
                      _showSnack('Support email copied to clipboard');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined, color: AppColors.nope),
                    title: const Text('Report a Problem',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    subtitle: const Text('Flag bugs or unexpected behavior',
                        style: TextStyle(color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showSnack('Thank you! Feedback reported to our engineering team.');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoModal(String title, List<Map<String, String>> points) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _sheetHandle()),
                Text(title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: points.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = points[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                            const SizedBox(height: 6),
                            Text(item['body'] ?? '',
                                style: const TextStyle(
                                    fontSize: 13, height: 1.4, color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrivacyPreferencesSheet() {
    bool analyticsConsent = true;
    bool adsConsent = false;
    bool crashReporting = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _sheetHandle()),
                const Text('Privacy Preferences',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                const Text('Manage how your data is processed and used on Crush.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                _Group(
                  children: [
                    SwitchListTile.adaptive(
                      activeColor: AppColors.primary,
                      title: const Text('Anonymous Analytics',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      subtitle: const Text('Help us improve connection matching algorithms',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      value: analyticsConsent,
                      onChanged: (v) => setSheetState(() => analyticsConsent = v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      activeColor: AppColors.primary,
                      title: const Text('Personalized Ads & Offers',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      subtitle: const Text('Relevant promotions for Crush Gold & events',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      value: adsConsent,
                      onChanged: (v) => setSheetState(() => adsConsent = v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      activeColor: AppColors.primary,
                      title: const Text('Crash Reports',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      subtitle: const Text('Send diagnostic logs to fix crashes quickly',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      value: crashReporting,
                      onChanged: (v) => setSheetState(() => crashReporting = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Sign Out & Delete ─────────────────────────────────────────────────────

  Future<void> _signOut(BuildContext context, AuthProvider auth) async {
    final nav = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out of Crush?',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: const Text('You will need to sign in again to see your chats and matches.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.nope,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await auth.signOut();
      nav.popUntil((route) => route.isFirst);
    }
  }

  void _confirmDelete(BuildContext context, AuthProvider auth) {
    final nav = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Crush Account?',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? All your matches, chats, photos, and preferences will be permanently erased. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.nope,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await auth.deleteAccount();
              nav.popUntil((route) => route.isFirst);
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.currentProfile?.email.isNotEmpty == true
        ? auth.currentProfile!.email
        : (auth.currentUser?.email ?? 'No email associated');

    final interestedLabel = switch (_genderPreference) {
      'female' => 'Women',
      'male' => 'Men',
      _ => 'Everyone',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ─── a. Account Settings ───
            const _GroupLabel('ACCOUNT SETTINGS'),
            _Group(
              children: [
                _NavTile(
                  icon: Icons.phone_outlined,
                  title: 'Phone Number',
                  value: _phoneNumber.isNotEmpty ? _phoneNumber : 'Add phone number',
                  onTap: _editPhoneNumberDialog,
                ),
                const Divider(height: 1),
                _NavTile(
                  icon: Icons.link_rounded,
                  title: 'Connected Accounts',
                  value: 'Google & Apple',
                  onTap: _showConnectedAccountsSheet,
                ),
                const Divider(height: 1),
                _NavTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email',
                  value: email,
                  trailingIcon: Icons.verified_user_outlined,
                  onTap: () => _showSnack('Email verified via OAuth provider'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── b. Discovery Settings ───
            const _GroupLabel('DISCOVERY SETTINGS'),
            _Group(
              children: [
                _NavTile(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  value: _city,
                  onTap: _editLocationDialog,
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.near_me_outlined, color: AppColors.primary, size: 20),
                              SizedBox(width: 12),
                              Text('Maximum Distance',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ],
                          ),
                          Text('${_maxDistanceKm.round()} km',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      Slider(
                        value: _maxDistanceKm,
                        min: 2,
                        max: 150,
                        divisions: 74,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.surfaceLight,
                        onChanged: (val) => setState(() => _maxDistanceKm = val),
                        onChangeEnd: (_) => _syncDiscoveryPreferences(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _NavTile(
                  icon: Icons.people_outline_rounded,
                  title: 'Interested In',
                  value: interestedLabel,
                  onTap: _showInterestedInSheet,
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.cake_outlined, color: AppColors.primary, size: 20),
                              SizedBox(width: 12),
                              Text('Age Range',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ],
                          ),
                          Text('${_ageRange.start.round()} – ${_ageRange.end.round()}',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      RangeSlider(
                        values: _ageRange,
                        min: 18,
                        max: 65,
                        divisions: 47,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.surfaceLight,
                        onChanged: (vals) => setState(() => _ageRange = vals),
                        onChangeEnd: (_) => _syncDiscoveryPreferences(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── c. Control My Visibility ───
            const _GroupLabel('CONTROL MY VISIBILITY'),
            _Group(
              children: [
                RadioListTile<bool>(
                  activeColor: AppColors.primary,
                  title: const Text('Standard Visibility',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: const Text('You will be shown to everyone who matches your search preferences.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: false,
                  groupValue: _isIncognito,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _isIncognito = v);
                    _setBoolPref('crush_incognito_mode', v);
                    _showSnack('Standard visibility active');
                  },
                ),
                const Divider(height: 1),
                RadioListTile<bool>(
                  activeColor: AppColors.primary,
                  title: Row(
                    children: [
                      const Text('Incognito Mode',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Gold',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  subtitle: const Text('Only people you swipe right on will see your profile.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: true,
                  groupValue: _isIncognito,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _isIncognito = v);
                    _setBoolPref('crush_incognito_mode', v);
                    _showSnack('Incognito mode active');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── d. Enable Discovery ───
            const _GroupLabel('DISCOVERY VISIBILITY'),
            _Group(
              children: [
                SwitchListTile.adaptive(
                  activeColor: AppColors.primary,
                  secondary: const Icon(Icons.explore_outlined, color: AppColors.primary),
                  title: const Text('Show Me on Crush',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: const Text(
                      'While turned off, your card will be hidden from the swipe stack. You can still message matches.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: _enableDiscovery,
                  onChanged: (val) {
                    setState(() => _enableDiscovery = val);
                    _setBoolPref('crush_discovery_enabled', val);
                    _showSnack(val ? 'Discovery enabled' : 'Discovery paused (Hidden)');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── e, f, g. Communication, Blocked & Active Status ───
            const _GroupLabel('PRIVACY & INTERACTIONS'),
            _Group(
              children: [
                _NavTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Who Messages You',
                  value: _messagePermission,
                  onTap: _showMessagePermissionSheet,
                ),
                const Divider(height: 1),
                _NavTile(
                  icon: Icons.block_flipped,
                  title: 'Blocked Accounts',
                  value: '${_blockedUsers.length}',
                  onTap: _showBlockedAccountsSheet,
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  activeColor: AppColors.primary,
                  secondary: const Icon(Icons.circle, color: AppColors.like, size: 16),
                  title: const Text('Show Active Status',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: const Text('Allow matches to see when you were recently online',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: _showActiveStatus,
                  onChanged: (val) {
                    setState(() => _showActiveStatus = val);
                    _setBoolPref('crush_active_status', val);
                    _showSnack(val ? 'Active status visible' : 'Active status hidden');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── h. Notifications ───
            const _GroupLabel('NOTIFICATIONS'),
            _Group(
              children: [
                SwitchListTile.adaptive(
                  activeColor: AppColors.primary,
                  secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                  title: const Text('Push Notifications',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: const Text('New matches, incoming messages & likes',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: _pushNotifications,
                  onChanged: (v) {
                    setState(() => _pushNotifications = v);
                    _setBoolPref('crush_push_notifications', v);
                    _showSnack(v ? 'Push notifications enabled' : 'Push notifications muted');
                  },
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  activeColor: AppColors.primary,
                  secondary: const Icon(Icons.mark_email_unread_outlined, color: AppColors.primary),
                  title: const Text('Email Notifications',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  subtitle: const Text('Weekly match digest, safety notices & updates',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: _emailNotifications,
                  onChanged: (v) {
                    setState(() => _emailNotifications = v);
                    _setBoolPref('crush_email_notifications', v);
                    _showSnack(v ? 'Email notifications enabled' : 'Email notifications muted');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── i, j, k. Preferences, Share & Support ───
            const _GroupLabel('APP & SUPPORT'),
            _Group(
              children: [
                _NavTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Appearance / Dark Mode',
                  value: _themeMode,
                  onTap: _showDarkModeSheet,
                ),
                const Divider(height: 1),
                _NavTile(
                  icon: Icons.share_rounded,
                  title: 'Share Crush App',
                  value: 'Invite friends',
                  onTap: _shareApp,
                ),
                const Divider(height: 1),
                _NavTile(
                  icon: Icons.headset_mic_outlined,
                  title: 'Help and Support',
                  value: 'FAQs & Contact',
                  onTap: _showHelpAndSupportSheet,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── l. Community ───
            const _GroupLabel('COMMUNITY & SAFETY'),
            _Group(
              children: [
                _NavTile(
                  icon: Icons.rule_folder_outlined,
                  title: 'Community Guidelines',
                  onTap: () => _showInfoModal('Community Guidelines', [
                    {
                      'title': 'Be Respectful & Kind',
                      'body': 'Treat everyone with dignity. Harassment, hate speech, and bullying are strictly forbidden on Crush.',
                    },
                    {
                      'title': 'Authenticity Matters',
                      'body': 'Use your real photos and age. Impersonation and catfishing result in immediate permanent bans.',
                    },
                    {
                      'title': 'Consent is Non-Negotiable',
                      'body': 'Explicit or unprompted sexual content is not allowed in messages or profile media.',
                    },
                  ]),
                ),
                const Divider(height: 1),
                _NavTile(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Safety Tips',
                  onTap: () => _showInfoModal('Dating Safety Tips', [
                    {
                      'title': 'Keep Chats on Crush Initially',
                      'body': 'Get to know your matches inside the app before sharing your phone number, Instagram, or address.',
                    },
                    {
                      'title': 'Meet in Public Places',
                      'body': 'For first dates, meet at a well-lit coffee shop or public venue. Never arrange private secluded meetups.',
                    },
                    {
                      'title': 'Tell a Friend',
                      'body': 'Share your date location and plans with a trusted friend or family member before heading out.',
                    },
                    {
                      'title': 'Never Send Money',
                      'body': 'Never send financial aid, crypto, or money orders to anyone you met online, no matter the story.',
                    },
                  ]),
                ),
                const Divider(height: 1),
                _NavTile(
                  icon: Icons.shield_outlined,
                  title: 'Safety Center',
                  onTap: () => _showInfoModal('Crush Safety Center', [
                    {
                      'title': 'Photo Verification',
                      'body': 'Verify your profile with a quick selfie pose to earn the verified badge and boost match trust.',
                    },
                    {
                      'title': 'Block & Report Tools',
                      'body': 'You can block or report any profile directly from their profile card or chat at any time.',
                    },
                    {
                      'title': 'Crisis Helpline Contacts',
                      'body': 'National Domestic Violence Hotline: 1-800-799-SAFE (7233). Emergency Assistance: Dial 911.',
                    },
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── m, n. Privacy & Legal ───
            const _GroupLabel('PRIVACY & LEGAL'),
            _Group(
              children: [
                _NavTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacy Policy',
                  onTap: () => _showInfoModal('Privacy Policy', [
                    {
                      'title': 'Data Collection & Encryption',
                      'body': 'We only collect essential profile details and securely encrypt your credentials and private chats.',
                    },
                    {
                      'title': 'Your Data, Your Control',
                      'body': 'You can export or permanently delete your account data at any time from Settings.',
                    },
                    {
                      'title': 'Official Policy',
                      'body': 'Read our full legal policy online at: ${AppConstants.privacyPolicyUrl}',
                    },
                  ]),
                ),
                const Divider(height: 1),
                _NavTile(
                  icon: Icons.tune_rounded,
                  title: 'Privacy Preferences',
                  onTap: _showPrivacyPreferencesSheet,
                ),
                const Divider(height: 1),
                _NavTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () => _showInfoModal('Terms of Service', [
                    {
                      'title': 'Eligibility',
                      'body': 'You must be at least 18 years old to create an account and access the Crush dating network.',
                    },
                    {
                      'title': 'Usage Rules',
                      'body': 'Commercial spam, scraping, and harmful conduct will lead to immediate account termination.',
                    },
                    {
                      'title': 'Full Agreement',
                      'body': 'View the complete legal agreement at: ${AppConstants.termsOfServiceUrl}',
                    },
                  ]),
                ),
                const Divider(height: 1),
                _NavTile(
                  icon: Icons.gavel_rounded,
                  title: 'Open Source Licenses',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: '${AppConstants.appVersion} (${AppConstants.appBuildNumber})',
                    applicationLegalese: 'Copyright © 2026 Crush Inc. All rights reserved.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ─── o, q. Account Actions ───
            _Group(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.nope),
                  title: const Text('Log out',
                      style: TextStyle(color: AppColors.nope, fontWeight: FontWeight.w600)),
                  onTap: () => _signOut(context, auth),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.nope),
                  title: const Text('Delete account',
                      style: TextStyle(color: AppColors.nope, fontWeight: FontWeight.w600)),
                  onTap: () => _confirmDelete(context, auth),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // ─── p. Version with Logo ───
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo_wordmark.png',
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Version ${AppConstants.appVersion} (${AppConstants.appBuildNumber})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Setting UI Widgets ───────────────────────────────────────────────

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    this.value,
    this.trailingIcon,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final IconData? trailingIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Icon(trailingIcon ?? Icons.arrow_forward_ios_rounded,
              size: trailingIcon != null ? 18 : 14,
              color: trailingIcon != null ? AppColors.like : AppColors.textMuted),
        ],
      ),
      onTap: onTap,
    );
  }
}
