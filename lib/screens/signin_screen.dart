import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'dashboard_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _startEntranceAnimation();
  }

  void _startEntranceAnimation() {
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    setState(() { _isLoading = true; });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() { _isLoading = false; });
      // For now, simulate successful login by going back to splash
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 40),
                Text('Welcome Back', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text('Sign in to continue your journey', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 48),
                _buildTextField(controller: _emailController, label: 'Email Address', hint: 'Enter your email', icon: Ionicons.mail_outline, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 20),
                _buildTextField(controller: _passwordController, label: 'Password', hint: 'Enter your password', icon: Ionicons.lock_closed_outline, obscureText: _obscurePassword, suffixIcon: IconButton(icon: Icon(_obscurePassword ? Ionicons.eye : Ionicons.eye_off, color: Colors.white.withOpacity(0.6)), onPressed: () { setState(() { _obscurePassword = !_obscurePassword; }); })),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: Text('Forgot Password?', style: GoogleFonts.inter(color: const Color(0xFF2196F3), fontWeight: FontWeight.w500)))),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : Text('Sign In', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                )),
                const SizedBox(height: 24),
                Row(children: [Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.1))), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5)))), Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.1)))]),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(FontAwesomeIcons.google, color: Colors.white, size: 20),
                  label: Text('Continue with Google', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                )),
                const SizedBox(height: 24),
                Center(child: TextButton(onPressed: () {}, child: RichText(text: TextSpan(children: [TextSpan(text: "Don't have an account? ", style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7))), TextSpan(text: 'Sign Up', style: GoogleFonts.inter(color: const Color(0xFF2196F3), fontWeight: FontWeight.w600))])))),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, TextInputType? keyboardType, bool obscureText = false, Widget? suffixIcon}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        cursorColor: const Color(0xFF4CAF50),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.6)),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xFF1a1a1a),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2)),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    ]);
  }
}