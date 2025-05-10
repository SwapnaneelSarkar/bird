import 'package:flutter/material.dart';
import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';

class FoodItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int quantity;
  final Function(int) onQuantityChanged;

  const FoodItemCard({
    Key? key,
    required this.item,
    this.quantity = 0,
    required this.onQuantityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isVeg = item['isVeg'] == true;
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildFoodImage(),
          ),
          SizedBox(width: 16),
          
          // Food Details
          Expanded(
            child: _buildFoodDetails(),
          ),
          
          // Column with dot and counter/add button
          Column(
            children: [
              // Veg/Non-veg indicator dot
              Container(
                width: 12,
                height: 12,
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isVeg ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              // Counter or Add button
              quantity > 0 ? _buildQuantityCounter() : _buildAddButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodImage() {
    final String? imageUrl = item['imageUrl'];
    
    return Image.network(
      imageUrl ?? 'https://via.placeholder.com/80x80?text=Food',
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 80,
          height: 80,
          color: Colors.grey[300],
          child: Center(child: Icon(Icons.restaurant, color: Colors.grey[500])),
        );
      },
    );
  }

  Widget _buildFoodDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['name'] ?? 'Food Item',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6),
        
        // Description
        Text(
          item['description'] ?? 'No description available',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8),
        
        // Price
        Text(
          '₹${item['price']?.toString() ?? '0'}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
  
  // Add button when quantity is 0
  Widget _buildAddButton() {
    return ElevatedButton(
      onPressed: () => onQuantityChanged(1),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        elevation: 0,
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      child: Text(
        'ADD',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
  
  // Quantity counter when quantity > 0
  Widget _buildQuantityCounter() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(20), // Pill shape
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus button
          InkWell(
            onTap: () {
              final newQuantity = quantity - 1;
              onQuantityChanged(newQuantity < 0 ? 0 : newQuantity);
            },
            child: Container(
              width: 32,
              height: 32,
              child: Center(
                child: Text(
                  "-",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
          
          // Quantity
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              quantity.toString(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          
          // Plus button
          InkWell(
            onTap: () => onQuantityChanged(quantity + 1),
            child: Container(
              width: 32,
              height: 32,
              child: Center(
                child: Text(
                  "+",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.pink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}