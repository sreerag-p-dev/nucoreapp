class RevenueData {
  final String currency;
  final double totalRevenue;
  final String period;
  final String lastUpdated;

  RevenueData({
    required this.currency,
    required this.totalRevenue,
    required this.period,
    required this.lastUpdated,
  });

  factory RevenueData.fromJson(Map<String, dynamic> json) {
    return RevenueData(
      currency: json['currency'] as String,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      period: json['period'] as String,
      lastUpdated: json['lastUpdated'] as String,
    );
  }
}

class SalesSummary {
  final String period;
  final int totalTransactions;
  final SalesSegment successful;
  final SalesSegment cancelled;
  final String lastUpdated;

  SalesSummary({
    required this.period,
    required this.totalTransactions,
    required this.successful,
    required this.cancelled,
    required this.lastUpdated,
  });

  factory SalesSummary.fromJson(Map<String, dynamic> json) {
    return SalesSummary(
      period: json['period'] as String,
      totalTransactions: json['totalTransactions'] as int,
      successful: SalesSegment.fromJson(
        json['successful'] as Map<String, dynamic>,
      ),
      cancelled: SalesSegment.fromJson(
        json['cancelled'] as Map<String, dynamic>,
      ),
      lastUpdated: json['lastUpdated'] as String,
    );
  }
}

class SalesSegment {
  final int count;
  final double amount;

  SalesSegment({required this.count, required this.amount});

  factory SalesSegment.fromJson(Map<String, dynamic> json) {
    return SalesSegment(
      count: json['count'] as int,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class CountrySales {
  final String country;
  final String code;
  final double sales;

  CountrySales({
    required this.country,
    required this.code,
    required this.sales,
  });

  factory CountrySales.fromJson(Map<String, dynamic> json) {
    return CountrySales(
      country: json['country'] as String,
      code: json['code'] as String,
      sales: (json['sales'] as num).toDouble(),
    );
  }
}

class StateSales {
  final String country;
  final String state;
  final double sales;

  StateSales({required this.country, required this.state, required this.sales});

  factory StateSales.fromJson(Map<String, dynamic> json) {
    return StateSales(
      country: json['country'] as String,
      state: json['state'] as String,
      sales: (json['sales'] as num).toDouble(),
    );
  }
}

class CitySales {
  final String state;
  final String city;
  final double sales;

  CitySales({required this.state, required this.city, required this.sales});

  factory CitySales.fromJson(Map<String, dynamic> json) {
    return CitySales(
      state: json['state'] as String,
      city: json['city'] as String,
      sales: (json['sales'] as num).toDouble(),
    );
  }
}

class CitiesPage {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final List<CitySales> data;

  CitiesPage({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.data,
  });

  factory CitiesPage.fromJson(Map<String, dynamic> json) {
    return CitiesPage(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
      data: (json['data'] as List)
          .map((e) => CitySales.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HourlyGrowth {
  final int hour;
  final String label;
  final double amount;
  final double growth;

  HourlyGrowth({
    required this.hour,
    required this.label,
    required this.amount,
    required this.growth,
  });

  factory HourlyGrowth.fromJson(Map<String, dynamic> json) {
    return HourlyGrowth(
      hour: json['hour'] as int,
      label: json['label'] as String,
      amount: (json['amount'] as num).toDouble(),
      growth: (json['growth'] as num).toDouble(),
    );
  }
}
