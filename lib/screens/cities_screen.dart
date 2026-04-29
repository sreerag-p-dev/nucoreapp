import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';
import '../services/api_service.dart';

class CitiesScreen extends StatefulWidget {
  final String token;
  final StateSales state;

  const CitiesScreen({super.key, required this.token, required this.state});

  @override
  State<CitiesScreen> createState() => _CitiesScreenState();
}

class _CitiesScreenState extends State<CitiesScreen> {
  CitiesPage? _citiesPage;
  bool _isLoading = true;
  String? _loadError;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _currentPage = page;
    });
    try {
      final cities = await ApiService.getCities(
        token: widget.token,
        state: widget.state.state,
        page: page,
        limit: 10,
      );
      setState(() {
        _citiesPage = cities;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _loadError = e.message;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _loadError = 'Failed to load cities. Check your connection.';
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
              widget.state.state,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1F3C),
              ),
            ),
            const Text(
              'Sales by City',
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
            onTap: () => _loadCities(page: _currentPage),
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
              onPressed: () => _loadCities(page: _currentPage),
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
    final page = _citiesPage;
    if (page == null || page.data.isEmpty) {
      return const Center(
        child: Text(
          'No cities found.',
          style: TextStyle(color: Color(0xFF8A93B2), fontSize: 14),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 24 : 16,
                  isTablet ? 20 : 16,
                  isTablet ? 24 : 16,
                  8,
                ),
                itemCount: page.data.length,
                itemBuilder: (context, index) =>
                    _CityRow(city: page.data[index], isTablet: isTablet),
              ),
            ),
            // ── Pagination Bar ────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 24 : 16,
                0,
                isTablet ? 24 : 16,
                isTablet ? 24 : 16,
              ),
              child: _PaginationBar(
                page: page.page,
                totalPages: page.totalPages,
                total: page.total,
                isTablet: isTablet,
                onPrev: _currentPage > 1
                    ? () => _loadCities(page: _currentPage - 1)
                    : null,
                onNext: _currentPage < page.totalPages
                    ? () => _loadCities(page: _currentPage + 1)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
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
  final int page, totalPages, total;
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
