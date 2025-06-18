// lib/presentation/privacy_policy/view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(() {
      if (_scrollController.offset > 300) {
        if (!_showScrollToTop) {
          setState(() => _showScrollToTop = true);
          _fadeController.forward();
        }
      } else {
        if (_showScrollToTop) {
          setState(() => _showScrollToTop = false);
          _fadeController.reverse();
        }
      }
    });

    // Trigger initial animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ColorManager.primary.withOpacity(0.05),
                  Colors.white,
                  Colors.grey.shade50,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),
          
          // Main content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ColorManager.primary,
                          ColorManager.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.security,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Privacy Policy',
                                    style: GoogleFonts.montserrat(
                                      fontSize: FontSize.s25,
                                      fontWeight: FontWeightManager.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                systemOverlayStyle: SystemUiOverlayStyle.light,
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Last updated card
                      _buildLastUpdatedCard(),
                      const SizedBox(height: 24),
                      
                      // Privacy policy sections
                      ..._buildPrivacyPolicySections(),
                      
                      const SizedBox(height: 40),
                      
                      // Contact section
                      _buildContactSection(),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Scroll to top button
          if (_showScrollToTop)
            Positioned(
              bottom: 30,
              right: 20,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: ColorManager.primary,
                  onPressed: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLastUpdatedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.schedule,
                  color: ColorManager.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Document Information',
                style: GoogleFonts.montserrat(
                  fontSize: FontSize.s18,
                  fontWeight: FontWeightManager.semiBold,
                  color: ColorManager.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Effective Date', '5-6-2025'),
          const SizedBox(height: 8),
          _buildInfoRow('Last Updated', '5-6-2025'),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: FontSize.s14,
              fontWeight: FontWeightManager.medium,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const Text(' : '),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: FontSize.s14,
              fontWeight: FontWeightManager.medium,
              color: ColorManager.black,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPrivacyPolicySections() {
    final sections = [
      {
        'title': '1. About Bird',
        'content': 'Bird is a food delivery application that allows customers to place orders and communicate directly with restaurants via real-time chat. Our goal is to provide a simple, transparent, and user-friendly delivery experience.',
        'icon': Icons.info_outline,
      },
      {
        'title': '2. Information We Collect',
        'content': '''For Customers:
• Personal Information: Name, phone number, email (optional), delivery location
• Chat Data: Messages exchanged with restaurants after order placement
• Order Information: Order history, restaurant preferences, delivery method
• Device Information: IP address, device ID, operating system version, app usage data
• Optional: Profile picture (if uploaded), reviews or feedback

For Restaurants:
• Business Information: Restaurant name, phone number, email address, location
• Menu and Order Data: Menu listings, order records, delivery status
• Chat Data: Communication with customers
• Device Information: Same as above''',
        'icon': Icons.data_usage,
      },
      {
        'title': '3. How We Use Your Information',
        'content': '''• To process and manage food orders
• To facilitate real-time communication between customers and restaurants
• To improve application performance and user experience
• To personalize services based on user preferences
• To ensure account security and prevent unauthorized access''',
        'icon': Icons.how_to_reg,
      },
      {
        'title': '4. Information Sharing and Disclosure',
        'content': '''We do not sell or rent your personal information to third parties.

We may share data in the following circumstances:
• With restaurants you place orders with, for the purpose of delivery and communication
• With third-party service providers such as analytics and infrastructure tools (only limited and non-sensitive data)
• When legally required to do so under applicable law or in response to legal process''',
        'icon': Icons.share,
      },
      {
        'title': '5. Data Security',
        'content': 'We implement reasonable security measures to protect your data from unauthorized access, disclosure, or misuse. These measures include secure servers, encrypted communication channels, and access control. However, no system can be completely secure. You use Bird at your own risk.',
        'icon': Icons.security,
      },
      {
        'title': '6. Your Rights and Choices',
        'content': '''• You may edit or delete your personal profile at any time
• You may request deletion of your account and related data
• You have control over permissions such as location access and notifications
• Chat history is retained to support communication and delivery history''',
        'icon': Icons.settings,
      },
      {
        'title': '7. Use of Third-Party Services',
        'content': '''Bird may use third-party services for:
• Real-time messaging infrastructure
• App analytics (e.g., Firebase, Google Analytics)
• Basic tracking of optional payment confirmations

These third-party providers operate under their own privacy policies. We encourage users to review those separately.''',
        'icon': Icons.extension,
      },
      {
        'title': '8. Children\'s Privacy',
        'content': 'Bird is not designed for users under the age of 5. We do not knowingly collect personal information from children. If we discover such information has been collected, we will take steps to delete it promptly.',
        'icon': Icons.child_care,
      },
      {
        'title': '9. Changes to This Policy',
        'content': 'This Privacy Policy may be updated from time to time. We will notify users of any material changes by updating the policy within the app and/or on our website. Continued use of the application after updates indicates your acceptance of the revised policy.',
        'icon': Icons.update,
      },
    ];

    return sections.asMap().entries.map((entry) {
      final index = entry.key;
      final section = entry.value;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorManager.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      section['icon'] as IconData,
                      color: ColorManager.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      section['title'] as String,
                      style: GoogleFonts.montserrat(
                        fontSize: FontSize.s18,
                        fontWeight: FontWeightManager.semiBold,
                        color: ColorManager.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                section['content'] as String,
                style: GoogleFonts.poppins(
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.regular,
                  color: Colors.grey.shade700,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ).animate(delay: Duration(milliseconds: 100 * index))
            .fadeIn(duration: 600.ms)
            .slideX(begin: 0.3, end: 0),
      );
    }).toList();
  }

  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorManager.primary.withOpacity(0.1),
            ColorManager.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ColorManager.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorManager.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.contact_support,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '10. Contact Us',
                style: GoogleFonts.montserrat(
                  fontSize: FontSize.s20,
                  fontWeight: FontWeightManager.bold,
                  color: ColorManager.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'For questions or concerns about this Privacy Policy, please contact us at:',
            style: GoogleFonts.poppins(
              fontSize: FontSize.s16,
              fontWeight: FontWeightManager.regular,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(Icons.email, 'Email', 'env.bird@gmail.com'),
          const SizedBox(height: 12),
          _buildContactItem(Icons.web, 'Website', 'www.bird.delivery'),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: ColorManager.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: FontSize.s14,
            fontWeight: FontWeightManager.medium,
            color: ColorManager.black,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: FontSize.s14,
              fontWeight: FontWeightManager.regular,
              color: ColorManager.primary,
            ),
          ),
        ),
      ],
    );
  }
}