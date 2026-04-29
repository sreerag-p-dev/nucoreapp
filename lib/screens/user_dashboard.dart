import 'package:flutter/material.dart';
import 'package:nucoreapp/models/user_model.dart';
import '../models/dashboard_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  String _token = '';
  AuthUser? _currentUser;

  // Data state
  RevenueData? _revenue;
  SalesSummary? _salesSummary;
  List<CountrySales> _countries = [];
  List<HourlyGrowth> _hourlyGrowth = [];

  bool _isLoading = true;
  String? _loadError;

  // Drill-down state
  CountrySales? _selectedCountry;
  List<StateSales> _states = [];
  bool _loadingStates = false;

  StateSales? _selectedState;
  CitiesPage? _citiesPage;
  bool _loadingCities = false;
  int _currentCityPage = 1;

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
    await _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getRevenue(_token),
        ApiService.getSalesSummary(_token),
        ApiService.getCountries(_token),
        ApiService.getHourlyGrowth(_token),
      ]);
      setState(() {
        _revenue = results[0] as RevenueData;
        _salesSummary = results[1] as SalesSummary;
        _countries = results[2] as List<CountrySales>;
        _hourlyGrowth = results[3] as List<HourlyGrowth>;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _loadError = e.message;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _loadError = 'Failed to load dashboard. Check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStates(CountrySales country) async {
    setState(() {
      _selectedCountry = country;
      _selectedState = null;
      _citiesPage = null;
      _states = [];
      _loadingStates = true;
    });
    try {
      final states = await ApiService.getStates(
        token: _token,
        country: country.country,
      );
      setState(() {
        _states = states;
        _loadingStates = false;
      });
    } on ApiException catch (e) {
      setState(() => _loadingStates = false);
      _showSnack(e.message, isError: true);
    }
  }

  Future<void> _loadCities(StateSales state, {int page = 1}) async {
    setState(() {
      _selectedState = state;
      _currentCityPage = page;
      _loadingCities = true;
    });
    try {
      final cities = await ApiService.getCities(
        token: _token,
        state: state.state,
        page: page,
        limit: 10,
      );
      setState(() {
        _citiesPage = cities;
        _loadingCities = false;
      });
    } on ApiException catch (e) {
      setState(() => _loadingCities = false);
      _showSnack(e.message, isError: true);
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
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: SafeArea(
        child: Column(
          children: [
            _DashboardAppBar(
              isTablet: isTablet,
              userName: _currentUser?.name,
              onLogout: _logout,
              onRefresh: _loadDashboard,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4F5BD5),
                        ),
                      ),
                    )
                  : _loadError != null
                  ? _buildError()
                  : _buildContent(isTablet),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _UserBottomNav(),
    );
  }

  Widget _buildError() {
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
              onPressed: _loadDashboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F5BD5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isTablet) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 24 : 16,
            isTablet ? 20 : 16,
            isTablet ? 24 : 16,
            isTablet ? 32 : 24,
          ),
          children: [
            // ── Revenue Card ──────────────────────────────────────────────
            if (_revenue != null)
              _RevenueCard(data: _revenue!, isTablet: isTablet),
            SizedBox(height: isTablet ? 16 : 12),

            // ── Sales Summary ─────────────────────────────────────────────
            if (_salesSummary != null)
              _SalesSummaryCard(data: _salesSummary!, isTablet: isTablet),
            SizedBox(height: isTablet ? 20 : 16),

            // ── Hourly Growth ─────────────────────────────────────────────
            if (_hourlyGrowth.isNotEmpty)
              _HourlyGrowthCard(data: _hourlyGrowth, isTablet: isTablet),
            SizedBox(height: isTablet ? 20 : 16),

            // ── Country Sales ─────────────────────────────────────────────
            _SectionTitle('Sales by Country', isTablet: isTablet),
            SizedBox(height: isTablet ? 12 : 10),
            ..._countries.map(
              (c) => _CountryRow(
                country: c,
                maxSales: _countries.first.sales,
                isTablet: isTablet,
                isSelected: _selectedCountry?.code == c.code,
                onTap: () => _loadStates(c),
              ),
            ),

            // ── States drill-down ─────────────────────────────────────────
            if (_selectedCountry != null) ...[
              SizedBox(height: isTablet ? 20 : 16),
              _SectionTitle(
                'States — ${_selectedCountry!.country}',
                isTablet: isTablet,
                onBack: () => setState(() {
                  _selectedCountry = null;
                  _states = [];
                  _selectedState = null;
                  _citiesPage = null;
                }),
              ),
              SizedBox(height: isTablet ? 12 : 10),
              if (_loadingStates)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF4F5BD5),
                      ),
                      strokeWidth: 2,
                    ),
                  ),
                )
              else
                ..._states.map(
                  (s) => _StateRow(
                    state: s,
                    maxSales: _states.isNotEmpty ? _states.first.sales : 1,
                    isTablet: isTablet,
                    isSelected: _selectedState?.state == s.state,
                    onTap: () => _loadCities(s),
                  ),
                ),
            ],

            // ── Cities drill-down ─────────────────────────────────────────
            if (_selectedState != null) ...[
              SizedBox(height: isTablet ? 20 : 16),
              _SectionTitle(
                'Cities — ${_selectedState!.state}',
                isTablet: isTablet,
                onBack: () => setState(() {
                  _selectedState = null;
                  _citiesPage = null;
                }),
              ),
              SizedBox(height: isTablet ? 12 : 10),
              if (_loadingCities)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF4F5BD5),
                      ),
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (_citiesPage != null) ...[
                ..._citiesPage!.data.map(
                  (c) => _CityRow(city: c, isTablet: isTablet),
                ),
                SizedBox(height: isTablet ? 12 : 10),
                _PaginationBar(
                  page: _citiesPage!.page,
                  totalPages: _citiesPage!.totalPages,
                  total: _citiesPage!.total,
                  isTablet: isTablet,
                  onPrev: _currentCityPage > 1
                      ? () => _loadCities(
                          _selectedState!,
                          page: _currentCityPage - 1,
                        )
                      : null,
                  onNext: _currentCityPage < _citiesPage!.totalPages
                      ? () => _loadCities(
                          _selectedState!,
                          page: _currentCityPage + 1,
                        )
                      : null,
                ),
              ],
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _DashboardAppBar extends StatelessWidget {
  final bool isTablet;
  final String? userName;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;

  const _DashboardAppBar({
    required this.isTablet,
    required this.onLogout,
    required this.onRefresh,
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
          Container(
            width: isTablet ? 44 : 38,
            height: isTablet ? 44 : 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B6EE8), Color(0xFF3D4FBF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              color: Colors.white,
              size: isTablet ? 24 : 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics Dashboard',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1F3C),
                  letterSpacing: -0.3,
                ),
              ),
              if (userName != null)
                Text(
                  'Welcome, $userName',
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11.5,
                    color: const Color(0xFF8A93B2),
                  ),
                ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              width: isTablet ? 40 : 34,
              height: isTablet ? 40 : 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0FC),
                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF4F5BD5),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
        ],
      ),
    );
  }
}

// ── Revenue Card ──────────────────────────────────────────────────────────────

class _RevenueCard extends StatelessWidget {
  final RevenueData data;
  final bool isTablet;

  const _RevenueCard({required this.data, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F5BD5), Color(0xFF3A4DC9)],
        ),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F5BD5).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL REVENUE',
                style: TextStyle(
                  fontSize: isTablet ? 13 : 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.75),
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data.period,
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 14 : 10),
          Text(
            '\$${_formatRevenue(data.totalRevenue)}',
            style: TextStyle(
              fontSize: isTablet ? 40 : 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${data.currency} • Updated ${_formatDate(data.lastUpdated)}',
            style: TextStyle(
              fontSize: isTablet ? 12.5 : 11.5,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRevenue(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(2);
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Sales Summary Card ────────────────────────────────────────────────────────

class _SalesSummaryCard extends StatelessWidget {
  final SalesSummary data;
  final bool isTablet;

  const _SalesSummaryCard({required this.data, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final successRate = (data.successful.count / data.totalTransactions * 100);
    final cancelRate = (data.cancelled.count / data.totalTransactions * 100);

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Summary',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1F3C),
                ),
              ),
              Text(
                data.period,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A93B2),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            '${_formatCount(data.totalTransactions)} total transactions',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A93B2)),
          ),
          SizedBox(height: isTablet ? 20 : 16),

          // Pie bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: data.successful.count,
                  child: Container(height: 10, color: const Color(0xFF16A34A)),
                ),
                Expanded(
                  flex: data.cancelled.count,
                  child: Container(height: 10, color: const Color(0xFFEF4444)),
                ),
              ],
            ),
          ),

          SizedBox(height: isTablet ? 16 : 14),

          Row(
            children: [
              Expanded(
                child: _SalesStat(
                  label: 'Successful',
                  count: _formatCount(data.successful.count),
                  amount: '\$${_formatAmount(data.successful.amount)}',
                  rate: '${successRate.toStringAsFixed(1)}%',
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFDCFCE7),
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: _SalesStat(
                  label: 'Cancelled',
                  count: _formatCount(data.cancelled.count),
                  amount: '\$${_formatAmount(data.cancelled.amount)}',
                  rate: '${cancelRate.toStringAsFixed(1)}%',
                  color: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFFEE2E2),
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCount(int v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(0)}K';
    }
    return v.toString();
  }

  String _formatAmount(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(2);
  }
}

class _SalesStat extends StatelessWidget {
  final String label;
  final String count;
  final String amount;
  final String rate;
  final Color color;
  final Color bgColor;
  final bool isTablet;

  const _SalesStat({
    required this.label,
    required this.count,
    required this.amount,
    required this.rate,
    required this.color,
    required this.bgColor,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 13 : 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 10 : 8),
          Text(
            count,
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1F3C),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTablet ? 13 : 12,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              rate,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hourly Growth Card ────────────────────────────────────────────────────────

class _HourlyGrowthCard extends StatelessWidget {
  final List<HourlyGrowth> data;
  final bool isTablet;

  const _HourlyGrowthCard({required this.data, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final maxAmount = data.map((h) => h.amount).reduce((a, b) => a > b ? a : b);
    // Show only every 3rd label to avoid clutter
    final visibleLabels = {0, 3, 6, 9, 12, 15, 18, 21, 23};

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hourly Purchase Growth',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1F3C),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sales volume across 24 hours',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF8A93B2)),
          ),
          SizedBox(height: isTablet ? 20 : 16),

          // Mini bar chart
          SizedBox(
            height: isTablet ? 100 : 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((h) {
                final barHeight = (h.amount / maxAmount) * (isTablet ? 90 : 72);
                final isPositive = h.growth >= 0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Tooltip(
                      message:
                          '${h.label}: \$${h.amount.toStringAsFixed(0)}\n${h.growth >= 0 ? '+' : ''}${h.growth.toStringAsFixed(1)}%',
                      child: Container(
                        height: barHeight.clamp(4, isTablet ? 90.0 : 72.0),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? const Color(0xFF4F5BD5)
                              : const Color(0xFFEF4444),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 6),

          // Hour labels
          Row(
            children: data.map((h) {
              return Expanded(
                child: visibleLabels.contains(h.hour)
                    ? Text(
                        h.hour.toString().padLeft(2, '0'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF8A93B2),
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            }).toList(),
          ),

          SizedBox(height: isTablet ? 14 : 12),

          // Legend
          Row(
            children: [
              _LegendDot(color: const Color(0xFF4F5BD5), label: 'Growth'),
              const SizedBox(width: 16),
              _LegendDot(color: const Color(0xFFEF4444), label: 'Decline'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8A93B2)),
        ),
      ],
    );
  }
}

// ── Section Title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isTablet;
  final VoidCallback? onBack;

  const _SectionTitle(this.title, {required this.isTablet, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          GestureDetector(
            onTap: onBack,
            child: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Color(0xFF4F5BD5),
              size: 18,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 18 : 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1F3C),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Country Row ───────────────────────────────────────────────────────────────

class _CountryRow extends StatelessWidget {
  final CountrySales country;
  final double maxSales;
  final bool isTablet;
  final bool isSelected;
  final VoidCallback onTap;

  const _CountryRow({
    required this.country,
    required this.maxSales,
    required this.isTablet,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = country.sales / maxSales;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18 : 14,
          vertical: isTablet ? 14 : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF0FC) : Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          border: isSelected
              ? Border.all(color: const Color(0xFF4F5BD5), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  country.country,
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? const Color(0xFF4F5BD5)
                        : const Color(0xFF1A1F3C),
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${_fmt(country.sales)}',
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1F3C),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  isSelected
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.chevron_right_rounded,
                  color: const Color(0xFF8A93B2),
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: const Color(0xFFF0F2F8),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF4F5BD5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ── State Row ─────────────────────────────────────────────────────────────────

class _StateRow extends StatelessWidget {
  final StateSales state;
  final double maxSales;
  final bool isTablet;
  final bool isSelected;
  final VoidCallback onTap;

  const _StateRow({
    required this.state,
    required this.maxSales,
    required this.isTablet,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = maxSales > 0 ? state.sales / maxSales : 0.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18 : 14,
          vertical: isTablet ? 14 : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          border: isSelected
              ? Border.all(color: const Color(0xFFD97706), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  state.state,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? const Color(0xFFD97706)
                        : const Color(0xFF1A1F3C),
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${_fmt(state.sales)}',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1F3C),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  isSelected
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.chevron_right_rounded,
                  color: const Color(0xFF8A93B2),
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.toDouble(),
                minHeight: 5,
                backgroundColor: const Color(0xFFF0F2F8),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFD97706),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ── City Row ──────────────────────────────────────────────────────────────────

class _CityRow extends StatelessWidget {
  final CitySales city;
  final bool isTablet;

  const _CityRow({required this.city, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 14,
        vertical: isTablet ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_city_rounded,
            color: Color(0xFF8A93B2),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              city.city,
              style: TextStyle(
                fontSize: isTablet ? 14.5 : 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1F3C),
              ),
            ),
          ),
          Text(
            '\$${_fmt(city.sales)}',
            style: TextStyle(
              fontSize: isTablet ? 14 : 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4F5BD5),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(2);
  }
}

// ── Pagination Bar ────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final int total;
  final bool isTablet;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.total,
    required this.isTablet,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PageBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),
          Text(
            'Page $page of $totalPages  •  $total cities',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8A93B2),
              fontWeight: FontWeight.w500,
            ),
          ),
          _PageBtn(icon: Icons.chevron_right_rounded, onTap: onNext),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _PageBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? const Color(0xFFEEF0FC)
              : const Color(0xFFF0F2F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: onTap != null
              ? const Color(0xFF4F5BD5)
              : const Color(0xFFD1D5DB),
          size: 20,
        ),
      ),
    );
  }
}

// ── User Bottom Nav ───────────────────────────────────────────────────────────

class _UserBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final items = [
      _NavItem(Icons.dashboard_rounded, 'Overview'),
      _NavItem(Icons.public_rounded, 'Countries'),
      _NavItem(Icons.show_chart_rounded, 'Growth'),
      _NavItem(Icons.person_rounded, 'Profile'),
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
              final isSelected = i == 0; // Overview always selected for now
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: SizedBox(
                  width: isTablet ? 90 : 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i].icon,
                        color: isSelected
                            ? const Color(0xFF4F5BD5)
                            : const Color(0xFFB0B7CC),
                        size: isTablet ? 28 : 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].label,
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

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
