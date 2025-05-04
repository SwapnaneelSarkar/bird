import 'package:flutter/material.dart';
import 'package:bird/constants/router/router.dart';
import '../../service/token_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  
  late Animation<double> _logoAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkLoginStatus();
  }

  void _initializeAnimations() {
    // Logo animation - scale and fade
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _textFadeAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );
    
    _textSlideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Loading animation
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _loadingAnimation = CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    );

    // Start animations in sequence
    _logoController.forward().then((_) {
      _textController.forward();
    });
  }

  Future<void> _checkLoginStatus() async {
    debugPrint('Checking login status...');
    
    // Wait for animations to complete
    await Future.delayed(const Duration(milliseconds: 2500));
    
    final isLoggedIn = await TokenService.isLoggedIn();
    
    if (isLoggedIn) {
      debugPrint('User is logged in, navigating to home');
      
      final userData = await TokenService.getUserData();
      final token = await TokenService.getToken();
      
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          Routes.home,
          arguments: {
            'userData': userData,
            'token': token,
          },
        );
      }
    } else {
      debugPrint('User is not logged in, navigating to login');
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.login);
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFFFF8F5), // Slight orange tint
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                ScaleTransition(
                  scale: _logoAnimation,
                  child: FadeTransition(
                    opacity: _logoAnimation,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/bird.png',
                        width: 180,
                        height: 180,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Animated Text
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: SlideTransition(
                    position: AlwaysStoppedAnimation(
                      Offset(0, _textSlideAnimation.value / 100),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'BIRD',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Delivery at Lightning Speed',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 80),
                
                // Custom Loading Animation
                FadeTransition(
                  opacity: _loadingAnimation,
                  child: Container(
                    width: 200,
                    child: Column(
                      children: [
                        // Animated dots
                        AnimatedBuilder(
                          animation: _loadingController,
                          builder: (context, child) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (index) {
                                final double delay = index * 0.2;
                                final double value = (_loadingController.value - delay).clamp(0.0, 1.0);
                                
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Transform.translate(
                                    offset: Offset(0, -10 * (0.5 - (value - 0.5).abs())),
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.orange[700],
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.orange.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Getting things ready...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}