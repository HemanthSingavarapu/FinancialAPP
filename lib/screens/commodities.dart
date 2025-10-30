import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  runApp(CryptoApp());
}

class CryptoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Tracker (INR)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Color(0xFFF9FAFB),
        primarySwatch: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'Inter',
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      home: CryptoScreen(),
    );
  }
}

class CryptoScreen extends StatefulWidget {
  @override
  _CryptoScreenState createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen> {
  List<dynamic> _cryptos = [];
  bool _isLoading = true;
  String _error = '';
  String _sortBy = 'market_cap';
  bool _descending = true;
  String _searchQuery = '';
  double _usdToInrRate = 83.0;
  bool _isRefreshing = false;
  int _selectedTimeframe = 0;
  bool _showFavoritesOnly = false;
  Set<String> _favorites = {};

  // Your provided API key
  final String _apiKey = 'Place yur api key';
  final List<String> _timeframes = ['24h', '7d', '30d', '1y'];
  final List<Color> _gradientColors = [
    Colors.blueAccent,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _fetchExchangeRate();
    _fetchData();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _favorites = {'bitcoin', 'ethereum', 'cardano'}.toSet();
    });
  }

  Future<void> _fetchExchangeRate() async {
    try {
      final response = await http
          .get(Uri.parse('Link to fetch data'))
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _usdToInrRate = data['rates']['INR']?.toDouble() ?? 83.0;
        });
      }
    } catch (e) {
      print('Error fetching exchange rate: $e');
      // Fallback exchange rate
      setState(() {
        _usdToInrRate = 83.0;
      });
    }
  }

  Future<void> _fetchData() async {
    if (!_isRefreshing) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
          'Link to fetch '
        headers: {
          'X-CMC_PRO_API_KEY': _apiKey,
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 15));

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          setState(() {
            _cryptos = data['data'];
            _isLoading = false;
            _isRefreshing = false;
            _error = '';
          });
        } else {
          throw Exception('Invalid API response format');
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Invalid API Key. Please check your CoinMarketCap API key.';
          _isLoading = false;
          _isRefreshing = false;
        });
      } else if (response.statusCode == 429) {
        setState(() {
          _error = 'Rate limit exceeded. Please try again later.';
          _isLoading = false;
          _isRefreshing = false;
        });
      } else {
        setState(() {
          _error = 'API Error: ${response.statusCode} - ${response.reasonPhrase}';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print('Error in _fetchData: $e');
      setState(() {
        _error = 'Failed to load data: ${e.toString()}';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  List<dynamic> get _filteredCryptos {
    var result = _cryptos;

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((crypto) =>
      crypto['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          crypto['symbol'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_showFavoritesOnly) {
      result = result.where((crypto) => _favorites.contains(crypto['id'].toString())).toList();
    }

    return result;
  }

  String _formatInr(double amount) {
    if (amount < 1) {
      return '₹${amount.toStringAsFixed(4)}';
    }
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: amount < 10 ? 3 : 2,
      locale: 'en_IN',
    );
    return formatter.format(amount);
  }

  String _formatLargeNumber(double num) {
    if (num >= 1000000000) {
      return '${(num / 1000000000).toStringAsFixed(2)}B';
    } else if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(2)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(2)}K';
    }
    return num.toStringAsFixed(2);
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  void _showCryptoDetails(BuildContext context, dynamic crypto) {
    final quote = crypto['quote']['USD'];
    final priceInr = (quote['price'] ?? 0) * _usdToInrRate;
    final isFavorite = _favorites.contains(crypto['id'].toString());
    final List<FlSpot> pricePoints = _generatePriceHistory(priceInr);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.9,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailHeader(context, crypto, isFavorite),
                _buildDetailChart(pricePoints),
                _buildDetailStats(quote, priceInr, crypto),
                _buildDetailActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generatePriceHistory(double currentPrice) {
    final Random random = Random();
    final List<FlSpot> spots = [];
    double price = currentPrice;

    for (int i = 0; i < 30; i++) {
      double change = (random.nextDouble() - 0.45) * 0.08;
      price = price * (1 + change);
      spots.add(FlSpot(i.toDouble(), price));
    }

    return spots;
  }

  Widget _buildDetailHeader(BuildContext context, dynamic crypto, bool isFavorite) {
    final quote = crypto['quote']['USD'];
    final priceInr = (quote['price'] ?? 0) * _usdToInrRate;
    final change = quote['percent_change_24h'] ?? 0;
    final isUp = change >= 0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      crypto['symbol']?.toString() ?? '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crypto['name']?.toString() ?? 'Unknown',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        crypto['symbol']?.toString() ?? '?',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey[400],
                  size: 28,
                ),
                onPressed: () => _toggleFavorite(crypto['id'].toString()),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatInr(priceInr),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isUp ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      isUp ? Icons.trending_up : Icons.trending_down,
                      size: 18,
                      color: isUp ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${change.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: isUp ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(thickness: 1, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildDetailChart(List<FlSpot> spots) {
    final minY = spots.map((s) => s.y).reduce(min) * 0.95;
    final maxY = spots.map((s) => s.y).reduce(max) * 1.05;

    return Container(
      height: 200,
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 29,
            minY: minY,
            maxY: maxY,
            lineTouchData: LineTouchData(
              getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((spotIndex) {
                  return TouchedSpotIndicatorData(
                    FlLine(color: Colors.blueGrey, strokeWidth: 1),
                    FlDotData(
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.blueGrey,
                          ),
                    ),
                  );
                }).toList();
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    return LineTooltipItem(
                      '₹${touchedSpot.y.toStringAsFixed(2)}',
                      TextStyle(color: Colors.white),
                    );
                  }).toList();
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY - minY) / 4,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 20,
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}d',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: (maxY - minY) / 4,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '₹${value.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: _gradientColors
                        .map((color) => color.withOpacity(0.3))
                        .toList(),
                  ),
                ),
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStats(dynamic quote, double priceInr, dynamic crypto) {
    final marketCapInr = (quote['market_cap'] ?? 0) * _usdToInrRate;
    final volumeInr = (quote['volume_24h'] ?? 0) * _usdToInrRate;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Market Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              _buildStatCard('Market Cap', _formatInr(marketCapInr), Icons.bar_chart, Colors.blue),
              _buildStatCard('24h Volume', _formatInr(volumeInr), Icons.timeline, Colors.green),
              _buildStatCard(
                '24h Change',
                '${(quote['percent_change_24h'] ?? 0).toStringAsFixed(2)}%',
                (quote['percent_change_24h'] ?? 0) >= 0 ? Icons.trending_up : Icons.trending_down,
                (quote['percent_change_24h'] ?? 0) >= 0 ? Colors.green : Colors.red,
              ),
              _buildStatCard(
                '7d Change',
                '${(quote['percent_change_7d'] ?? 0).toStringAsFixed(2)}%',
                (quote['percent_change_7d'] ?? 0) >= 0 ? Icons.trending_up : Icons.trending_down,
                (quote['percent_change_7d'] ?? 0) >= 0 ? Colors.green : Colors.red,
              ),
              _buildStatCard(
                'Circulating Supply',
                '${crypto['circulating_supply']?.toStringAsFixed(0) ?? 'N/A'}',
                Icons.account_balance_wallet,
                Colors.purple,
              ),
              _buildStatCard(
                'Max Supply',
                crypto['max_supply'] != null ? crypto['max_supply'].toStringAsFixed(0) : '∞',
                Icons.all_inclusive,
                Colors.orange,
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(thickness: 1, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close),
              label: Text('Close Details'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoItem(BuildContext context, dynamic crypto) {
    final quote = crypto['quote']['USD'];
    final priceInr = (quote['price'] ?? 0) * _usdToInrRate;
    final change = quote['percent_change_24h'] ?? 0;
    final isUp = change >= 0;
    final isFavorite = _favorites.contains(crypto['id'].toString());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showCryptoDetails(context, crypto),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Crypto rank
              Container(
                width: 24,
                alignment: Alignment.center,
                child: Text(
                  '${crypto['cmc_rank']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(width: 12),

              // Favorite icon
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey[400],
                  size: 20,
                ),
                onPressed: () => _toggleFavorite(crypto['id'].toString()),
              ),

              // Crypto symbol with blue background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  crypto['symbol']?.toString().toUpperCase() ?? '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crypto['name']?.toString() ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatInr(priceInr),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUp ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUp ? Icons.trending_up : Icons.trending_down,
                          size: 16,
                          color: isUp ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${change.toStringAsFixed(2)}%',
                          style: TextStyle(
                              color: isUp ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '₹${_formatLargeNumber((quote['market_cap'] ?? 0) * _usdToInrRate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          strokeWidth: 3,
        ),
        SizedBox(height: 20),
        Text(
          'Please wait while we fetch the latest prices of cryptocurrencies...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crypto Tracker (INR)'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.star : Icons.star_border,
              color: _showFavoritesOnly ? Colors.amber : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _descending = value == 'percent_change_24h' ? false : true;
              });
              _fetchData();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'market_cap',
                child: Row(
                  children: [
                    Icon(Icons.attach_money, size: 20),
                    SizedBox(width: 8),
                    Text('Market Cap'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price',
                child: Row(
                  children: [
                    Icon(Icons.price_change, size: 20),
                    SizedBox(width: 8),
                    Text('Price'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'percent_change_24h',
                child: Row(
                  children: [
                    Icon(Icons.trending_up, size: 20),
                    SizedBox(width: 8),
                    Text('24h Change'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 20),
                    SizedBox(width: 8),
                    Text('Name'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _isRefreshing = true;
          });
          await _fetchData();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search cryptocurrencies...',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : _error.isNotEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(_error, style: TextStyle(fontSize: 16)),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchData,
                      child: Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
                  : _filteredCryptos.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      _showFavoritesOnly
                          ? 'No favorites added'
                          : 'No cryptocurrencies found',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _filteredCryptos.length,
                itemBuilder: (context, index) =>
                    _buildCryptoItem(context, _filteredCryptos[index]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchData,
        child: _isRefreshing
            ? CircularProgressIndicator(color: Colors.white)
            : Icon(Icons.refresh),
        tooltip: 'Refresh Data',
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}