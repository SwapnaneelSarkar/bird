import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/color/colorConstant.dart';

class AttributesDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final int quantity;
  final Function(Map<String, dynamic>? attributes) onConfirm;
  final VoidCallback onDismiss;

  const AttributesDialog({
    Key? key,
    required this.item,
    required this.quantity,
    required this.onConfirm,
    required this.onDismiss,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> item,
    required int quantity,
    required Function(Map<String, dynamic>? attributes) onConfirm,
    required VoidCallback onDismiss,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AttributesDialog(
        item: item,
        quantity: quantity,
        onConfirm: onConfirm,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<AttributesDialog> createState() => _AttributesDialogState();
}

class _AttributesDialogState extends State<AttributesDialog> {
  Map<String, dynamic> selectedAttributes = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final attributes = widget.item['attributes'] as Map<String, dynamic>?;

    if (attributes == null || attributes.isEmpty) {
      return Container();
    }

    return Container(
      height: screenHeight * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(screenWidth * 0.05),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item['name'] ?? 'Item',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        '${widget.item['price']?.toString() ?? '0'}',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w500,
                          color: ColorManager.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onDismiss,
                  icon: const Icon(Icons.close),
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),

          // Attributes List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(screenWidth * 0.05),
              itemCount: attributes.length,
              itemBuilder: (context, index) {
                final attributeKey = attributes.keys.elementAt(index);
                final attribute = attributes[attributeKey];
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attributeKey,
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    if (attribute is List)
                      Wrap(
                        spacing: screenWidth * 0.02,
                        runSpacing: screenHeight * 0.01,
                        children: attribute.map((option) {
                          final isSelected = selectedAttributes[attributeKey] == option;
                          return ChoiceChip(
                            label: Text(
                              option.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.035,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedAttributes[attributeKey] = option;
                                } else {
                                  selectedAttributes.remove(attributeKey);
                                }
                              });
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: ColorManager.primary,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03,
                              vertical: screenHeight * 0.01,
                            ),
                          );
                        }).toList(),
                      )
                    else if (attribute is Map)
                      Column(
                        children: attribute.entries.map((entry) {
                          final isSelected = selectedAttributes[attributeKey] == entry.key;
                          return ListTile(
                            title: Text(
                              entry.key.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.035,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              '+${entry.value.toString()}',
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.03,
                                color: ColorManager.primary,
                              ),
                            ),
                            trailing: Radio<String>(
                              value: entry.key.toString(),
                              groupValue: selectedAttributes[attributeKey]?.toString(),
                              onChanged: (value) {
                                setState(() {
                                  selectedAttributes[attributeKey] = value;
                                });
                              },
                              activeColor: ColorManager.primary,
                            ),
                          );
                        }).toList(),
                      ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                );
              },
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.all(screenWidth * 0.05),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Quantity',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        widget.quantity.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    setState(() => _isLoading = true);
                    widget.onConfirm(selectedAttributes);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.015,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                    ? SizedBox(
                        width: screenWidth * 0.05,
                        height: screenWidth * 0.05,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Add to Cart',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 