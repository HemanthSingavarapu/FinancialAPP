import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:iconsax/iconsax.dart';

import '../main.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> introData = [
    {
      'icon': Iconsax.chart_2,
      'title': 'Market Intelligence',
      'description': 'Empower your investment journey with a comprehensive platform that puts the stock market at your fingertips. Explore detailed company profiles, interactive price charts, historic data tables, technical insights, and the latest financial news—all in one seamless experience',
      'color': Color(0xFF6A1B9A),
    },
    {
      'icon': Icons.newspaper,
      'title': 'Financial news ',
      'description': 'Stay informed with the latest financial news directly in the app. Access timely updates, market insights, and headlines',
      'color': Color(0xFF0277BD),
    },
    {
      'icon': Icons.currency_bitcoin,
      'title': 'Crypto Prices',
      'description': 'Track the pulse of the cryptocurrency market with real-time updates on top crypto prices. Stay ahead with insights into market trends and fluctuations, all seamlessly integrated.',
      'color': Color(0xFF2E7D32),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Animated header
              AnimatedContainer(
                duration: Duration(milliseconds: 500),
                height: size.height * 0.1,
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock Market',
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextButton(
                      onPressed: _navigateToMain,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: introData.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                      _animationController.reset();
                      _animationController.forward();
                    });
                  },
                  itemBuilder: (context, index) {
                    final data = introData[index];

                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated icon with gradient
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  data['color'],
                                  data['color'].withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: data['color'].withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              data['icon'],
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 40),

                          // Title with animated underline
                          Column(
                            children: [
                              Text(
                                data['title'],
                                textAlign: TextAlign.center,
                                style: textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              ),
                              SizedBox(height: 8),
                              AnimatedContainer(
                                duration: Duration(milliseconds: 500),
                                width: _currentIndex == index ? 100 : 0,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: data['color'],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          // Description text
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              data['description'],
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                                height: 1.6,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Page indicators with custom animation
              SizedBox(
                height: 60,
                child: Center(
                  child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: introData.length,
                    itemBuilder: (context, index) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 6),
                        width: _currentIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? introData[index]['color']
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _currentIndex == index
                              ? [
                            BoxShadow(
                              color: introData[index]['color'].withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Animated button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 500),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: _currentIndex < introData.length - 1
                      ? _buildNextButton()
                      : _buildGetStartedButton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: () {
        _pageController.nextPage(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        shadowColor: Colors.white.withOpacity(0.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Next',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 8),
          Icon(Iconsax.arrow_right_1, size: 20),
        ],
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return ElevatedButton(
      onPressed: _navigateToMain,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        shadowColor: Colors.blueAccent.withOpacity(0.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Get Started',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 8),
          Icon(Iconsax.arrow_right_1, size: 20),
        ],
      ),
    );
  }
}