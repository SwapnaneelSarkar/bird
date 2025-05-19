// widgets/food_item_card.dart
import 'package:flutter/material.dart';
import '../constants/color/colorConstant.dart';
import 'cached_image.dart';

class FoodItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int quantity;
  final Function(int) onQuantityChanged;

  const FoodItemCard({
    Key? key,
    required this.item,
    required this.quantity,
    required this.onQuantityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isVeg = item['isVeg'] ?? false;
    String? imageUrl = item['imageUrl'];
    String name = item['name'] ?? '';
    num price = item['price'] ?? 0;
    String description = item['description'] ?? '';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food details section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Veg/Non-veg indicator
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isVeg ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isVeg ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Food name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Price
                  Text(
                    '₹${price.toString()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ColorManager.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Description
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
          
          // Image and add button section
          Column(
            children: [
              // Food image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                ),
                child: SizedBox(
                  width: 120,
                  height: 100,
                  child: CachedImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: 120,
                    height: 100,
                    placeholder: (context) => Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, error) => Container(
                      color: Colors.grey[100],
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.grey[400],
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Add to cart button or quantity selector
              Container(
                width: 120,
                padding: const EdgeInsets.all(8),
                child: quantity > 0
                    ? _buildQuantitySelector()
                    : _buildAddButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddButton() {
    return ElevatedButton(
      onPressed: () => onQuantityChanged(1),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorManager.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 4),
        minimumSize: const Size(double.infinity, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text('ADD', style: TextStyle(fontSize: 12)),
    );
  }
  
  Widget _buildQuantitySelector() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: ColorManager.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => onQuantityChanged(quantity - 1),
            child: Container(
              width: 28,
              height: 32,
              alignment: Alignment.center,
              child: const Icon(Icons.remove, color: Colors.white, size: 16),
            ),
          ),
          Text(
            quantity.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          InkWell(
            onTap: () => onQuantityChanged(quantity + 1),
            child: Container(
              width: 28,
              height: 32,
              alignment: Alignment.center,
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}