import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/color/colorConstant.dart';
import '../service/attribute_service.dart';
import '../models/attribute_model.dart';

class MenuItemAttributesDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(List<SelectedAttribute> selectedAttributes) onAttributesSelected;

  const MenuItemAttributesDialog({
    Key? key,
    required this.item,
    required this.onAttributesSelected,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> item,
    required Function(List<SelectedAttribute> selectedAttributes) onAttributesSelected,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuItemAttributesDialog(
        item: item,
        onAttributesSelected: onAttributesSelected,
      ),
    );
  }

  @override
  State<MenuItemAttributesDialog> createState() => _MenuItemAttributesDialogState();
}

class _MenuItemAttributesDialogState extends State<MenuItemAttributesDialog> {
  List<AttributeGroup> _attributeGroups = [];
  Map<String, dynamic> _selectedValues = {};
  bool _isLoading = true;
  String? _errorMessage;
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAttributes();
  }

  Future<void> _loadAttributes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final menuId = widget.item['id'];
      if (menuId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Item ID not found';
        });
        return;
      }

      final attributes = await AttributeService.fetchMenuItemAttributes(menuId);
      
      if (attributes.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No attributes available for this item';
        });
        return;
      }

      // Don't pre-select any values - let user choose
      setState(() {
        _attributeGroups = attributes;
        _selectedValues = {}; // Start with empty selection
        _isLoading = false;
        _totalPrice = _calculateTotalPrice();
      });

    } catch (e, stack) {
      debugPrint('MenuItemAttributesDialog: Error loading attributes: $e');
      debugPrint('Stack trace: $stack');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load attributes: '
            '${e is Exception ? e.toString() : 'Unknown error'}';
      });
    }
  }

  double _calculateTotalPrice() {
    double basePrice = 0.0;
    final priceRaw = widget.item['price'];
    if (priceRaw is num) {
      basePrice = priceRaw.toDouble();
    } else if (priceRaw is String) {
      basePrice = double.tryParse(priceRaw) ?? 0.0;
    }
    double attributesPrice = 0.0;

    for (var group in _attributeGroups) {
      final selectedValue = _selectedValues[group.attributeId];
      if (selectedValue != null) {
        if (group.type == 'checkbox' && selectedValue is List) {
          // Handle multiple selections for checkbox
          for (String valueId in selectedValue) {
            final selectedValueObj = group.values.firstWhere(
              (value) => value.valueId == valueId,
              orElse: () => AttributeValue(),
            );
            final adj = selectedValueObj.priceAdjustment ?? 0.0;
            attributesPrice += adj;
          }
        } else if (group.type == 'radio' && selectedValue is String) {
          // Handle single selection for radio
          final selectedValueObj = group.values.firstWhere(
            (value) => value.valueId == selectedValue,
            orElse: () => AttributeValue(),
          );
          final adj = selectedValueObj.priceAdjustment ?? 0.0;
          attributesPrice += adj;
        }
      }
    }

    return basePrice + attributesPrice;
  }

  List<SelectedAttribute> _getSelectedAttributes() {
    List<SelectedAttribute> selectedAttributes = [];

    for (var group in _attributeGroups) {
      final selectedValue = _selectedValues[group.attributeId];
      if (selectedValue != null) {
        if (group.type == 'checkbox' && selectedValue is List) {
          // Handle multiple selections for checkbox
          for (String valueId in selectedValue) {
            final selectedValueObj = group.values.firstWhere(
              (value) => value.valueId == valueId,
              orElse: () => AttributeValue(),
            );
            
            if (selectedValueObj.name != null && selectedValueObj.valueId != null) {
              selectedAttributes.add(SelectedAttribute(
                attributeId: group.attributeId,
                attributeName: group.name,
                valueId: selectedValueObj.valueId!,
                valueName: selectedValueObj.name!,
                priceAdjustment: selectedValueObj.priceAdjustment ?? 0.0,
              ));
            }
          }
        } else if (group.type == 'radio' && selectedValue is String) {
          // Handle single selection for radio
          final selectedValueObj = group.values.firstWhere(
            (value) => value.valueId == selectedValue,
            orElse: () => AttributeValue(),
          );
          
          if (selectedValueObj.name != null && selectedValueObj.valueId != null) {
            selectedAttributes.add(SelectedAttribute(
              attributeId: group.attributeId,
              attributeName: group.name,
              valueId: selectedValueObj.valueId!,
              valueName: selectedValueObj.name!,
              priceAdjustment: selectedValueObj.priceAdjustment ?? 0.0,
            ));
          }
        }
      }
    }

    return selectedAttributes;
  }

  bool _isValidSelection() {
    // All attributes are optional - no validation required
    return true;
  }

  String? _getValidationError() {
    // No validation errors since all attributes are optional
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(screenWidth * 0.05),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.item['imageUrl'] ?? '',
                    width: screenWidth * 0.2,
                    height: screenWidth * 0.2,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: screenWidth * 0.2,
                      height: screenWidth * 0.2,
                      color: Colors.grey[200],
                      child: Icon(Icons.restaurant, color: Colors.grey[400]),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item['name'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.01),
                      Text(
                        '${_totalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w500,
                          color: ColorManager.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: ColorManager.primary),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'Loading options...',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, 
                                 size: screenWidth * 0.15, 
                                 color: Colors.grey[400]),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.035,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            ElevatedButton(
                              onPressed: _loadAttributes,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorManager.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Retry',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        children: [
                          Text(
                            'Select Options',
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          ..._attributeGroups.map((group) => _buildAttributeGroup(group, screenWidth, screenHeight)),
                        ],
                      ),
          ),

          // Bottom Action Buttons
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
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final selectedAttributes = _getSelectedAttributes();
                      widget.onAttributesSelected(selectedAttributes);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add to Cart',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildAttributeGroup(AttributeGroup group, double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.name,
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        
        if (group.type == 'radio')
          ...group.values.map((value) => _buildRadioOption(group, value, screenWidth, screenHeight))
        else if (group.type == 'checkbox')
          ...group.values.map((value) => _buildCheckboxOption(group, value, screenWidth, screenHeight)),
        
        SizedBox(height: screenHeight * 0.02),
      ],
    );
  }

  Widget _buildRadioOption(AttributeGroup group, AttributeValue value, double screenWidth, double screenHeight) {
    if (value.name == null || value.valueId == null) return SizedBox.shrink();
    
    final isSelected = _selectedValues[group.attributeId] == value.valueId;
    final priceText = value.priceAdjustment != null && value.priceAdjustment! > 0 
        ? ' (+₹${value.priceAdjustment!.toStringAsFixed(2)})' 
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.01),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? ColorManager.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? ColorManager.primary.withOpacity(0.05) : Colors.transparent,
      ),
      child: InkWell(
        onTap: () {
          debugPrint('Custom radio button tapped for value: ${value.valueId}');
          debugPrint('Current selected value for ${group.attributeId}: ${_selectedValues[group.attributeId]}');
          debugPrint('Is this option currently selected? $isSelected');
          
          setState(() {
            if (isSelected) {
              // If already selected, deselect it
              debugPrint('Deselecting attribute ${group.attributeId}');
              _selectedValues.remove(group.attributeId);
            } else {
              // If not selected, select it
              debugPrint('Selecting attribute ${group.attributeId} with value: ${value.valueId}');
              _selectedValues[group.attributeId] = value.valueId!;
            }
            _totalPrice = _calculateTotalPrice();
            debugPrint('Updated selected values: $_selectedValues');
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.03,
            vertical: screenHeight * 0.015,
          ),
          child: Row(
            children: [
              // Custom radio button
              Container(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? ColorManager.primary : Colors.grey[400]!,
                    width: 2,
                  ),
                  color: isSelected ? ColorManager.primary : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: screenWidth * 0.03,
                        color: Colors.white,
                      )
                    : null,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  '${value.name!}$priceText',
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.035,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? ColorManager.primary : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxOption(AttributeGroup group, AttributeValue value, double screenWidth, double screenHeight) {
    if (value.name == null || value.valueId == null) return SizedBox.shrink();
    
    // Get the list of selected values for this attribute group
    List<String> selectedValues = [];
    if (_selectedValues[group.attributeId] is List) {
      selectedValues = List<String>.from(_selectedValues[group.attributeId]);
    }
    
    final isSelected = selectedValues.contains(value.valueId);
    final priceText = value.priceAdjustment != null && value.priceAdjustment! > 0 
        ? ' (+${value.priceAdjustment!.toStringAsFixed(2)})' 
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.01),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? ColorManager.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? ColorManager.primary.withOpacity(0.05) : Colors.transparent,
      ),
      child: InkWell(
        onTap: () {
          debugPrint('Custom checkbox tapped for value: ${value.valueId}');
          debugPrint('Current selected values for ${group.attributeId}: $selectedValues');
          debugPrint('Is this option currently selected? $isSelected');
          
          setState(() {
            if (isSelected) {
              // If already selected, remove it from the list
              debugPrint('Deselecting attribute ${group.attributeId} value: ${value.valueId}');
              selectedValues.remove(value.valueId);
              if (selectedValues.isEmpty) {
                _selectedValues.remove(group.attributeId);
              } else {
                _selectedValues[group.attributeId] = selectedValues;
              }
            } else {
              // If not selected, add it to the list
              debugPrint('Selecting attribute ${group.attributeId} with value: ${value.valueId}');
              selectedValues.add(value.valueId!);
              _selectedValues[group.attributeId] = selectedValues;
            }
            _totalPrice = _calculateTotalPrice();
            debugPrint('Updated selected values: $_selectedValues');
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.03,
            vertical: screenHeight * 0.015,
          ),
          child: Row(
            children: [
              // Custom checkbox
              Container(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? ColorManager.primary : Colors.grey[400]!,
                    width: 2,
                  ),
                  color: isSelected ? ColorManager.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: screenWidth * 0.03,
                        color: Colors.white,
                      )
                    : null,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  '${value.name!}$priceText',
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.035,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? ColorManager.primary : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 