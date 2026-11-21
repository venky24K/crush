import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:crush/core/constants/app_colors.dart';
import 'package:crush/core/constants/app_constants.dart';
import 'package:crush/providers/auth_provider.dart';
import 'package:crush/ui/widgets/interest_chip.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _bioController;
  late TextEditingController _occupationController;
  late TextEditingController _schoolController;
  late TextEditingController _cityController;
  late List<String> _selectedInterests;
  late List<String> _photos;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().currentProfile;
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _occupationController = TextEditingController(text: profile?.occupation ?? '');
    _schoolController = TextEditingController(text: profile?.school ?? '');
    _cityController = TextEditingController(text: profile?.city ?? '');
    _selectedInterests = List<String>.from(profile?.interests ?? []);
    _photos = List<String>.from(profile?.photos ?? []);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _occupationController.dispose();
    _schoolController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    final auth = context.read<AuthProvider>();
    final current = auth.currentProfile;
    if (current == null) return;

    final updated = current.copyWith(
      bio: _bioController.text,
      occupation: _occupationController.text,
      school: _schoolController.text,
      city: _cityController.text,
      interests: _selectedInterests,
      photos: _photos,
    );

    await auth.updateProfile(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully! ✨'),
          backgroundColor: AppColors.surface,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Photos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add at least 2 photos to make your profile stand out.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                if (index < _photos.length) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: _photos[index],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _photos.removeAt(index));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                      if (index == 0)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Main',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  );
                } else {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _photos.add(
                          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=800&q=80',
                        );
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.cardBorder,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                      ),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 28),

            const Text(
              'About Me',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bioController,
              maxLines: 4,
              maxLength: 300,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Share a little about yourself, your hobbies...',
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Occupation / Job Title',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _occupationController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. UX Designer',
                prefixIcon: Icon(Icons.work_outline, color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Education',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _schoolController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. Stanford University',
                prefixIcon: Icon(Icons.school_outlined, color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Current City',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cityController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. San Francisco, CA',
                prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Passions & Interests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select up to 5 interests to help find better matches.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.availableInterests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return InterestChip(
                  label: interest,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedInterests.remove(interest);
                      } else {
                        if (_selectedInterests.length < 5) {
                          _selectedInterests.add(interest);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Maximum 5 interests allowed.'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
