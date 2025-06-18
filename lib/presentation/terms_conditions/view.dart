// lib/presentation/terms_conditions/view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';

class TermsConditionsPage extends StatefulWidget {
  const TermsConditionsPage({Key? key}) : super(key: key);

  @override
  State<TermsConditionsPage> createState() => _TermsConditionsPageState();
}

class _TermsConditionsPageState extends State<TermsConditionsPage>
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
                                    Icons.gavel,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Terms & Conditions',
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
                      
                      // Terms and conditions sections
                      ..._buildTermsSections(),
                      
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

  List<Widget> _buildTermsSections() {
    final sections = [
      {
        'title': '1. Acceptance of Terms',
        'content': 'By accessing and using the Bird application, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
        'icon': Icons.check_circle_outline,
      },
      {
        'title': '2. Service Description',
        'content': 'Bird is a food delivery platform that connects customers with restaurants. We facilitate order placement, real-time communication between customers and restaurants, and coordinate delivery services. Bird acts as an intermediary between customers and restaurants.',
        'icon': Icons.restaurant_menu,
      },
      {
        'title': '3. User Accounts and Registration',
        'content': 'You must provide accurate and complete information during registration. You are responsible for maintaining the confidentiality of your account. You must be at least 5 years old to use our services. One person may not maintain multiple accounts. You are responsible for all activities that occur under your account.',
        'icon': Icons.person_add,
      },
      {
        'title': '4. Order Placement and Payment',
        'content': 'All orders placed through the app constitute an offer to purchase. Prices are as displayed at the time of order placement. Payment is processed through secure third-party payment providers. You agree to pay all charges incurred by your account. Delivery fees and taxes may apply as shown during checkout.',
        'icon': Icons.payment,
      },
      {
        'title': '5. Delivery and Fulfillment',
        'content': 'Estimated delivery times are approximate and not guaranteed. Restaurants are responsible for food preparation and quality. Bird facilitates delivery coordination but does not guarantee delivery times. You must be available to receive your order at the delivery location. Additional charges may apply for failed delivery attempts.',
        'icon': Icons.delivery_dining,
      },
      {
        'title': '6. Cancellation and Refunds',
        'content': 'Orders may be cancelled before restaurant confirmation. Refund policies are determined by individual restaurants. Bird may process refunds for technical errors or service failures. Cancellation fees may apply in certain circumstances. Disputes should be reported through the app\'s support system.',
        'icon': Icons.cancel,
      },
      {
        'title': '7. User Conduct',
        'content': 'You agree not to use the service for illegal purposes or activities, harass abuse or harm other users restaurants or delivery personnel, post false misleading or inappropriate content, attempt to gain unauthorized access to our systems, use automated systems to access the service, or violate any applicable local state or federal laws.',
        'icon': Icons.rule,
      },
      {
        'title': '8. Intellectual Property',
        'content': 'All content on the Bird app is protected by intellectual property laws. You may not reproduce distribute or create derivative works without permission. Restaurant logos and menus are the property of respective restaurants. Bird logos and trademarks are the property of Bird. User-generated content remains your property but you grant us license to use it.',
        'icon': Icons.copyright,
      },
      {
        'title': '9. Limitation of Liability',
        'content': 'Bird is not liable for food quality safety or preparation. We are not responsible for actions of restaurants or delivery personnel. Our liability is limited to the amount paid for the specific order. We do not guarantee uninterrupted or error-free service. Use of the service is at your own risk.',
        'icon': Icons.warning,
      },
      {
        'title': '10. Privacy and Data Protection',
        'content': 'Your privacy is important to us. Please review our Privacy Policy which governs the collection use and sharing of your personal information. By using our service you consent to the collection and use of information as outlined in our Privacy Policy.',
        'icon': Icons.privacy_tip,
      },
      {
        'title': '11. Modifications to Terms',
        'content': 'We reserve the right to modify these terms at any time. Changes will be effective immediately upon posting. Continued use of the service constitutes acceptance of modified terms. We will notify users of material changes through the app. It is your responsibility to review terms periodically.',
        'icon': Icons.edit,
      },
      {
        'title': '12. Termination',
        'content': 'Either party may terminate the agreement at any time. We may suspend or terminate accounts for violations of these terms. Upon termination your right to use the service ceases immediately. Sections regarding liability intellectual property and disputes survive termination. You may delete your account at any time through the app settings.',
        'icon': Icons.exit_to_app,
      },
      {
        'title': '13. Governing Law and Disputes',
        'content': 'These terms are governed by the laws of the jurisdiction where Bird operates. Any disputes will be resolved through binding arbitration. You waive the right to participate in class action lawsuits. Legal proceedings must be filed within one year of the incident. Disputes should first be addressed through our customer support.',
        'icon': Icons.gavel,
      },
      {
        'title': '14. Third-Party Services',
        'content': 'Our app may contain links to third-party websites or services. We are not responsible for third-party content or practices. Third-party terms and privacy policies apply to their services. Payment processing is handled by licensed third-party providers. Integration with maps and location services is subject to their terms.',
        'icon': Icons.link,
      },
      {
        'title': '15. Force Majeure',
        'content': 'Bird is not liable for any failure to perform due to unforeseen circumstances including but not limited to acts of God natural disasters war terrorism strikes technical failures or government regulations that prevent normal business operations.',
        'icon': Icons.nature,
      },
      {
        'title': '16. Severability',
        'content': 'If any provision of these terms is found to be unenforceable or invalid the remaining provisions will continue to be valid and enforceable. The invalid provision will be replaced with a valid provision that most closely matches the intent of the original.',
        'icon': Icons.account_balance,
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
                '17. Contact Information',
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
            'If you have any questions about these Terms & Conditions, please contact us at:',
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorManager.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: ColorManager.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Agreement Acknowledgment',
                      style: GoogleFonts.montserrat(
                        fontSize: FontSize.s16,
                        fontWeight: FontWeightManager.semiBold,
                        color: ColorManager.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'By using the Bird application, you acknowledge that you have read, understood, and agree to be bound by these Terms & Conditions.',
                  style: GoogleFonts.poppins(
                    fontSize: FontSize.s14,
                    fontWeight: FontWeightManager.regular,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
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