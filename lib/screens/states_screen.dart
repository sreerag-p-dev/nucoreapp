import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';
import '../services/api_service.dart';
import 'cities_screen.dart';

class StatesScreen extends StatefulWidget {
  final String token;
  final CountrySales country;

  const StatesScreen({super.key, required this.token, required this.country});

  @override
  State<StatesScreen> createState() => _StatesScreenState();
}

class _StatesScreenState extends State<StatesScreen> {
  List<StateSales> _states = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final states = await ApiService.getStates(
        token: widget.token,
        country: widget.country.country,
      );
      setState(() {
        _states = states;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _loadError = e.message;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _loadError = 'Failed to load states. Check your connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1A1F3C),
            size: 20,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.country.country,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1F3C),
              ),
            ),
            const Text(
              'Sales by State',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8A93B2),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _loadStates,
            child: Container(
              margin: EdgeInsets.only(right: isTablet ? 24 : 16),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF4F5BD5),
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F5BD5)),
                ),
              )
            : _loadError != null
            ? _buildError()
            : _buildContent(isTablet),
      ),
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
              onPressed: _loadStates,
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
    if (_states.isEmpty) {
      return const Center(
        child: Text(
          'No states found.',
          style: TextStyle(color: Color(0xFF8A93B2), fontSize: 14),
        ),
      );
    }

    final maxSales = _states.first.sales;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 24 : 16,
            isTablet ? 20 : 16,
            isTablet ? 24 : 16,
            isTablet ? 32 : 24,
          ),
          itemCount: _states.length,
          itemBuilder: (context, index) {
            final state = _states[index];
            return _StateRow(
              state: state,
              maxSales: maxSales,
              isTablet: isTablet,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CitiesScreen(token: widget.token, state: state),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── State Row ─────────────────────────────────────────────────────────────────

class _StateRow extends StatelessWidget {
  final StateSales state;
  final double maxSales;
  final bool isTablet;
  final VoidCallback onTap;

  const _StateRow({
    required this.state,
    required this.maxSales,
    required this.isTablet,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
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
                    color: const Color(0xFF1A1F3C),
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
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8A93B2),
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
