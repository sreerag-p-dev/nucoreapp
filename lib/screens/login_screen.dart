import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'admin_dashboard.dart';
import 'user_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  int _selectedRole = 0; // 0 = Admin, 1 = User
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Login Logic ───────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.login(email: email, password: password);

      // RBAC: validate selected role tab matches actual role from server
      final expectedRole = _selectedRole == 0 ? 'admin' : 'user';
      if (user.role != expectedRole) {
        await AuthService.logout(); // clear saved token
        setState(() {
          _errorMessage =
              'This account is a "${user.role}" account. Please select the correct role tab.';
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;

      // Navigate based on role
      final destination = user.role == 'admin'
          ? const AdminConsoleScreen()
          : const UserDashboardScreen();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => destination,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to connect. Check your network and try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    final iconSize = isTablet ? 88.0 : 72.0;
    final iconInnerSize = isTablet ? 44.0 : 36.0;
    final iconRadius = isTablet ? 26.0 : 20.0;
    final titleFontSize = isTablet ? 30.0 : 24.0;
    final subtitleFontSize = isTablet ? 16.0 : 13.5;
    final cardPadding = isTablet ? 32.0 : 24.0;
    final verticalSpacing = isTablet ? 48.0 : 32.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 40.0 : 24.0,
                vertical: isTablet ? 48.0 : 32.0,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: verticalSpacing),

                      // App icon
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF5B6EE8), Color(0xFF3D4FBF)],
                          ),
                          borderRadius: BorderRadius.circular(iconRadius),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F5BD5).withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.bar_chart_rounded,
                          color: Colors.white,
                          size: iconInnerSize,
                        ),
                      ),

                      SizedBox(height: isTablet ? 28 : 20),

                      Text(
                        'Analytics Dashboard',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1F3C),
                          letterSpacing: -0.4,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: isTablet ? 10 : 6),

                      Text(
                        'Precision insights for high-stakes decisions',
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: const Color(0xFF8A93B2),
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: isTablet ? 44 : 36),

                      // Login card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            isTablet ? 24 : 20,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F5BD5).withOpacity(0.07),
                              blurRadius: 30,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(cardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RoleToggle(
                              selected: _selectedRole,
                              onChanged: (val) => setState(() {
                                _selectedRole = val;
                                _errorMessage = null;
                              }),
                              isTablet: isTablet,
                            ),

                            SizedBox(height: isTablet ? 32 : 28),

                            _FieldLabel('Email Address', isTablet: isTablet),
                            SizedBox(height: isTablet ? 10 : 8),
                            _InputField(
                              controller: _emailController,
                              hint: 'executive@insight.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              isTablet: isTablet,
                              enabled: !_isLoading,
                            ),

                            SizedBox(height: isTablet ? 24 : 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _FieldLabel('Password', isTablet: isTablet),
                                GestureDetector(
                                  onTap: () {},
                                  child: Text(
                                    'Forgot?',
                                    style: TextStyle(
                                      fontSize: isTablet ? 14.5 : 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF4F5BD5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isTablet ? 10 : 8),
                            _InputField(
                              controller: _passwordController,
                              hint: '••••••••',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              suffixIcon: _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              onSuffixTap: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              isTablet: isTablet,
                              enabled: !_isLoading,
                            ),

                            // Error message
                            if (_errorMessage != null) ...[
                              SizedBox(height: isTablet ? 16 : 12),
                              _ErrorBanner(
                                message: _errorMessage!,
                                isTablet: isTablet,
                              ),
                            ],

                            SizedBox(height: isTablet ? 32 : 28),

                            _LoginButton(
                              label: _selectedRole == 0
                                  ? 'Log In as Admin'
                                  : 'Log In as User',
                              isTablet: isTablet,
                              isLoading: _isLoading,
                              onTap: _isLoading ? null : _handleLogin,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: verticalSpacing),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final bool isTablet;

  const _ErrorBanner({required this.message, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: isTablet ? 13.5 : 12.5,
                color: const Color(0xFFB91C1C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field Label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isTablet;

  const _FieldLabel(this.text, {required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: isTablet ? 14.5 : 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1F3C),
      ),
    );
  }
}

// ── Role Toggle ───────────────────────────────────────────────────────────────

class _RoleToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  final bool isTablet;

  const _RoleToggle({
    required this.selected,
    required this.onChanged,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isTablet ? 52 : 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F8),
        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
      ),
      child: Row(
        children: [
          _ToggleTab(
            label: 'Admin',
            isSelected: selected == 0,
            onTap: () => onChanged(0),
            isTablet: isTablet,
          ),
          _ToggleTab(
            label: 'User',
            isSelected: selected == 1,
            onTap: () => onChanged(1),
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isTablet;

  const _ToggleTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(isTablet ? 11 : 9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 15 : 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF4F5BD5)
                  : const Color(0xFF8A93B2),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Input Field ───────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputType keyboardType;
  final bool isTablet;
  final bool enabled;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.isTablet,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = isTablet ? 15.5 : 14.5;
    final iconSize = isTablet ? 22.0 : 20.0;
    final verticalPadding = isTablet ? 16.0 : 14.0;

    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF7F8FC) : const Color(0xFFF0F1F5),
        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        border: Border.all(color: const Color(0xFFE4E7F0), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        enabled: enabled,
        style: TextStyle(
          fontSize: fontSize,
          color: const Color(0xFF1A1F3C),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFFB0B7CC),
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: const Color(0xFF8A93B2),
            size: iconSize,
          ),
          suffixIcon: suffixIcon != null
              ? GestureDetector(
                  onTap: onSuffixTap,
                  child: Icon(
                    suffixIcon,
                    color: const Color(0xFF8A93B2),
                    size: iconSize,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: verticalPadding,
          ),
        ),
      ),
    );
  }
}

// ── Login Button ──────────────────────────────────────────────────────────────

class _LoginButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isTablet;
  final bool isLoading;

  const _LoginButton({
    required this.label,
    required this.onTap,
    required this.isTablet,
    this.isLoading = false,
  });

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.03,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => _pressController.forward()
          : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _pressController.reverse();
              widget.onTap!();
            }
          : null,
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: double.infinity,
          height: widget.isTablet ? 60 : 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isLoading
                  ? [const Color(0xFF8E9DD6), const Color(0xFF7A89C4)]
                  : [const Color(0xFF5B6EE8), const Color(0xFF3A4DC9)],
            ),
            borderRadius: BorderRadius.circular(widget.isTablet ? 16 : 14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F5BD5).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: widget.isTablet ? 17 : 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}
