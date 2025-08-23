import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bird/constants/router/router.dart';
import '../../service/token_service.dart';
import '../../service/app_startup_service.dart';
import '../../service/connectivity_service.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  
  // Animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _loadingAnimation;
  
  // Background particles
  final List<Particle> _particles = [];
  final Random _random = Random();
  
  // Status indicator
  String _statusMessage = 'Preparing for takeoff...';

  @override
  void initState() {
    super.initState();
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    _initializeParticles();
    _initializeAnimations();
    _checkLoginStatus();
  }

  void _initializeParticles() {
    // Create background particles
    for (int i = 0; i < 30; i++) {
      _particles.add(Particle(
        position: Offset(
          _random.nextDouble() * 400,
          _random.nextDouble() * 800,
        ),
        size: _random.nextDouble() * 8 + 2,
        speed: _random.nextDouble() * 1.5 + 0.5,
        opacity: _random.nextDouble() * 0.6 + 0.2,
      ));
    }
  }

  void _initializeAnimations() {
    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
          .chain(CurveTween(curve: Curves.easeOutQuint)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_logoController);
    
    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _loadingAnimation = CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    );
    
    // Start animations in sequence
    _logoController.forward().then((_) {
      _textController.forward();
    });
  }

  void _updateStatusMessage(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  Future<void> _checkLoginStatus() async {
    // OPTIMIZATION: Reduce initial delay for faster startup
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Status checking begins
    
    _updateStatusMessage('Checking internet connection...');
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Check internet connectivity first
    final hasConnection = await ConnectivityService.hasConnection();
    if (!hasConnection) {
      _updateStatusMessage('No internet connection...');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ConnectivityService.showNoInternetPage(context);
        return;
      }
    }
    
    _updateStatusMessage('Checking login status...');
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      final isLoggedIn = await TokenService.isLoggedIn();
      
      if (isLoggedIn) {
        _updateStatusMessage('Welcome back!');
        await Future.delayed(const Duration(milliseconds: 300));
        
        // OPTIMIZATION: Start location initialization immediately without extra delays
        _updateStatusMessage('Checking location...');
        debugPrint('🚀 SplashScreen: Starting optimized location initialization...');
        
        // OPTIMIZATION: Use timeout to prevent hanging
        final initResult = await AppStartupService.initializeAppGracefully()
            .timeout(const Duration(seconds: 12), onTimeout: () {
          debugPrint('🚀 SplashScreen: Location initialization timed out, proceeding with fallback');
          return {
            'success': true,
            'message': 'Location initialization timed out - using fallback',
            'locationUpdated': false,
            'timeout': true,
          };
        });
        
        debugPrint('🚀 SplashScreen: Location initialization result: $initResult');
        
        if (initResult['locationUpdated'] == true) {
          _updateStatusMessage('Location updated!');
          debugPrint('🚀 SplashScreen: Location was updated successfully');
          await Future.delayed(const Duration(milliseconds: 300));
        } else if (initResult['recentDataUsed'] == true) {
          _updateStatusMessage('Using recent location!');
          debugPrint('🚀 SplashScreen: Using recent location data');
          await Future.delayed(const Duration(milliseconds: 200));
        } else if (initResult['fallbackUsed'] == true) {
          _updateStatusMessage('Using saved location!');
          debugPrint('🚀 SplashScreen: Using existing location data as fallback');
          await Future.delayed(const Duration(milliseconds: 200));
        } else if (initResult['noLocationAccess'] == true) {
          _updateStatusMessage('Ready without location!');
          debugPrint('🚀 SplashScreen: Proceeding without location access');
          await Future.delayed(const Duration(milliseconds: 200));
        } else if (initResult['timeout'] == true) {
          _updateStatusMessage('Ready!');
          debugPrint('🚀 SplashScreen: Location initialization timed out');
          await Future.delayed(const Duration(milliseconds: 200));
        } else {
          _updateStatusMessage('Location ready!');
          debugPrint('🚀 SplashScreen: Location was not updated (${initResult['message']})');
          await Future.delayed(const Duration(milliseconds: 200));
        }
        
        // OPTIMIZATION: Get user data in parallel with location initialization
        final userData = await TokenService.getUserData();
        final token = await TokenService.getToken();
        
        debugPrint('🚀 SplashScreen: Final user data before navigation:');
        debugPrint('  📍 Address: ${userData?['address']}');
        debugPrint('  📍 Latitude: ${userData?['latitude']}');
        debugPrint('  📍 Longitude: ${userData?['longitude']}');
        
        if (mounted) {
          debugPrint('🚀 SplashScreen: Navigating to dashboard...');
          Navigator.pushReplacementNamed(
            context,
            Routes.dashboard,
            arguments: {
              'userData': userData,
              'token': token,
              'locationInitResult': initResult,
            },
          );
        }
      } else {
        _updateStatusMessage('Getting ready...');
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.login);
        }
      }
    } catch (e) {
      _updateStatusMessage('Something went wrong. Retrying...');
      await Future.delayed(const Duration(milliseconds: 800));
      _checkLoginStatus();
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
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFFFF8F5),
                ],
              ),
            ),
          ),
          
          // Particle effect
          CustomPaint(
            painter: ParticlePainter(_particles, _loadingAnimation.value),
            size: Size.infinite,
          ),
          
          // Main Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo - Responsive sizing
                    ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: Container(
                        width: size.width * 0.45, // 45% of screen width
                        height: size.width * 0.45, // Keep it square
                        constraints: const BoxConstraints(
                          minWidth: 120,
                          maxWidth: 200,
                          minHeight: 120,
                          maxHeight: 200,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(size.width * 0.1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.2),
                              blurRadius: size.width * 0.075,
                              spreadRadius: size.width * 0.025,
                            ),
                          ],
                        ),
                        child: _buildLogo(),
                      ),
                    ),
                    
                    SizedBox(height: size.height * 0.05), // 5% of screen height
                  
                    // Animated Text
                    FadeTransition(
                      opacity: _textFadeAnimation,
                      child: SlideTransition(
                        position: Offset(0, _textSlideAnimation.value / 100).toSlidePosition(),
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  Color(0xFFFF9800),
                                  Color(0xFFFF5722),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                'BIRD',
                                style: TextStyle(
                                  fontSize: size.width * 0.12, // Responsive font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, // Applied by shader
                                  letterSpacing: size.width * 0.02, // Responsive letter spacing
                                ),
                              ),
                            ),
                            SizedBox(height: size.height * 0.01), // Responsive spacing
                            Text(
                              'Delivery at Lightning Speed',
                              style: TextStyle(
                                fontSize: size.width * 0.04, // Responsive font size
                                color: Colors.grey[600],
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: size.height * 0.1), // 10% of screen height
                  
                    // Loading Animation
                    FadeTransition(
                      opacity: _loadingAnimation,
                      child: Container(
                        width: size.width * 0.5, // 50% of screen width
                        constraints: const BoxConstraints(
                          minWidth: 150,
                          maxWidth: 250,
                        ),
                        child: Column(
                          children: [
                            // Animated loading dots
                            _buildLoadingDots(),
                            SizedBox(height: size.height * 0.03), // Responsive spacing
                            Text(
                              _statusMessage,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: size.width * 0.035, // Responsive font size
                              ),
                              textAlign: TextAlign.center,
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
        ],
      ),
    );
  }
  
  Widget _buildLogo() {
    return GestureDetector(
      onTap: () {
        // Trigger bounce animation when tapped
        _logoController.reset();
        _logoController.forward();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Stack(
          children: [
            // Logo image
            Image.asset(
              'assets/images/bird.png',
              width: 180,
              height: 180,
            ),
            // Overlay for interactivity hint
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final double delay = index * 0.2;
        final double value = (_loadingAnimation.value - delay).clamp(0.0, 1.0);
        
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
  }
}

// Extension to convert Offset to SlideTransitionPosition
extension OffsetExtension on Offset {
  Animation<Offset> toSlidePosition() {
    return AlwaysStoppedAnimation<Offset>(this);
  }
}

// Simple Particle class
class Particle {
  Offset position;
  double size;
  double speed;
  double opacity;
  
  Particle({
    required this.position,
    required this.size,
    required this.speed,
    required this.opacity,
  });
  
  void update(Size screenSize) {
    // Move particle upward
    position = Offset(
      position.dx,
      position.dy - speed,
    );
    
    // Reset position when off screen
    if (position.dy < -size) {
      position = Offset(
        math.Random().nextDouble() * screenSize.width,
        screenSize.height + size,
      );
      speed = math.Random().nextDouble() * 1.5 + 0.5;
      opacity = math.Random().nextDouble() * 0.6 + 0.2;
    }
  }
}

// Particle painter
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  
  ParticlePainter(this.particles, this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Update particle position
      particle.update(size);
      
      // Draw particle
      final paint = Paint()
        ..color = Colors.orange.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }
  
  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}