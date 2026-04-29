import 'package:flutter/material.dart';

class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> {
  int _selectedTab = 1; // 0=Dashboard, 1=Users, 2=Reports, 3=Settings
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_UserModel> _users = [
    _UserModel(
      initials: 'JD',
      name: 'Jane Doe',
      email: 'jane.doe@corporate.com',
      role: 'ADMINISTRATOR',
      roleColor: const Color(0xFF4F5BD5),
      roleBg: const Color(0xFFEEF0FC),
      avatarBg: const Color(0xFFD6D9F5),
      avatarTextColor: const Color(0xFF4F5BD5),
      isActive: true,
    ),
    _UserModel(
      initials: 'MS',
      name: 'Michael Smith',
      email: 'm.smith@operations.net',
      role: 'STANDARD USER',
      roleColor: const Color(0xFF3D4FBF),
      roleBg: const Color(0xFFEEF0FC),
      avatarBg: const Color(0xFF8A93D5),
      avatarTextColor: Colors.white,
      isActive: true,
    ),
    _UserModel(
      initials: 'RW',
      name: 'Rachel Wong',
      email: 'r.wong@finance.io',
      role: 'BILLING LEAD',
      roleColor: const Color(0xFFD97706),
      roleBg: const Color(0xFFFEF3C7),
      avatarBg: const Color(0xFFFDBA74),
      avatarTextColor: const Color(0xFF92400E),
      isActive: true,
    ),
    _UserModel(
      initials: 'AK',
      name: 'Alex Kapranos',
      email: 'a.kapranos@dev.team',
      role: 'DEACTIVATED',
      roleColor: const Color(0xFF9CA3AF),
      roleBg: const Color(0xFFF3F4F6),
      avatarBg: const Color(0xFFE5E7EB),
      avatarTextColor: const Color(0xFF9CA3AF),
      isActive: false,
    ),
  ];

  List<_UserModel> get _filteredUsers {
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String selectedRole = 'STANDARD USER';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Create New User',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1F3C),
            fontSize: 18,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setDState) => Column(
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
                    items: ['ADMINISTRATOR', 'STANDARD USER', 'BILLING LEAD']
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r,
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Create',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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

  // ── Mobile Layout ────────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context, bool isTablet) {
    return Column(
      children: [
        _AppBar(isTablet: isTablet),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _StatCard(isTablet: isTablet),
              const SizedBox(height: 16),
              _SearchBar(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 20),
              _SectionHeader(isTablet: isTablet),
              const SizedBox(height: 12),
              ..._filteredUsers.map(
                (u) => _UserCard(user: u, isTablet: isTablet),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tablet Layout ────────────────────────────────────────────────────────
  Widget _buildTabletLayout(BuildContext context, bool isTablet) {
    return Column(
      children: [
        _AppBar(isTablet: isTablet),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                children: [
                  _StatCard(isTablet: isTablet),
                  const SizedBox(height: 20),
                  _SearchBar(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(isTablet: isTablet),
                  const SizedBox(height: 14),
                  ..._filteredUsers.map(
                    (u) => _UserCard(user: u, isTablet: isTablet),
                  ),
                ],
              ),
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
  const _AppBar({required this.isTablet});

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
                  color: const Color(0xFF4F5BD5).withValues(alpha: (0.3)),
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
  const _StatCard({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F5BD5).withValues(alpha: (0.07)),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '1,284',
                      style: TextStyle(
                        fontSize: isTablet ? 42 : 36,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1F3C),
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            color: Color(0xFF16A34A),
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '12%',
                            style: TextStyle(
                              fontSize: isTablet ? 13 : 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'v.s. previous 30 days',
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
            color: Colors.black.withValues(alpha: (0.05)),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14.5, color: Color(0xFF1A1F3C)),
        decoration: InputDecoration(
          hintText: 'Search by name, email, or role...',
          hintStyle: const TextStyle(color: Color(0xFFB0B7CC), fontSize: 14.5),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF8A93B2),
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final bool isTablet;
  const _SectionHeader({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Active Users',
          style: TextStyle(
            fontSize: isTablet ? 22 : 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1F3C),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Text(
            'View All',
            style: TextStyle(
              fontSize: isTablet ? 15 : 14,
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
  final _UserModel user;
  final bool isTablet;

  const _UserCard({required this.user, required this.isTablet});

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: (0.04)),
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
            decoration: BoxDecoration(
              color: user.avatarBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              user.initials,
              style: TextStyle(
                fontSize: isTablet ? 18 : 15,
                fontWeight: FontWeight.w800,
                color: user.avatarTextColor,
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
                    color: user.isActive
                        ? const Color(0xFF1A1F3C)
                        : const Color(0xFF9CA3AF),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: user.roleBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.role,
                    style: TextStyle(
                      fontSize: roleFontSize,
                      fontWeight: FontWeight.w700,
                      color: user.roleColor,
                      letterSpacing: 0.5,
                    ),
                  ),
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
                onTap: () {},
                isTablet: isTablet,
              ),
              SizedBox(width: isTablet ? 10 : 6),
              _IconAction(
                icon: Icons.delete_rounded,
                color: const Color(0xFFEF4444),
                onTap: () {},
                isTablet: isTablet,
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

  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isTablet ? 38 : 32,
        height: isTablet ? 38 : 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: (0.08)),
          borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: isTablet ? 20 : 17),
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
            color: Colors.black.withValues(alpha: (0.07)),
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

// ── Dialog Field ──────────────────────────────────────────────────────────────
class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _DialogField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
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

// ── Models ────────────────────────────────────────────────────────────────────
class _UserModel {
  final String initials;
  final String name;
  final String email;
  final String role;
  final Color roleColor;
  final Color roleBg;
  final Color avatarBg;
  final Color avatarTextColor;
  final bool isActive;

  const _UserModel({
    required this.initials,
    required this.name,
    required this.email,
    required this.role,
    required this.roleColor,
    required this.roleBg,
    required this.avatarBg,
    required this.avatarTextColor,
    required this.isActive,
  });
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
