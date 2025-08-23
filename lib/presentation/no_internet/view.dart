import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/router/router.dart';

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5), // Light cream background like in image
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.1), // Slightly more padding
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top spacing for proper centering
                  SizedBox(height: size.height * 0.08),
                  
                  // Illustration - no background container, just the image
                  Container(
                    height: size.height * 0.4, // Larger image area
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/no_internet.jpg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  
                  // Content spacing
                  SizedBox(height: size.height * 0.05),
                  
                  // Main heading - exactly as in image
                  Text(
                    'No Internet Connection',
                    style: TextStyle(
                      fontSize: 28, // Fixed size instead of responsive for pixel perfect
                      fontWeight: FontWeight.w800, // Extra bold
                      color: const Color(0xFF2D3748), // Dark gray color
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: size.height * 0.02),
                  
                  // Subheading - exactly as in image
                  Text(
                    'Oops! Seems we\'re offline',
                    style: TextStyle(
                      fontSize: 20, // Fixed size
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4A5568), // Medium gray
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: size.height * 0.03),
                  
                  // Description text - exactly as in image
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                    child: Text(
                      'Please check your internet connection and try again. Your delicious food is waiting!',
                      style: TextStyle(
                        fontSize: 16, // Fixed size
                        color: const Color(0xFF718096), // Light gray
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  SizedBox(height: size.height * 0.06),
                  
                  // Try Again button - styled exactly like in image
                  Container(
                    width: double.infinity,
                    height: 54,
                    margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to splash screen to reload the app
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.splash,
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD2691E), // Exact orange-brown color
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0, // No shadow like in image
                        shadowColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Try Again',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom spacing
                  SizedBox(height: size.height * 0.08),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 