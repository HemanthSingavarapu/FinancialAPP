import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(StockMarketApp());
  });
}

class StockMarketApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockMaster Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFF8FAFD),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1A237E),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardTheme(
          elevation: 6,
          margin: EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          titleMedium: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1A237E),
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFF0D1117),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 6,
          margin: EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Color(0xFF161B22),
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          titleMedium: TextStyle(fontSize: 16, color: Colors.grey[300]),
        ),
      ),
      home: StockScreen(),
    );
  }
}

class StockScreen extends StatefulWidget {
  @override
  _StockScreenState createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with SingleTickerProviderStateMixin {
  // State variables
  bool isLoading = false;
  bool isNewsVisible = true;
  bool isHistoryVisible = false;
  Map<String, dynamic>? stockData;
  List<FlSpot> chartData = [];
  List<FlSpot> smaData = [];
  List<FlSpot> rsiData = [];
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> historicalData = [];
  List<Map<String, dynamic>> newsArticles = [];
  String selectedTimeframe = '1D';
  String selectedIndicator = 'None';
  bool hasNetworkConnection = true;
  bool isDarkMode = false;
  String? errorMessage;

  final String apiKey = "Place Your Stocks api key ";
  final String newsApiKey = "Place ypur news api ";

  @override
  void initState() {
    super.initState();
    _checkNetworkConnection();
    _loadThemePreference();
    searchController.addListener(_onSearchChanged);
    _loadPopularStocks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Helper methods
  void _onSearchChanged() {
    if (searchController.text.isEmpty) {
      setState(() {
        stockData = null;
        errorMessage = null;
      });
    }
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  Future<void> _checkNetworkConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      hasNetworkConnection = connectivityResult != ConnectivityResult.none;
    });
  }

  // UI Components
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildMainAppBar(),
      body: _buildHomeScreen(),
    );
  }

  AppBar _buildMainAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      title: Text('Stock App',
          style: Theme.of(context).appBarTheme.titleTextStyle),
      centerTitle: true, // This centers the title
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline),
          onPressed: () => _showAboutDialog(context),
        ),
      ],
    );
  }

  Widget _buildHomeScreen() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSearchBar(),
          SizedBox(height: 20),
          if (!hasNetworkConnection)
            _buildNetworkErrorWidget(),
          if (errorMessage != null)
            _buildErrorWidget(),
          if (isLoading)
            _buildLoadingIndicator()
          else if (stockData == null)
            _buildEmptyState()
          else
            Expanded(
              child: _buildStockContent(),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: "Search stocks (e.g., AAPL, GOOGL, TSLA)",
          hintStyle: TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.blue),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              searchController.clear();
              setState(() {
                stockData = null;
                errorMessage = null;
              });
            },
          )
              : null,
          contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            fetchStockData(value.toUpperCase());
          }
        },
      ),
    );
  }

  Widget _buildNetworkErrorWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red[900]!.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.red[800]!, Colors.red[600]!],
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "No Internet Connection",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Showing limited functionality. Connect to internet for real-time data.",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            child: Text("RETRY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: _checkNetworkConnection,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, color: Colors.red[800]),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Error Loading Data",
                  style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.green.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: TweenAnimationBuilder(
                duration: Duration(seconds: 2),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: value * 2 * pi,
                    child: Icon(
                      Icons.trending_up,
                      size: 40,
                      color: Colors.blue,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Fetching Stock Data...",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Loading real-time market information",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildEmptyState() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Icon(Icons.auto_graph, size: 80,
                  color: Theme.of(context).primaryColor.withOpacity(0.7)),
            ),
            SizedBox(height: 30),
            Text(
              "Welcome to Stock App",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Search for stocks to begin your investment journey",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            _buildPopularStocks(),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularStocks() {
    List<Map<String, String>> popularStocks = [
      {'symbol': 'AAPL', 'name': 'Apple Inc.'},
      {'symbol': 'GOOGL', 'name': 'Alphabet Inc.'},
      {'symbol': 'TSLA', 'name': 'Tesla Inc.'},
      {'symbol': 'MSFT', 'name': 'Microsoft'},
      {'symbol': 'AMZN', 'name': 'Amazon.com'},
      {'symbol': 'META', 'name': 'Meta Platforms'},
    ];

    return Column(
      children: [
        Text(
          "Popular Stocks",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: popularStocks.length,
          itemBuilder: (context, index) {
            final stock = popularStocks[index];
            return _buildStockChip(stock['symbol']!, stock['name']!);
          },
        ),
      ],
    );
  }

  Widget _buildStockChip(String symbol, String name) {
    return GestureDetector(
      onTap: () {
        searchController.text = symbol;
        fetchStockData(symbol);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  symbol.substring(0, 1),
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      symbol,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStockHeader(),
                SizedBox(height: 20),
                _buildStockChart(),
                SizedBox(height: 20),
                _buildStockInfo(),
                SizedBox(height: 20),
                _buildStockHistoryTable(),
                SizedBox(height: 20),
                _buildNewsSection(),
                SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockHeader() {
    final priceChange = stockData!["change"] ?? 0;
    final changePercent = stockData!["changesPercentage"] ?? 0;
    final isPositive = priceChange >= 0;
    final description = stockData!["description"] ?? "No description available";
    final needsReadMore = description.length > 100;
    final symbol = stockData!["symbol"] ?? "N/A";

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stockData!["name"] ?? symbol,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.headlineSmall?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      symbol,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Text(
                "\$${(stockData!["price"] ?? 0).toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
              ),
              SizedBox(width: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "${isPositive ? '+' : ''}${priceChange.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)",
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Divider(),
          SizedBox(height: 16),
          Text(
            "About Company",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineSmall?.color,
            ),
          ),
          SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (needsReadMore)
                TextButton(
                  onPressed: () => _showFullDescriptionDialog(description, symbol),
                  child: Text("Read More", style: TextStyle(color: Colors.blue)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(50, 30),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFullDescriptionDialog(String description, String symbol) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("About $symbol"),
        content: SingleChildScrollView(
          child: Text(description),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    final timeframes = ['1D', '1W', '1M', '3M', '1Y', '5Y'];

    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: timeframes.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, index) {
          final timeframe = timeframes[index];
          return GestureDetector(
            onTap: () {
              setState(() => selectedTimeframe = timeframe);
              _fetchChartData(stockData!["symbol"], timeframe);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: selectedTimeframe == timeframe
                    ? Colors.blue
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                timeframe,
                style: TextStyle(
                  color: selectedTimeframe == timeframe
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIndicatorSelector() {
    final indicators = ['None', 'SMA', 'RSI', 'MACD'];

    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: indicators.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, index) {
          final indicator = indicators[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndicator = indicator;
                if (indicator == 'SMA') {
                  _calculateSMA();
                } else if (indicator == 'RSI') {
                  _calculateRSI();
                }
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: selectedIndicator == indicator
                    ? Colors.blue
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                indicator,
                style: TextStyle(
                  color: selectedIndicator == indicator
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStockChart() {
    return Column(
      children: [
        _buildTimeframeSelector(),
        SizedBox(height: 12),
        _buildIndicatorSelector(),
        SizedBox(height: 16),
        Container(
          height: 300,
          margin: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: chartData.isEmpty
              ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          )
              : Padding(
            padding: EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: _calculateInterval(chartData),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: _calculateTimeInterval(chartData.length),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < chartData.length && index % 5 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _formatChartDate(index),
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: _calculateInterval(chartData),
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            '\$${value.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                minX: 0,
                maxX: chartData.length.toDouble() - 1,
                minY: chartData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) * 0.98,
                maxY: chartData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) * 1.02,
                lineBarsData: _buildChartLines(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<LineChartBarData> _buildChartLines() {
    List<LineChartBarData> lines = [
      LineChartBarData(
        spots: chartData,
        isCurved: true,
        color: Colors.blue,
        barWidth: 3,
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.3),
              Colors.blue.withOpacity(0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        dotData: FlDotData(show: false),
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.lightBlue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    ];

    if (selectedIndicator == 'SMA' && smaData.isNotEmpty) {
      lines.add(
        LineChartBarData(
          spots: smaData,
          isCurved: true,
          color: Colors.orange,
          barWidth: 2,
          dotData: FlDotData(show: false),
        ),
      );
    }

    if (selectedIndicator == 'RSI' && rsiData.isNotEmpty) {
      lines.add(
        LineChartBarData(
          spots: rsiData,
          isCurved: true,
          color: Colors.purple,
          barWidth: 2,
          dotData: FlDotData(show: false),
        ),
      );
    }

    return lines;
  }

  Widget _buildStockInfo() {
    List<Map<String, dynamic>> stockInfo = [
      {"label": "Market Cap", "value": "\$${_formatNumber(stockData!['marketCap'])}", "icon": Icons.business, "color": Colors.blue},
      {"label": "Volume", "value": _formatNumber(stockData!['volume']), "icon": Icons.bar_chart, "color": Colors.green},
      {"label": "52W High", "value": "\$${(stockData!['yearHigh'] ?? 0).toStringAsFixed(2)}", "icon": Icons.trending_up, "color": Colors.green},
      {"label": "52W Low", "value": "\$${(stockData!['yearLow'] ?? 0).toStringAsFixed(2)}", "icon": Icons.trending_down, "color": Colors.red},
      {"label": "P/E Ratio", "value": (stockData!['pe']?.toStringAsFixed(2)) ?? "N/A", "icon": Icons.analytics, "color": Colors.purple},
      {"label": "EPS", "value": (stockData!['eps']?.toStringAsFixed(2)) ?? "N/A", "icon": Icons.show_chart, "color": Colors.orange},
      {"label": "Dividend", "value": stockData!['dividendYield'] != null ? "${(stockData!['dividendYield'] as double).toStringAsFixed(2)}%" : "N/A", "icon": Icons.monetization_on, "color": Colors.amber},
      {"label": "Beta", "value": (stockData!['beta']?.toStringAsFixed(2)) ?? "N/A", "icon": Icons.timeline, "color": Colors.indigo},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: stockInfo.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        return _buildInfoCard(
          stockInfo[index]["label"] as String,
          stockInfo[index]["value"] as String,
          stockInfo[index]["icon"] as IconData,
          stockInfo[index]["color"] as Color,
        );
      },
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockHistoryTable() {
    if (historicalData.isEmpty) {
      return Container();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Historical Data",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
              ),
              IconButton(
                icon: Icon(
                  isHistoryVisible ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    isHistoryVisible = !isHistoryVisible;
                  });
                },
              ),
            ],
          ),
          if (isHistoryVisible) ...[
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24,
                  dataRowHeight: 52,
                  headingRowHeight: 44,
                  columns: [
                    DataColumn(label: _buildTableHeader("Date")),
                    DataColumn(label: _buildTableHeader("Open")),
                    DataColumn(label: _buildTableHeader("High")),
                    DataColumn(label: _buildTableHeader("Low")),
                    DataColumn(label: _buildTableHeader("Close")),
                    DataColumn(label: _buildTableHeader("Volume")),
                  ],
                  rows: historicalData.take(5).map((day) {
                    final close = day['close'] as double;
                    final open = day['open'] as double;
                    final isPositive = close >= open;

                    return DataRow(
                      cells: [
                        DataCell(_buildTableCell(day['date'] as String)),
                        DataCell(_buildTableCell("\$${open.toStringAsFixed(2)}")),
                        DataCell(_buildTableCell("\$${(day['high'] as double).toStringAsFixed(2)}")),
                        DataCell(_buildTableCell("\$${(day['low'] as double).toStringAsFixed(2)}")),
                        DataCell(
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "\$${close.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: isPositive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(_buildTableCell(_formatNumber(day['volume']))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontSize: 12,
      ),
    );
  }

  Widget _buildNewsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Latest News",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
              ),
              IconButton(
                icon: Icon(
                  isNewsVisible ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    isNewsVisible = !isNewsVisible;
                  });
                },
              ),
            ],
          ),
          if (isNewsVisible)
            if (newsArticles.isEmpty)
              _buildNewsShimmer()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: newsArticles.length > 5 ? 5 : newsArticles.length,
                separatorBuilder: (context, index) => SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final article = newsArticles[index];
                  final publishedAt = DateFormat('MMM d, y • HH:mm').format(
                    DateTime.parse(article['publishedAt'] as String),
                  );

                  return _buildNewsCard(article, publishedAt);
                },
              ),
        ],
      ),
    );
  }

  Widget _buildNewsShimmer() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> article, String publishedAt) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _launchURL(article['url'] as String),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article['image'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: article['image'] as String,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 80,
                      color: Theme.of(context).dividerColor,
                      child: Icon(Icons.article, color: Colors.grey),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: Theme.of(context).dividerColor,
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              SizedBox(width: article['image'] != null ? 12 : 0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publishedAt,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      article['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "Read More",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 12, color: Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Data fetching methods
  Future<void> fetchStockData(String symbol) async {
    if (!hasNetworkConnection) {
      setState(() {
        errorMessage = "No internet connection. Please connect to view stock data.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final stockUrl = Uri.parse("https://financialmodelingprep.com/api/v3/quote/$symbol?apikey=$apiKey");
      final profileUrl = Uri.parse("https://financialmodelingprep.com/api/v3/profile/$symbol?apikey=$apiKey");

      final responses = await Future.wait([
        http.get(stockUrl),
        http.get(profileUrl),
      ]);

      if (responses[0].statusCode != 200 || responses[1].statusCode != 200) {
        throw Exception("Failed to fetch stock data");
      }

      final stockJson = json.decode(responses[0].body) as List;
      final profileJson = json.decode(responses[1].body) as List;

      if (stockJson.isEmpty || profileJson.isEmpty) {
        throw Exception("No data available for $symbol");
      }

      setState(() {
        stockData = stockJson[0] as Map<String, dynamic>;
        stockData!["description"] = profileJson[0]["description"] ?? "No description available";
        stockData!["name"] = profileJson[0]["companyName"] ?? symbol;
        _fetchChartData(symbol, selectedTimeframe);
        _fetchHistoricalTableData(symbol);
        fetchStockNews(symbol);
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error: ${e.toString()}";
      });
      print("Error fetching stock data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchChartData(String symbol, String timeframe) async {
    String endpoint;
    switch (timeframe) {
      case '1D': endpoint = '1hour'; break;
      case '1W': endpoint = '4hour'; break;
      case '1M': endpoint = '1day'; break;
      case '3M': endpoint = '1day'; break;
      case '1Y': endpoint = '1day'; break;
      case '5Y': endpoint = '1week'; break;
      default: endpoint = '1day';
    }

    try {
      final url = Uri.parse("LINKS to Fetch dataaaa");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List;
        setState(() {
          chartData = jsonData.map((dayData) {
            return FlSpot(
              (jsonData.indexOf(dayData)).toDouble(),
              double.parse(dayData['close'].toString()),
            );
          }).toList().reversed.toList();
        });
      }
    } catch (e) {
      print("Error fetching chart data: $e");
    }
  }

  Future<void> _fetchHistoricalTableData(String symbol) async {
    try {
      final url = Uri.parse("LINKS to Fetch dataaaa");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final historicalList = jsonData['historical'] as List;

        setState(() {
          historicalData = historicalList.take(5).map((dayData) {
            return {
              'date': DateFormat('MMM d, y').format(DateTime.parse(dayData['date'] as String)),
              'open': dayData['open']?.toDouble() ?? 0.0,
              'high': dayData['high']?.toDouble() ?? 0.0,
              'low': dayData['low']?.toDouble() ?? 0.0,
              'close': dayData['close']?.toDouble() ?? 0.0,
              'volume': dayData['volume'],
            };
          }).toList();
        });
      }
    } catch (e) {
      print("Error fetching historical table data: $e");
    }
  }

  void _calculateSMA() {
    if (chartData.isEmpty) return;

    const period = 5; // 5-period SMA
    final List<FlSpot> smaPoints = [];

    for (int i = period - 1; i < chartData.length; i++) {
      double sum = 0;
      for (int j = 0; j < period; j++) {
        sum += chartData[i - j].y;
      }
      smaPoints.add(FlSpot(i.toDouble(), sum / period));
    }

    setState(() {
      smaData = smaPoints;
    });
  }

  void _calculateRSI() {
    if (chartData.isEmpty) return;

    const period = 14;
    final List<FlSpot> rsiPoints = [];
    List<double> gains = [];
    List<double> losses = [];

    for (int i = 1; i < chartData.length; i++) {
      double change = chartData[i].y - chartData[i - 1].y;
      gains.add(change > 0 ? change : 0);
      losses.add(change < 0 ? -change : 0);
    }

    for (int i = period; i < gains.length; i++) {
      double avgGain = gains.sublist(i - period, i).reduce((a, b) => a + b) / period;
      double avgLoss = losses.sublist(i - period, i).reduce((a, b) => a + b) / period;

      double rs = avgLoss == 0 ? 100 : avgGain / avgLoss;
      double rsi = 100 - (100 / (1 + rs));

      rsiPoints.add(FlSpot(i.toDouble(), rsi));
    }

    setState(() {
      rsiData = rsiPoints;
    });
  }

  Future<void> fetchStockNews(String symbol) async {
    try {
      final newsUrl = Uri.parse("https://newsapi.org/v2/everything?q=$symbol&apiKey=$newsApiKey&sortBy=publishedAt&pageSize=20");
      final newsResponse = await http.get(newsUrl);

      if (newsResponse.statusCode == 200) {
        final newsJson = json.decode(newsResponse.body) as Map<String, dynamic>;
        setState(() {
          newsArticles = (newsJson['articles'] as List).map((article) {
            return {
              'title': article['title'],
              'description': article['description'],
              'url': article['url'],
              'publishedAt': article['publishedAt'],
              'image': article['urlToImage'],
            } as Map<String, dynamic>;
          }).toList();
        });
      } else {
        throw Exception("Failed to fetch news");
      }
    } catch (e) {
      print("Error fetching news: $e");
      setState(() {
        errorMessage = "Could not load news articles";
      });
    }
  }

  Future<void> _loadPopularStocks() async {
    // Pre-load some popular stocks for better UX
    final popularSymbols = ['AAPL', 'GOOGL', 'MSFT'];
    for (final symbol in popularSymbols) {
      try {
        final url = Uri.parse("LINKS to Fetch dataaaa");
        final response = await http.get(url);
        if (response.statusCode == 200) {
          // Cache the response or pre-load data
        }
      } catch (e) {
        print("Error pre-loading $symbol: $e");
      }
    }
  }

  String _formatNumber(dynamic number) {
    if (number == null) return 'N/A';
    if (number is String) {
      number = double.tryParse(number) ?? 0;
    }
    return NumberFormat.compact().format(number);
  }

  double _calculateInterval(List<FlSpot> data) {
    if (data.isEmpty) return 1.0;
    final min = data.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final max = data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return ((max - min) / 4).clamp(0.1, double.infinity);
  }

  double _calculateTimeInterval(int dataLength) {
    if (dataLength <= 10) return 1;
    if (dataLength <= 30) return 5;
    return (dataLength / 5).roundToDouble();
  }

  String _formatChartDate(int index) {
    if (historicalData.isNotEmpty && index < historicalData.length) {
      return historicalData[index]['date'] ?? 'Day ${index + 1}';
    }
    return 'Day ${index + 1}';
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    _saveThemePreference();
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch URL")),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            SizedBox(width: 8),
            Text("StockMaster Pro"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Advanced stock market tracking app with real-time data, technical analysis, and portfolio management."),
              SizedBox(height: 16),
              Text("Features:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("• Real-time stock quotes with detailed metrics"),
              Text("• Interactive price charts with technical indicators"),
              Text("• Historical price data and performance analysis"),
              Text("• Financial news from trusted sources"),
              Text("• Dark/Light theme support"),
              SizedBox(height: 16),
              Text("Data provided by Financial Modeling Prep and NewsAPI"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }
}