import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crush/core/constants/app_colors.dart';
import 'package:crush/providers/auth_provider.dart';
import 'package:crush/ui/screens/auth/onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController =
      TextEditingController(text: 'alex@crush.app');
  final TextEditingController _passwordController =
      TextEditingController(text: 'password123');
  bool _obscurePassword = true;
  bool _showEmailFields = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not sign in. Try Demo Mode or check credentials.'),
          backgroundColor: AppColors.nope,
        ),
      );
    }
  }

  void _handleAppleOnboarding() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithApple();
    if (!success && mounted && !auth.hasSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apple sign-in was cancelled or could not be completed.'),
          backgroundColor: AppColors.nope,
        ),
      );
    }
  }

  void _handleGoogleOnboarding() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (!success && mounted && !auth.hasSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-in was cancelled or could not be completed.'),
          backgroundColor: AppColors.nope,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // Crush Logo Wordmark
                Image.asset(
                  'assets/images/logo_wordmark.png',
                  height: 64,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Spark genuine connections',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 40),

                // ─── Continue with Apple Button ───
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleAppleOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.apple, size: 24, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Continue with Apple',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ─── Continue with Google Button ───
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: auth.isLoading ? null : _handleGoogleOnboarding,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _GoogleLogoIcon(),
                        SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

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

                const SizedBox(height: 16),

                // ─── Toggle Email Fields ───
                if (!_showEmailFields) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _showEmailFields = true),
                      icon: const Icon(Icons.mail_outline_rounded,
                          color: AppColors.textSecondary, size: 20),
                      label: const Text(
                        'Use Email & Password',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Email & Password Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined,
                                color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: AppColors.textSecondary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _handleSignIn,
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Sign In',
                                    style: TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OnboardingScreen(
                                  authProvider: 'email',
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "New to Crush? Create an account",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Legal Notice
                const Text(
                  'By signing up, you agree to Crush\'s Terms of Service and Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom multi-color Google 'G' icon rendered with crisp vector circles & paths
class _GoogleLogoIcon extends StatelessWidget {
  const _GoogleLogoIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Draw Google 4-color arcs
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.butt;

    // Blue arc (top-right & bar)
    strokePaint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1.8),
      -0.6,
      1.1,
      false,
      strokePaint,
    );

    // Green arc (bottom-right & bottom)
    strokePaint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1.8),
      0.5,
      1.6,
      false,
      strokePaint,
    );

    // Yellow arc (bottom-left)
    strokePaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1.8),
      2.1,
      1.1,
      false,
      strokePaint,
    );

    // Red arc (top-left & top)
    strokePaint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1.8),
      3.2,
      1.6,
      false,
      strokePaint,
    );

    // Blue center horizontal cross bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - 1, center.dy),
      Offset(w - 1, center.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
