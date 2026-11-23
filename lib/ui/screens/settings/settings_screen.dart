import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crush/core/constants/app_colors.dart';
import 'package:crush/providers/auth_provider.dart';

/// Settings hub. Currently holds only what used to live in the profile tab's
/// settings sheet (email, log out, delete account).
///
/// Next sections, in order: discovery preferences, pause profile,
/// notifications, blocked users, legal links.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, AuthProvider auth) async {
    // This screen is pushed on top of the root route, so after the auth state
    // flips we pop back to root instead of leaving Settings on screen.
    final nav = Navigator.of(context);
    await auth.signOut();
    nav.popUntil((route) => route.isFirst);
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
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? All your matches, chats, photos, and preferences will be permanently erased. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.nope,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.currentProfile?.email.isNotEmpty == true
        ? auth.currentProfile!.email
        : (auth.currentUser?.email ?? 'No email associated');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _GroupLabel('Account'),
          _Group(
            children: [
              ListTile(
                leading: const Icon(Icons.mail_outline,
                    color: AppColors.textSecondary),
                title: const Text('Email',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                subtitle: Text(email,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
              ListTile(
                leading:
                    const Icon(Icons.logout_rounded, color: AppColors.nope),
                title: const Text('Log out',
                    style: TextStyle(
                        color: AppColors.nope, fontWeight: FontWeight.w600)),
                onTap: () => _signOut(context, auth),
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.nope),
                title: const Text('Delete account',
                    style: TextStyle(
                        color: AppColors.nope, fontWeight: FontWeight.w600)),
                onTap: () => _confirmDelete(context, auth),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
          fontSize: 14,
          fontWeight: FontWeight.w700,
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
      // Material so ListTile ink paints on top of the Container's color.
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}
