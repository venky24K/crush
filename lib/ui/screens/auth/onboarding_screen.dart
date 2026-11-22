import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:crush/core/constants/app_colors.dart';
import 'package:crush/core/constants/app_constants.dart';
import 'package:crush/providers/auth_provider.dart';
import 'package:crush/ui/widgets/interest_chip.dart';

class OnboardingScreen extends StatefulWidget {
  final String authProvider;
  final String? initialName;
  final String? initialEmail;

  const OnboardingScreen({
    super.key,
    this.authProvider = 'apple',
    this.initialName,
    this.initialEmail,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 9;

  // Form Fields
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _cityController =
      TextEditingController(text: 'San Francisco, CA');

  DateTime _birthDate = DateTime(2001, 6, 15);
  String _gender = 'Woman';
  String _lookingFor = 'Men';
  String _intention = '💍 Long-term partner';
  final List<String> _selectedInterests = [];
  final List<String> _photos = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
  ];

  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void didUpdateWidget(covariant OnboardingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_nameController.text.isEmpty && widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
    if (_emailController.text.isEmpty && widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _occupationController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  int get _calculatedAge {
    final now = DateTime.now();
    int age = now.year - _birthDate.year;
    if (now.month < _birthDate.month ||
        (now.month == _birthDate.month && now.day < _birthDate.day)) {
      age--;
    }
    return age;
  }

  bool get _isCurrentStepValid {
    switch (_currentStep) {
      case 0: // Name
        return _nameController.text.trim().isNotEmpty;
      case 1: // Age
        return _calculatedAge >= 18;
      case 2: // Gender
        return _gender.isNotEmpty;
      case 3: // Looking For
        return _lookingFor.isNotEmpty;
      case 4: // Intentions
        return _intention.isNotEmpty;
      case 5: // Photos (minimum 2)
        return _photos.length >= 2;
      case 6: // Interests (minimum 5)
        return _selectedInterests.length >= 5;
      case 7: // Bio / Location
        return _cityController.text.trim().isNotEmpty;
      case 8: // Pledge
        return true;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_isCurrentStepValid) return;

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _submitOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      final auth = context.read<AuthProvider>();
      if (auth.needsOnboarding) {
        auth.signOut();
      } else {
        Navigator.maybePop(context);
      }
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (_photos.length < 6) {
            _photos.add(image.path);
          }
        });
      }
    } catch (e) {
      debugPrint('[Onboarding] Image pick error: $e');
    }
  }

  void _addSamplePhotos() {
    setState(() {
      _photos.clear();
      _photos.addAll([
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80',
      ]);
    });
  }

  void _submitOnboarding() async {
    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();

    final genderKey = _gender.toLowerCase() == 'woman'
        ? 'female'
        : (_gender.toLowerCase() == 'man' ? 'male' : 'other');

    final lookingForKey = _lookingFor.toLowerCase() == 'women'
        ? ['female']
        : (_lookingFor.toLowerCase() == 'men' ? ['male'] : ['female', 'male']);

    final success = await auth.completeOnboarding(
      fullName: _nameController.text.trim(),
      birthDate: _birthDate,
      gender: genderKey,
      lookingFor: lookingForKey,
      photos: _photos,
      interests: _selectedInterests,
      bio: _bioController.text.trim(),
      occupation: _occupationController.text.trim(),
      city: _cityController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.textPrimary),
          onPressed: _previousStep,
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 140,
            height: 6,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                '${_currentStep + 1}/$_totalSteps',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildNameStep(),
                  _buildBirthdayStep(),
                  _buildGenderStep(),
                  _buildLookingForStep(),
                  _buildIntentionsStep(),
                  _buildPhotosStep(),
                  _buildInterestsStep(),
                  _buildBioLocationStep(),
                  _buildPledgeStep(),
                ],
              ),
            ),

            // Bottom Continue CTA Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isCurrentStepValid && !_isSubmitting
                      ? _nextStep
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.35),
                    elevation: _isCurrentStepValid ? 2 : 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _currentStep == _totalSteps - 1
                              ? 'I Agree & Enter Crush ✨'
                              : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP 0: First Name ─────────────────────────────────────────────────
  Widget _buildNameStep() {
    return _buildStepScaffold(
      title: "What's your name?",
      subtitle:
          "This is how you'll appear on Crush. Choose the name your matches will see.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'First Name',
              fillColor: AppColors.surfaceLight,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          const Text(
            '🔒 You won\'t be able to change this later to keep profiles authentic.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── STEP 1: Birthday & Age Verification ─────────────────────────────────
  Widget _buildBirthdayStep() {
    final isOldEnough = _calculatedAge >= 18;

    return _buildStepScaffold(
      title: "When's your birthday?",
      subtitle:
          "Your profile will show your age, never your exact birthday. You must be at least 18.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (ctx) => SizedBox(
                  height: 280,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _birthDate,
                    maximumDate: DateTime.now(),
                    minimumYear: 1940,
                    maximumYear: DateTime.now().year,
                    onDateTimeChanged: (date) {
                      setState(() => _birthDate = date);
                    },
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isOldEnough ? AppColors.cardBorder : AppColors.nope,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM dd, yyyy').format(_birthDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Icon(Icons.calendar_today_rounded,
                      color: AppColors.primary, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isOldEnough
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.nope.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOldEnough ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: isOldEnough ? AppColors.like : AppColors.nope,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isOldEnough
                      ? '$_calculatedAge years old (Eligible for Crush)'
                      : 'You must be at least 18 years old',
                  style: TextStyle(
                    color: isOldEnough ? AppColors.like : AppColors.nope,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP 2: Gender Identity ────────────────────────────────────────────
  Widget _buildGenderStep() {
    final options = ['Woman', 'Man', 'Non-Binary', 'More options'];

    return _buildStepScaffold(
      title: "How do you identify?",
      subtitle: "Select the gender identity that best represents you.",
      child: Column(
        children: options.map((option) {
          final isSelected = _gender == option;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSelectableCard(
              title: option,
              isSelected: isSelected,
              onTap: () => setState(() => _gender = option),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── STEP 3: Looking For ────────────────────────────────────────────────
  Widget _buildLookingForStep() {
    final options = ['Women', 'Men', 'Everyone'];

    return _buildStepScaffold(
      title: "Who would you like to see?",
      subtitle:
          "Choose who appears in your discovery deck. You can adjust this anytime.",
      child: Column(
        children: options.map((option) {
          final isSelected = _lookingFor == option;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSelectableCard(
              title: option,
              isSelected: isSelected,
              onTap: () => setState(() => _lookingFor = option),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── STEP 4: Dating Intentions ──────────────────────────────────────────
  Widget _buildIntentionsStep() {
    final options = [
      {'title': '💍 Long-term partner', 'desc': 'Ready for something lasting'},
      {'title': '✨ Casual dating', 'desc': 'Fun dates and good chemistry'},
      {'title': '🥂 Marriage-minded', 'desc': 'Looking for a future spouse'},
      {'title': '☕ New friends', 'desc': 'Expanding my social circle'},
      {'title': '🧭 Still figuring it out', 'desc': 'Open to where things go'},
    ];

    return _buildStepScaffold(
      title: "What are you looking for?",
      subtitle: "Be upfront about your dating intentions so you match with like minds.",
      child: Column(
        children: options.map((opt) {
          final title = opt['title']!;
          final desc = opt['desc']!;
          final isSelected = _intention == title;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() => _intention = title),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            desc,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 22),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── STEP 5: Photos (Minimum 2 Required) ────────────────────────────────
  Widget _buildPhotosStep() {
    return _buildStepScaffold(
      title: "Add your best photos",
      subtitle:
          "Upload at least 2 photos to show your true self. The first photo will be your main card.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_photos.length} of 6 added (min 2 required)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _photos.length >= 2
                      ? AppColors.like
                      : AppColors.textSecondary,
                ),
              ),
              TextButton.icon(
                onPressed: _addSamplePhotos,
                icon: const Icon(Icons.auto_awesome_rounded,
                    size: 16, color: AppColors.primary),
                label: const Text(
                  'Use Sample Photos',
                  style: TextStyle(fontSize: 12, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 6-slot Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              if (index < _photos.length) {
                final photoUrl = _photos[index];
                final isLocal = !photoUrl.startsWith('http');

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: isLocal
                          ? Image.file(File(photoUrl), fit: BoxFit.cover)
                          : Image.network(photoUrl, fit: BoxFit.cover),
                    ),
                    if (index == 0)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Main',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _photos.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return InkWell(
                onTap: _pickPhoto,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.cardBorder,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_a_photo_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── STEP 6: Interests (Select 5+) ──────────────────────────────────────
  Widget _buildInterestsStep() {
    return _buildStepScaffold(
      title: "What are your passions?",
      subtitle:
          "Select at least 5 interests to help us match you with compatible people.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _selectedInterests.length >= 5
                      ? AppColors.like.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedInterests.length} of 5 selected',
                  style: TextStyle(
                    color: _selectedInterests.length >= 5
                        ? AppColors.like
                        : AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
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
                      _selectedInterests.add(interest);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── STEP 7: Bio & Location ─────────────────────────────────────────────
  Widget _buildBioLocationStep() {
    return _buildStepScaffold(
      title: "A little about you",
      subtitle:
          "Write a short bio and add your city so nearby singles know who you are.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio
          TextField(
            controller: _bioController,
            maxLines: 4,
            maxLength: 300,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Share what excites you, your hobbies, or favorite things...',
              fillColor: AppColors.surfaceLight,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // City
          TextField(
            controller: _cityController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'City & Location',
              prefixIcon: const Icon(Icons.location_on_outlined,
                  color: AppColors.primary),
              fillColor: AppColors.surfaceLight,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Occupation
          TextField(
            controller: _occupationController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Occupation / Work (Optional)',
              prefixIcon: const Icon(Icons.work_outline_rounded,
                  color: AppColors.textSecondary),
              fillColor: AppColors.surfaceLight,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP 8: Community Pledge ───────────────────────────────────────────
  Widget _buildPledgeStep() {
    final rules = [
      {
        'icon': Icons.verified_user_rounded,
        'title': 'Be Authentic',
        'desc': 'Use your real photos and honest info. No catfishing or impersonation.'
      },
      {
        'icon': Icons.favorite_rounded,
        'title': 'Treat Everyone with Kindness',
        'desc': 'Communicate with warmth and empathy. Ghosting and harassment are zero-tolerance.'
      },
      {
        'icon': Icons.shield_rounded,
        'title': 'Stay Safe',
        'desc': 'Never share financial credentials. Report any suspicious behavior immediately.'
      },
      {
        'icon': Icons.handshake_rounded,
        'title': 'Consent & Boundaries',
        'desc': 'Respect every boundary. No means no, unconditionally.'
      },
    ];

    return _buildStepScaffold(
      title: "The Crush Pledge",
      subtitle:
          "We are creating a safe, kind, and authentic dating culture. By joining, you commit to these values.",
      child: Column(
        children: rules.map((rule) {
          final icon = rule['icon'] as IconData;
          final title = rule['title'] as String;
          final desc = rule['desc'] as String;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Reusable Helpers ───────────────────────────────────────────────────
  Widget _buildStepScaffold({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }

  Widget _buildSelectableCard({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
