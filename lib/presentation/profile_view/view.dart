import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/profile_tile.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

const List<BoxShadow> softBoxShadow = [
  BoxShadow(
    color: Color(0x0D000000), // black with 5% opacity
    blurRadius: 4,
    spreadRadius: 0.5,
    offset: Offset(0, 2),
  ),
];

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return BlocProvider(
      create: (_) => ProfileBloc(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          title: const Text('Profile', style: TextStyle(color: Colors.black)),
          leading: const BackButton(color: Colors.black),
        ),
        body: BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileLoggedOut) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Profile Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: softBoxShadow,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: w * 0.11,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=68',
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Michael Anderson',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'michael.anderson@email.com',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Orders Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: softBoxShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Your Orders',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                color: Color(0xFFE67E22),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        ],
                      ),
                      const _OrderTile(
                        image: 'assets/images/burger.jpg',
                        title: 'Burger Combo',
                        date: 'Apr 25, 2025',
                        price: '\$24.99',
                      ),
                      const _OrderTile(
                        image: 'assets/images/pizza.jpg',
                        title: 'Margherita Pizza',
                        date: 'Apr 24, 2025',
                        price: '\$18.99',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Info Cards
                ProfileCardTile(
                  leadingIcon: const Icon(Icons.description, size: 20, color: Color(0xFFE67E22)),
                  title: 'Terms & Conditions',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                ProfileCardTile(
                  leadingIcon: const Icon(Icons.privacy_tip, size: 20, color: Color(0xFFE67E22)),
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                ProfileCardTile(
                  leadingIcon: const Icon(Icons.share, size: 20, color: Color(0xFFE67E22)),
                  title: 'Share App',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                ProfileCardTile(
                  leadingIcon: const Icon(Icons.settings, size: 20, color: Color(0xFFE67E22)),
                  title: 'Settings',
                  onTap: () {},
                ),

                const SizedBox(height: 24),

                // Logout Button
                _LogoutButton(
                  onPressed: () {
                    context.read<ProfileBloc>().add(LogoutRequested());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final String image;
  final String title;
  final String date;
  final String price;

  const _OrderTile({
    required this.image,
    required this.title,
    required this.date,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(image, width: 48, height: 48, fit: BoxFit.cover),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('Delivered • $date'),
      trailing: Text(
        price,
        style: const TextStyle(
          color: Color(0xFFE67E22),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LogoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: softBoxShadow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFEAEA),
                      ),
                      child: const Icon(Icons.logout, color: Colors.red, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          width: 60,
          decoration: BoxDecoration(
            color: Color(0xFF554CF3),
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ],
    );
  }
}
