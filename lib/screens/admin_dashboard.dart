import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> {
  int _selectedTab = 1;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // API state
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _loadError;
  String _token = '';
  AuthUser? _currentUser;

  List<UserModel> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    final q = _searchQuery.toLowerCase();
    return _users
        .where(
          (u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.role.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final token = await AuthService.getToken();
    final user = await AuthService.getCurrentUser();
    if (token == null) {
      _logout();
      return;
    }
    setState(() {
      _token = token;
      _currentUser = user;
    });
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final users = await ApiService.getUsers(_token);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _loadError = e.message;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _loadError = 'Failed to load users. Check your connection.';
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ── Create User ───────────────────────────────────────────────────────────

  void _showCreateUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'user';
    bool isCreating = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Create New User',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1F3C),
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogField(
                controller: nameCtrl,
                hint: 'Full Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _DialogField(
                controller: emailCtrl,
                hint: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _DialogField(
                controller: passwordCtrl,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              const Text(
                'Role',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1F3C),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E7F0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    items: ['admin', 'user']
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r == 'admin' ? 'Administrator' : 'Standard User',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1A1F3C),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDState(() => selectedRole = v!),
                  ),
                ),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dialogError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF8A93B2)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F5BD5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isCreating
                  ? null
                  : () async {
                      setDState(() {
                        isCreating = true;
                        dialogError = null;
                      });
                      try {
                        final newUser = await ApiService.createUser(
                          token: _token,
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: passwordCtrl.text,
                          role: selectedRole,
                        );
                        setState(() => _users.add(newUser));
                        if (ctx.mounted) Navigator.pop(ctx);
                        _showSnack(
                          'User "${newUser.name}" created successfully.',
                        );
                      } on ApiException catch (e) {
                        setDState(() {
                          dialogError = e.message;
                          isCreating = false;
                        });
                      } catch (_) {
                        setDState(() {
                          dialogError = 'Unexpected error. Try again.';
                          isCreating = false;
                        });
                      }
                    },
              child: isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Create',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reset Password ────────────────────────────────────────────────────────

  void _showResetPasswordDialog(UserModel user) {
    final passwordCtrl = TextEditingController();
    bool isResetting = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Reset Password',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1F3C),
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set a new password for ${user.name}',
                style: const TextStyle(color: Color(0xFF8A93B2), fontSize: 13),
              ),
              const SizedBox(height: 14),
              _DialogField(
                controller: passwordCtrl,
                hint: 'New Password (min 6 chars)',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 10),
                _DialogError(message: dialogError!),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isResetting ? null : () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF8A93B2)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F5BD5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isResetting
                  ? null
                  : () async {
                      setDState(() {
                        isResetting = true;
                        dialogError = null;
                      });
                      try {
                        await ApiService.resetPassword(
                          token: _token,
                          userId: user.id,
                          newPassword: passwordCtrl.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _showSnack('Password reset for ${user.name}.');
                      } on ApiException catch (e) {
                        setDState(() {
                          dialogError = e.message;
                          isResetting = false;
                        });
                      } catch (_) {
                        setDState(() {
                          dialogError = 'Unexpected error. Try again.';
                          isResetting = false;
                        });
                      }
                    },
              child: isResetting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Reset',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Toggle Disable ────────────────────────────────────────────────────────

  Future<void> _toggleDisable(UserModel user) async {
    final action = user.disabled ? 're-enable' : 'disable';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '${action[0].toUpperCase()}${action.substring(1)} User?',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Text(
          'Are you sure you want to $action "${user.name}"?',
          style: const TextStyle(color: Color(0xFF8A93B2)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8A93B2)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: user.disabled
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFD97706),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              user.disabled ? 'Re-enable' : 'Disable',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final updated = await ApiService.toggleDisableUser(
        token: _token,
        userId: user.id,
      );
      setState(() {
        final idx = _users.indexWhere((u) => u.id == updated.id);
        if (idx != -1) _users[idx] = updated;
      });
      _showSnack(
        updated.disabled
            ? '${updated.name} has been disabled.'
            : '${updated.name} has been re-enabled.',
      );
    } on ApiException catch (e) {
      _showSnack(e.message, isError: true);
    }
  }

  // ── Delete User ───────────────────────────────────────────────────────────

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete User?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: Color(0xFFB91C1C),
          ),
        ),
        content: Text(
          'This will permanently delete "${user.name}". This action cannot be undone.',
          style: const TextStyle(color: Color(0xFF8A93B2)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8A93B2)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.deleteUser(token: _token, userId: user.id);
      setState(() => _users.removeWhere((u) => u.id == user.id));
      _showSnack('${user.name} has been deleted.');
    } on ApiException catch (e) {
      _showSnack(e.message, isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF3A4DC9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: SafeArea(
        child: isTablet
            ? _buildTabletLayout(context, isTablet)
            : _buildMobileLayout(context, isTablet),
      ),
      bottomNavigationBar: _BottomNav(
        selected: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context),
        backgroundColor: const Color(0xFF3A4DC9),
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Create New User',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isTablet) {
    return Column(
      children: [
        _AppBar(
          isTablet: isTablet,
          userName: _currentUser?.name,
          onLogout: _logout,
        ),
        Expanded(
          child: _buildBody(
            isTablet,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, bool isTablet) {
    return Column(
      children: [
        _AppBar(
          isTablet: isTablet,
          userName: _currentUser?.name,
          onLogout: _logout,
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: _buildBody(
                isTablet,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(bool isTablet, {required EdgeInsets padding}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F5BD5)),
        ),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFF8A93B2),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8A93B2), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadUsers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F5BD5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: padding,
      children: [
        _StatCard(isTablet: isTablet, totalUsers: _users.length),
        SizedBox(height: isTablet ? 20 : 16),
        _SearchBar(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        SizedBox(height: isTablet ? 24 : 20),
        _SectionHeader(isTablet: isTablet, count: _filteredUsers.length),
        SizedBox(height: isTablet ? 14 : 12),
        ..._filteredUsers.map(
          (u) => _UserCard(
            user: u,
            isTablet: isTablet,
            onResetPassword: () => _showResetPasswordDialog(u),
            onToggleDisable: () => _toggleDisable(u),
            onDelete: () => _deleteUser(u),
          ),
        ),
        if (_filteredUsers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'No users found.'
                    : 'No results for "$_searchQuery".',
                style: const TextStyle(color: Color(0xFF8A93B2), fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final bool isTablet;
  final String? userName;
  final VoidCallback onLogout;

  const _AppBar({
    required this.isTablet,
    required this.onLogout,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F2F8),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      child: Row(
        children: [
          Icon(
            Icons.menu_rounded,
            color: const Color(0xFF3A4DC9),
            size: isTablet ? 30 : 26,
          ),
          const SizedBox(width: 12),
          Text(
            'Admin Console',
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1F3C),
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          // Logout button
          GestureDetector(
            onTap: onLogout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0FC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFF4F5BD5),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 12,
                      color: const Color(0xFF4F5BD5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: isTablet ? 48 : 40,
            height: isTablet ? 48 : 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF5B6EE8), Color(0xFF3D4FBF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F5BD5).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: isTablet ? 26 : 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final bool isTablet;
  final int totalUsers;

  const _StatCard({required this.isTablet, required this.totalUsers});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F5BD5).withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL USERS',
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8A93B2),
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 8),
                Text(
                  totalUsers.toString(),
                  style: TextStyle(
                    fontSize: isTablet ? 42 : 36,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1F3C),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Registered accounts',
                  style: TextStyle(
                    fontSize: isTablet ? 13.5 : 12,
                    color: const Color(0xFF8A93B2),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.group_rounded,
            color: const Color(0xFF4F5BD5),
            size: isTablet ? 40 : 32,
          ),
        ],
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14.5, color: Color(0xFF1A1F3C)),
        decoration: const InputDecoration(
          hintText: 'Search by name, email, or role...',
          hintStyle: TextStyle(color: Color(0xFFB0B7CC), fontSize: 14.5),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Color(0xFF8A93B2),
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final bool isTablet;
  final int count;

  const _SectionHeader({required this.isTablet, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'All Users',
          style: TextStyle(
            fontSize: isTablet ? 22 : 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1F3C),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF0FC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count found',
            style: TextStyle(
              fontSize: isTablet ? 13 : 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4F5BD5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── User Card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final UserModel user;
  final bool isTablet;
  final VoidCallback onResetPassword;
  final VoidCallback onToggleDisable;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.isTablet,
    required this.onResetPassword,
    required this.onToggleDisable,
    required this.onDelete,
  });

  Color get _roleColor =>
      user.role == 'admin' ? const Color(0xFF4F5BD5) : const Color(0xFF3D4FBF);
  Color get _roleBg =>
      user.role == 'admin' ? const Color(0xFFEEF0FC) : const Color(0xFFEEF0FC);
  Color get _avatarBg =>
      user.disabled ? const Color(0xFFE5E7EB) : const Color(0xFFD6D9F5);
  Color get _avatarTextColor =>
      user.disabled ? const Color(0xFF9CA3AF) : const Color(0xFF4F5BD5);

  String get _initials {
    final parts = user.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return user.name.substring(0, user.name.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatarSize = isTablet ? 56.0 : 48.0;
    final nameFontSize = isTablet ? 17.0 : 15.5;
    final emailFontSize = isTablet ? 13.5 : 12.5;
    final roleFontSize = isTablet ? 11.5 : 10.5;

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 14 : 10),
      padding: EdgeInsets.all(isTablet ? 18 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 18 : 14),
        border: user.disabled
            ? Border.all(color: const Color(0xFFE5E7EB), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(color: _avatarBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: TextStyle(
                fontSize: isTablet ? 18 : 15,
                fontWeight: FontWeight.w800,
                color: _avatarTextColor,
              ),
            ),
          ),

          SizedBox(width: isTablet ? 14 : 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.w700,
                    color: user.disabled
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF1A1F3C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: emailFontSize,
                    color: const Color(0xFF8A93B2),
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _roleBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: TextStyle(
                          fontSize: roleFontSize,
                          fontWeight: FontWeight.w700,
                          color: _roleColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (user.disabled) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'DISABLED',
                          style: TextStyle(
                            fontSize: roleFontSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF9CA3AF),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: isTablet ? 12 : 8),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconAction(
                icon: Icons.vpn_key_rounded,
                color: const Color(0xFF8A93B2),
                onTap: onResetPassword,
                isTablet: isTablet,
                tooltip: 'Reset Password',
              ),
              SizedBox(width: isTablet ? 8 : 6),
              _IconAction(
                icon: user.disabled
                    ? Icons.check_circle_outline_rounded
                    : Icons.block_rounded,
                color: user.disabled
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFD97706),
                onTap: onToggleDisable,
                isTablet: isTablet,
                tooltip: user.disabled ? 'Re-enable' : 'Disable',
              ),
              SizedBox(width: isTablet ? 8 : 6),
              _IconAction(
                icon: Icons.delete_rounded,
                color: const Color(0xFFEF4444),
                onTap: onDelete,
                isTablet: isTablet,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isTablet;
  final String tooltip;

  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isTablet,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: isTablet ? 38 : 32,
          height: isTablet ? 38 : 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: isTablet ? 20 : 17),
        ),
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final items = [
      _NavItem(Icons.dashboard_rounded, 'Dashboard'),
      _NavItem(Icons.group_rounded, 'Users'),
      _NavItem(Icons.bar_chart_rounded, 'Reports'),
      _NavItem(Icons.settings_rounded, 'Settings'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 40 : 8,
            vertical: isTablet ? 10 : 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = i == selected;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: isTablet ? 90 : 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected
                            ? const Color(0xFF4F5BD5)
                            : const Color(0xFFB0B7CC),
                        size: isTablet ? 28 : 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF4F5BD5)
                              : const Color(0xFFB0B7CC),
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 6 : 0,
                        height: isSelected ? 6 : 0,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4F5BD5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Dialog Helpers ────────────────────────────────────────────────────────────

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;

  const _DialogField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7F0)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1F3C)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB0B7CC), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF8A93B2), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

class _DialogError extends StatelessWidget {
  final String message;
  const _DialogError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
