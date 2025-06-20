// lib/widgets/review_rating_widget.dart
import 'package:bird/service/review_service.dart';
import 'package:flutter/material.dart';
import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';
class ReviewRatingWidget extends StatefulWidget {
  final String orderId;
  final String partnerId;
  final bool canReview;

  const ReviewRatingWidget({
    Key? key,
    required this.orderId,
    required this.partnerId,
    required this.canReview,
  }) : super(key: key);

  @override
  State<ReviewRatingWidget> createState() => _ReviewRatingWidgetState();
}

class _ReviewRatingWidgetState extends State<ReviewRatingWidget> {
  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate & Review',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeightManager.bold,
              fontFamily: FontFamily.Montserrat,
              color: ColorManager.black,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          
          if (widget.canReview) ...[
            // Rating Section
            Text(
              'How was your experience?',
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                fontFamily: FontFamily.Montserrat,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            
            // Star Rating
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = index + 1;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: screenWidth * 0.02),
                    child: Icon(
                      _selectedRating > index ? Icons.star : Icons.star_border,
                      size: screenWidth * 0.08,
                      color: _selectedRating > index ? Colors.amber : Colors.grey[400],
                    ),
                  ),
                );
              }),
            ),
            
            SizedBox(height: screenHeight * 0.015),
            
            // Review Text Field
            TextField(
              controller: _reviewController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Share your experience... (optional)',
                hintStyle: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontFamily: FontFamily.Montserrat,
                  color: Colors.grey[500],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  borderSide: BorderSide(color: ColorManager.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: EdgeInsets.all(screenWidth * 0.03),
              ),
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontFamily: FontFamily.Montserrat,
                color: ColorManager.black,
              ),
            ),
            
            SizedBox(height: screenHeight * 0.015),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: screenHeight * 0.055,
              child: ElevatedButton(
                onPressed: (_selectedRating > 0 && !_isSubmitting) ? _submitReview : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.black,
                  disabledBackgroundColor: Colors.grey[300],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: screenWidth * 0.05,
                        height: screenWidth * 0.05,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeightManager.medium,
                          fontFamily: FontFamily.Montserrat,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ] else ...[
            // Already reviewed or cannot review
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: screenWidth * 0.05,
                  color: Colors.grey[600],
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    'Reviews can only be submitted for delivered orders.',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontFamily: FontFamily.Montserrat,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await ReviewService.submitReview(
        orderId: widget.orderId,
        rating: _selectedRating,
        reviewText: _reviewController.text.trim(),
        partnerId: widget.partnerId.isNotEmpty ? widget.partnerId : null, // Only pass if not empty
      );

      if (mounted) {
        if (response.status == 'SUCCESS') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Reset form
          setState(() {
            _selectedRating = 0;
            _reviewController.clear();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while submitting review'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}