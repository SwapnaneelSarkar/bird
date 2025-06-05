import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/color/colorConstant.dart';

class CartConflictDialog extends StatelessWidget {
  final String currentRestaurant;
  final String newRestaurant;
  final VoidCallback onKeepCurrent;
  final VoidCallback onReplaceWithNew;

  const CartConflictDialog({
    Key? key,
    required this.currentRestaurant,
    required this.newRestaurant,
    required this.onKeepCurrent,
    required this.onReplaceWithNew,
  }) : super(key: key);

  static Future<bool?> show({
    required BuildContext context,
    required String currentRestaurant,
    required String newRestaurant,
  }) async {
    debugPrint('CartConflictDialog: Showing dialog');
    debugPrint('CartConflictDialog: Current restaurant: $currentRestaurant');
    debugPrint('CartConflictDialog: New restaurant: $newRestaurant');
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CartConflictDialog(
        currentRestaurant: currentRestaurant,
        newRestaurant: newRestaurant,
        onKeepCurrent: () {
          debugPrint('CartConflictDialog: User chose to keep current cart');
          Navigator.of(context).pop(false);
        },
        onReplaceWithNew: () {
          debugPrint('CartConflictDialog: User chose to replace cart');
          Navigator.of(context).pop(true);
        },
      ),
    );
    
    debugPrint('CartConflictDialog: Dialog closed with result: $result');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.06),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: screenWidth * 0.16,
              height: screenWidth * 0.16,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                color: ColorManager.primary,
                size: screenWidth * 0.08,
              ),
            ),
            
            SizedBox(height: screenHeight * 0.025),
            
            // Title
            Text(
              'Replace Cart Items?',
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: screenHeight * 0.015),
            
            // Description
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.035,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Your cart contains items from '),
                  TextSpan(
                    text: currentRestaurant,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: ColorManager.primary,
                    ),
                  ),
                  const TextSpan(text: '. Adding items from '),
                  TextSpan(
                    text: newRestaurant,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: ColorManager.primary,
                    ),
                  ),
                  const TextSpan(text: ' will replace your current cart items.'),
                ],
              ),
            ),
            
            SizedBox(height: screenHeight * 0.03),
            
            // Action Buttons
            Row(
              children: [
                // Keep Current Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: onKeepCurrent,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                      side: BorderSide(color: Colors.grey[300]!, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Keep Current',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: screenWidth * 0.04),
                
                // Replace Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReplaceWithNew,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Replace Cart',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}