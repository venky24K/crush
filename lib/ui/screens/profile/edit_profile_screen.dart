import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:crush/core/constants/app_colors.dart';
import 'package:crush/core/constants/app_constants.dart';
import 'package:crush/core/constants/profile_options.dart';
import 'package:crush/models/profile_model.dart';
import 'package:crush/providers/auth_provider.dart';
import 'package:crush/ui/widgets/crush_image.dart';
import 'package:crush/ui/widgets/interest_chip.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.initialSection});

  /// When set, the screen scrolls to this section on open (profile tab chips).
  final ProfileSection? initialSection;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _PromptDraft {
  _PromptDraft(this.question, String answer)
      : controller = TextEditingController(text: answer);

  String question;
  final TextEditingController controller;
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _titleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const _hintStyle =
      TextStyle(fontSize: 13, color: AppColors.textSecondary);

  static const Map<String, IconData> _fieldIcons = {
    'relationship_goal': Icons.favorite_border_rounded,
    'zodiac': Icons.auto_awesome_outlined,
    'education_level': Icons.school_outlined,
    'family_plans': Icons.child_care_outlined,
    'communication_style': Icons.chat_bubble_outline_rounded,
    'love_style': Icons.volunteer_activism_outlined,
    'drinking': Icons.local_bar_outlined,
    'smoking': Icons.smoking_rooms_outlined,
    'workout': Icons.fitness_center_rounded,
    'pets': Icons.pets_outlined,
  };

  final ImagePicker _picker = ImagePicker();
  final Map<ProfileSection, GlobalKey> _anchors = {
    for (final s in ProfileSection.values) s: GlobalKey(),
  };

  late TextEditingController _bioController;
  late TextEditingController _occupationController;
  late TextEditingController _schoolController;
  late TextEditingController _cityController;
  late TextEditingController _heightController;
  late List<String> _selectedInterests;
  late List<String> _photos;
  late Map<String, String> _basics;
  late Map<String, String> _lifestyle;
  late String? _goal;
  late List<_PromptDraft> _prompts;

  // Controllers of removed prompt cards. Disposed with the screen, because
  // disposing mid-rebuild can hit a TextField that is still attached.
  final List<TextEditingController> _retired = [];
  bool _isSaving = false;

  // Snapshot of the original values used to detect unsaved changes.
  late List<String> _originalPhotos;
  late List<String> _originalInterests;
  late Map<String, String> _originalBasics;
  late Map<String, String> _originalLifestyle;
  late String? _originalGoal;
  late int? _originalHeightCm;

  bool get _isDirty {
    final profile = context.read<AuthProvider>().currentProfile;
    if (profile == null) return false;
    return _bioController.text.trim() != (profile.bio.trim()) ||
        _occupationController.text.trim() != profile.occupation.trim() ||
        _schoolController.text.trim() != profile.school.trim() ||
        _cityController.text.trim() != profile.city.trim() ||
        _heightController.text.trim() !=
            (_originalHeightCm?.toString() ?? '') ||
        !_listEquals(_photos, _originalPhotos) ||
        !_listEquals(_selectedInterests, _originalInterests) ||
        _goal != _originalGoal ||
        _basics.toString() != _originalBasics.toString() ||
        _lifestyle.toString() != _originalLifestyle.toString() ||
        _prompts.any((p) => p.controller.text.trim().isNotEmpty);
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().currentProfile;
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _occupationController =
        TextEditingController(text: profile?.occupation ?? '');
    _schoolController = TextEditingController(text: profile?.school ?? '');
    _cityController = TextEditingController(text: profile?.city ?? '');
    _heightController =
        TextEditingController(text: profile?.heightCm?.toString() ?? '');
    _selectedInterests = List<String>.from(profile?.interests ?? []);
    _photos = List<String>.from(profile?.photos ?? []);
    _basics = Map<String, String>.from(profile?.basics ?? const {});
    _lifestyle = Map<String, String>.from(profile?.lifestyle ?? const {});
    _goal = profile?.relationshipGoal;
    _prompts = [
      for (final p in profile?.prompts ?? const <PromptAnswer>[])
        _PromptDraft(p.prompt, p.answer),
    ];

    // Snapshots for dirty-check.
    _originalPhotos = List<String>.from(_photos);
    _originalInterests = List<String>.from(_selectedInterests);
    _originalBasics = Map<String, String>.from(_basics);
    _originalLifestyle = Map<String, String>.from(_lifestyle);
    _originalGoal = _goal;
    _originalHeightCm = profile?.heightCm;

    final target = widget.initialSection;
    if (target != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _anchors[target]?.currentContext;
        if (ctx != null && ctx.mounted) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: 0.05,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _occupationController.dispose();
    _schoolController.dispose();
    _cityController.dispose();
    _heightController.dispose();
    for (final p in _prompts) {
      p.controller.dispose();
    }
    for (final c in _retired) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Photos
  // ---------------------------------------------------------------------------

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          if (_photos.length < 6) {
            _photos.add(image.path);
          }
        });
      }
    } catch (e) {
      debugPrint('[EditProfileScreen] Photo picker error: $e');
    }
  }

  void _showAddPhotoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const Text(
                'Add Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary, size: 26),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary, size: 26),
                title: const Text(
                  'Take a Photo',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoTile(int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CrushImage(imageUrl: _photos[index], fit: BoxFit.cover),
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
                color: Color(0x99000000),
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
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Filled slots are long-press draggable and also drop targets; dropping on
  /// a slot moves the photo to that position. Slot 0 is the main photo.
  Widget _photoSlot(int index) {
    if (index >= _photos.length) {
      return GestureDetector(
        onTap: _showAddPhotoSheet,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Center(
            child: Icon(Icons.add_a_photo_outlined,
                color: AppColors.primary, size: 28),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tile = _photoTile(index);
        return DragTarget<int>(
          onWillAcceptWithDetails: (details) => details.data != index,
          onAcceptWithDetails: (details) {
            setState(() {
              final moved = _photos.removeAt(details.data);
              _photos.insert(index, moved);
            });
          },
          builder: (context, candidates, _) {
            return LongPressDraggable<int>(
              data: index,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Opacity(opacity: 0.85, child: tile),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: tile),
              child: Container(
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: candidates.isNotEmpty
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: tile,
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Pickers and shared widgets
  // ---------------------------------------------------------------------------

  Widget _sheetHandle() => Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.cardBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  /// Returns the chosen option, '' to clear the field, or null if dismissed.
  Future<String?> _pickOption(
      String title, List<String> options, String? current) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final o in options)
                        ListTile(
                          title: Text(
                            o,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: o == current
                              ? const Icon(Icons.check_rounded,
                                  color: AppColors.primary)
                              : null,
                          onTap: () => Navigator.pop(ctx, o),
                        ),
                      if (current != null)
                        ListTile(
                          title: const Text(
                            'Clear',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          onTap: () => Navigator.pop(ctx, ''),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _choiceTile({
    required IconData icon,
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: Icon(icon, color: AppColors.primary, size: 22),
          title: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  value ?? 'Add',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: value == null
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.textMuted, size: 14),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _fieldTile(
      ProfileFieldDef def, String? value, ValueChanged<String?> onChanged) {
    return _choiceTile(
      icon: _fieldIcons[def.key] ?? Icons.tune_rounded,
      label: def.label,
      value: value,
      onTap: () async {
        final picked = await _pickOption(def.label, def.options, value);
        if (picked == null) return;
        setState(() => onChanged(picked.isEmpty ? null : picked));
      },
    );
  }

  Widget _section(
    ProfileSection section,
    String title, {
    String? subtitle,
    required List<Widget> children,
  }) {
    return Padding(
      key: _anchors[section],
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _titleStyle),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: _hintStyle),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Prompts
  // ---------------------------------------------------------------------------

  Future<void> _addPrompt() async {
    final used = _prompts.map((p) => p.question).toSet();
    final available =
        ProfileOptions.prompts.where((p) => !used.contains(p)).toList();
    final picked = await _pickOption('Pick a prompt', available, null);
    if (picked == null || picked.isEmpty) return;
    setState(() => _prompts.add(_PromptDraft(picked, '')));
  }

  Future<void> _changePrompt(int index) async {
    final draft = _prompts[index];
    final taken = _prompts.map((p) => p.question).toSet()
      ..remove(draft.question);
    final available =
        ProfileOptions.prompts.where((p) => !taken.contains(p)).toList();
    final picked = await _pickOption('Pick a prompt', available, draft.question);
    if (picked == null || picked.isEmpty) return;
    setState(() => draft.question = picked);
  }

  Widget _promptCard(int index) {
    final draft = _prompts[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _changePrompt(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      draft.question,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    size: 18, color: AppColors.textMuted),
                onPressed: () => setState(() {
                  _retired.add(_prompts.removeAt(index).controller);
                }),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextField(
              controller: draft.controller,
              maxLines: 3,
              minLines: 1,
              maxLength: 150,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Your answer'),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  void _snack(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    final current = auth.currentProfile;
    if (current == null) return;

    if (_photos.isEmpty) {
      _snack('Please add at least 1 profile photo.', color: AppColors.nope);
      return;
    }

    final heightText = _heightController.text.trim();
    final int? height = heightText.isEmpty ? null : int.tryParse(heightText);
    if (heightText.isNotEmpty &&
        (height == null || height < 100 || height > 250)) {
      _snack('Enter a height between 100 and 250 cm.', color: AppColors.nope);
      return;
    }

    setState(() => _isSaving = true);

    final updated = current.copyWith(
      bio: _bioController.text.trim(),
      occupation: _occupationController.text.trim(),
      school: _schoolController.text.trim(),
      city: _cityController.text.trim(),
      interests: _selectedInterests,
      photos: _photos,
      heightCm: height,
      clearHeight: height == null,
      relationshipGoal: _goal,
      clearRelationshipGoal: _goal == null,
      basics: Map<String, String>.of(_basics),
      lifestyle: Map<String, String>.of(_lifestyle),
      prompts: [
        for (final p in _prompts)
          if (p.controller.text.trim().isNotEmpty)
            PromptAnswer(
              prompt: p.question,
              answer: p.controller.text.trim(),
            ),
      ],
    );

    await auth.updateProfile(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      _snack('Profile updated successfully! ✨',
          color: AppColors.primary);
      Navigator.pop(context);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_isDirty) {
          Navigator.of(context).pop();
          return;
        }
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Discard changes?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            content: const Text(
              'You have unsaved changes. Leave without saving?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep editing',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nope,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if ((leave ?? false) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              : TextButton(
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
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(
              ProfileSection.photos,
              'Profile Photos',
              subtitle:
                  'Add at least 2 photos. Hold and drag to reorder; the first one is your main photo.',
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) => _photoSlot(index),
                ),
              ],
            ),
            _section(
              ProfileSection.about,
              'About Me',
              children: [
                TextField(
                  controller: _bioController,
                  maxLines: 4,
                  maxLength: 300,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Share a little about yourself, your hobbies...',
                  ),
                ),
              ],
            ),
            _section(
              ProfileSection.prompts,
              'Prompts',
              subtitle: 'Answer up to ${ProfileOptions.maxPrompts} to start the conversation.',
              children: [
                for (var i = 0; i < _prompts.length; i++) _promptCard(i),
                if (_prompts.length < ProfileOptions.maxPrompts)
                  OutlinedButton.icon(
                    onPressed: _addPrompt,
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    label: const Text(
                      'Add a prompt',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
              ],
            ),
            _section(
              ProfileSection.basics,
              'Basics',
              children: [
                for (final def in ProfileOptions.basics)
                  _fieldTile(def, _basics[def.key], (v) {
                    if (v == null) {
                      _basics.remove(def.key);
                    } else {
                      _basics[def.key] = v;
                    }
                  }),
              ],
            ),
            _section(
              ProfileSection.goal,
              'Looking for',
              children: [
                _fieldTile(ProfileOptions.goal, _goal, (v) => _goal = v),
              ],
            ),
            _section(
              ProfileSection.lifestyle,
              'Lifestyle',
              children: [
                for (final def in ProfileOptions.lifestyle)
                  _fieldTile(def, _lifestyle[def.key], (v) {
                    if (v == null) {
                      _lifestyle.remove(def.key);
                    } else {
                      _lifestyle[def.key] = v;
                    }
                  }),
              ],
            ),
            _section(
              ProfileSection.career,
              'Occupation / Job Title',
              children: [
                TextField(
                  controller: _occupationController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. UX Designer',
                    prefixIcon: Icon(Icons.work_outline,
                        color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            _section(
              ProfileSection.education,
              'Education',
              children: [
                TextField(
                  controller: _schoolController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Stanford University',
                    prefixIcon: Icon(Icons.school_outlined,
                        color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            _section(
              ProfileSection.height,
              'Height',
              children: [
                TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 3,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 178',
                    counterText: '',
                    suffixText: 'cm',
                    prefixIcon: Icon(Icons.height_rounded,
                        color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            _section(
              ProfileSection.livingIn,
              'Current City',
              children: [
                TextField(
                  controller: _cityController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. San Francisco, CA',
                    prefixIcon: Icon(Icons.location_on_outlined,
                        color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            _section(
              ProfileSection.interests,
              'Passions & Interests',
              subtitle:
                  'Select up to ${ProfileOptions.maxInterests} interests to help find better matches.',
              children: [
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
                          } else if (_selectedInterests.length <
                              ProfileOptions.maxInterests) {
                            _selectedInterests.add(interest);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Maximum ${ProfileOptions.maxInterests} interests allowed.'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ), // Scaffold
    ); // PopScope
  }
}
