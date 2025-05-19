// lib/widgets/restaurant_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/color/colorConstant.dart';

class RestaurantCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String cuisine;
  final dynamic rating;
  final String price;
  final String deliveryTime;
  final bool isVeg;
  final VoidCallback onTap;
  final bool isHorizontal;

  const RestaurantCard({
    Key? key,
    required this.name,
    required this.imageUrl,
    required this.cuisine,
    required this.rating,
    required this.price,
    required this.deliveryTime,
    this.isVeg = false,
    required this.onTap,
    this.isHorizontal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double ratingValue = _parseRating(rating);
    return isHorizontal
        ? _buildHorizontalCard(context, ratingValue)
        : _buildVerticalCard(context, ratingValue, screenWidth);
  }

  double _parseRating(dynamic rating) {
    if (rating == null) return 0.0;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) return double.tryParse(rating) ?? 0.0;
    return 0.0;
  }

  Widget _buildVerticalCard(BuildContext context, double ratingValue, double screenWidth) {
    final formattedPrice = _shortenPrice(price);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColorManager.cardGrey, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 160,
                    child: _buildImage(imageUrl),
                  ),
                ),
                if (isVeg)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _buildBadge('PURE VEG', Icons.eco_outlined),
                  ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: _buildDeliveryTime(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleRow(ratingValue),
                  const SizedBox(height: 4),
                  Text(
                    cuisine,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(Icons.currency_rupee, formattedPrice),
                      _buildInfoItem(Icons.place, "Nearby"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context, double ratingValue) {
    final formattedPrice = _shortenPrice(price);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorManager.cardGrey, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: _buildImage(imageUrl),
                  ),
                  if (isVeg)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildBadge('VEG', Icons.eco_outlined, fontSize: 9),
                    ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _buildRatingBadge(ratingValue),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cuisine,
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoItem(Icons.currency_rupee, formattedPrice, fontSize: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text("•", style: TextStyle(color: Colors.grey[500])),
                        ),
                        _buildInfoItem(Icons.access_time, deliveryTime, fontSize: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, {double fontSize = 10}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorManager.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: fontSize),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTime() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorManager.primary.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            deliveryTime,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow(double ratingValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            name,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildRatingBadge(ratingValue),
      ],
    );
  }

  Widget _buildRatingBadge(double ratingValue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ColorManager.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            ratingValue > 0 ? ratingValue.toStringAsFixed(1) : "New",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (ratingValue > 0) ...[
            const SizedBox(width: 2),
            const Icon(Icons.star, color: Colors.white, size: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, {double fontSize = 13}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: ColorManager.primary),
        const SizedBox(width: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  String _shortenPrice(String price) {
    if (price.length > 10) {
      if (price.contains("for")) {
        final parts = price.split("for");
        if (parts.isNotEmpty) return parts[0].trim();
      }
      return price.substring(0, 8) + "...";
    }
    return price;
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(isLoading: true);
        },
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder({bool isLoading = false}) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: isLoading
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(ColorManager.primary),
                strokeWidth: 2,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, size: 30, color: Colors.grey[400]),
                  const SizedBox(height: 4),
                  Text(
                    'No image',
                    style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}
