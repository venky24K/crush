import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crush/core/constants/app_colors.dart';
import 'package:crush/core/constants/app_constants.dart';
import 'package:crush/providers/auth_provider.dart';
import 'package:crush/ui/screens/auth/onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _showEmailFields = false;
  String? _emailError;
  String? _passwordError;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ─── Validation ───────────────────────────────────────────────────────────

  bool _validateFields() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    bool valid = true;

    setState(() {
      if (email.isEmpty) {
        _emailError = 'Email is required';
        valid = false;
      } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
        _emailError = 'Enter a valid email address';
        valid = false;
      } else {
        _emailError = null;
      }

      if (password.isEmpty) {
        _passwordError = 'Password is required';
        valid = false;
      } else if (password.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
        valid = false;
      } else {
        _passwordError = null;
      }
    });

    return valid;
  }

  // ─── Sign-In Handlers ─────────────────────────────────────────────────────

  Future<void> _handleSignIn() async {
    FocusScope.of(context).unfocus();
    if (!_validateFields()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!success && mounted) {
      _showErrorSnackBar('Incorrect email or password. Please try again.');
    }
  }

  Future<void> _handleAppleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithApple();
    if (!success && mounted && !auth.hasSession) {
      _showErrorSnackBar('Apple sign-in was cancelled or could not be completed.');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (!success && mounted && !auth.hasSession) {
      _showErrorSnackBar('Google sign-in was cancelled or could not be completed.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.nope,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // ─── Logo & Tagline ───
                  Hero(
                    tag: 'crush_logo_hero',
                    child: Image.asset(
                      'assets/images/logo_wordmark.png',
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Spark genuine connections',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 44),

                  // ─── Apple Sign-In ───
                  _SocialButton(
                    label: 'Continue with Apple',
                    icon: const Icon(Icons.apple, size: 22, color: Colors.white),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    isLoading: isLoading,
                    onPressed: _handleAppleSignIn,
                  ),

                  const SizedBox(height: 12),

                  // ─── Google Sign-In ───
                  _SocialButton(
                    label: 'Continue with Google',
                    icon: const _GoogleLogoIcon(),
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                    borderColor: AppColors.cardBorder,
                    isLoading: isLoading,
                    onPressed: _handleGoogleSignIn,
                  ),

                  const SizedBox(height: 24),

                  // ─── Divider ───
                  Row(
                    children: const [
                      Expanded(child: Divider(color: AppColors.cardBorder)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.cardBorder)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ─── Email / Password ───
                  if (!_showEmailFields) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => setState(() => _showEmailFields = true),
                        icon: const Icon(Icons.mail_outline_rounded, size: 18),
                        label: const Text('Use Email & Password'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26)),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    _EmailPasswordCard(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      emailFocus: _emailFocus,
                      passwordFocus: _passwordFocus,
                      obscurePassword: _obscurePassword,
                      emailError: _emailError,
                      passwordError: _passwordError,
                      isLoading: isLoading,
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onSignIn: _handleSignIn,
                      onCreateAccount: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnboardingScreen(
                            authProvider: 'email',
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 36),

                  // ─── Legal ───
                  _LegalRow(onShowSheet: _showLegalSheet),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLegalSheet(BuildContext context,
      {required String title, required String url}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.68,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 14, bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.cardBorder, indent: 24, endIndent: 24),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  Text(
                    title == 'Privacy Policy'
                        ? 'Crush is committed to protecting your privacy and security. We do not sell your personal data to third parties. Your account credentials, photos, matches, and chats are encrypted and used solely to facilitate authentic dating connections.\n\n'
                            '• Age Requirement: Crush is strictly for users 18 years of age or older.\n\n'
                            '• Data Collection: We collect account profile information (name, age, gender, preferences) and photos you explicitly upload to construct your dating profile.\n\n'
                            '• Account Deletion: You may permanently delete your Crush account at any time within the app (My Profile → Account Settings → Delete Account). Upon deletion, all your photos, matches, and messages are permanently purged immediately.'
                        : 'Welcome to Crush. By using our application, you agree to our community standards and terms.\n\n'
                            '• Zero Tolerance: Crush strictly prohibits nudity, harassment, hate speech, spam, and underage usage. Violating accounts are permanently banned without notice.\n\n'
                            '• Safety: You may block any match at any time, or report suspicious or abusive accounts directly from their profile card or chat screen.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.65,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                    label: const Text('View full document online'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      // URL is passed but not opened inline — user can close and visit
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Social Button ────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.isLoading,
    required this.onPressed,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: borderColor != null ? 0 : 1,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: borderColor != null
                ? BorderSide(color: borderColor!, width: 1.2)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Email / Password Card ────────────────────────────────────────────────────

class _EmailPasswordCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final bool obscurePassword;
  final String? emailError;
  final String? passwordError;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  const _EmailPasswordCard({
    required this.emailController,
    required this.passwordController,
    required this.emailFocus,
    required this.passwordFocus,
    required this.obscurePassword,
    required this.emailError,
    required this.passwordError,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onSignIn,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email field
          TextField(
            controller: emailController,
            focusNode: emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            enabled: !isLoading,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Email Address',
              errorText: emailError,
              prefixIcon: const Icon(Icons.email_outlined,
                  color: AppColors.textSecondary, size: 20),
              floatingLabelStyle: const TextStyle(color: AppColors.primary),
            ),
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(passwordFocus),
          ),

          const SizedBox(height: 14),

          // Password field
          TextField(
            controller: passwordController,
            focusNode: passwordFocus,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: passwordError,
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppColors.textSecondary, size: 20),
              floatingLabelStyle: const TextStyle(color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: onTogglePassword,
              ),
            ),
            onSubmitted: (_) => onSignIn(),
          ),

          const SizedBox(height: 18),

          // Sign In button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSignIn,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 4),

          // Create account
          Center(
            child: TextButton(
              onPressed: isLoading ? null : onCreateAccount,
              child: const Text(
                'New to Crush? Create an account',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Legal Row ────────────────────────────────────────────────────────────────

class _LegalRow extends StatelessWidget {
  final void Function(BuildContext, {required String title, required String url}) onShowSheet;

  const _LegalRow({required this.onShowSheet});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'By signing up, you agree to our ',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        GestureDetector(
          onTap: () => onShowSheet(
            context,
            title: 'Terms of Service',
            url: AppConstants.termsOfServiceUrl,
          ),
          child: const Text(
            'Terms of Service',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const Text(
          ' and ',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        GestureDetector(
          onTap: () => onShowSheet(
            context,
            title: 'Privacy Policy',
            url: AppConstants.privacyPolicyUrl,
          ),
          child: const Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const Text(
          '.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

// ─── Proper Google G Logo ─────────────────────────────────────────────────────

class _GoogleLogoIcon extends StatelessWidget {
  const _GoogleLogoIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final r = w / 2;
    final strokeW = w * 0.167;
    final halfStroke = strokeW / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    // Red – top arc (270° → 360° and a bit past, covering top-left through top-right)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r - halfStroke),
      _deg(-220), _deg(110), false, paint,
    );

    // Green – right arc continuing down (from ~-110° → -60°)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r - halfStroke),
      _deg(-110), _deg(130), false, paint,
    );

    // Yellow – bottom-left arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r - halfStroke),
      _deg(20), _deg(70), false, paint,
    );

    // Blue – left arc (bottom-left through top-left going upward, plus the cross bar)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r - halfStroke),
      _deg(90), _deg(130), false, paint,
    );

    // Blue horizontal cross-bar (right half)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(w / 2, h / 2),
      Offset(w - halfStroke, h / 2),
      barPaint,
    );

    // Blue cap to close the gap at right-center
    final capPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), strokeW / 2.4, capPaint);
  }

  static double _deg(double degrees) => degrees * 3.1415926535 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
