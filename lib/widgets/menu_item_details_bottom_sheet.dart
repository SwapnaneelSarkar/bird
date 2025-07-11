import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../constants/color/colorConstant.dart';
import '../constants/api_constant.dart';
import '../service/token_service.dart';
import 'cached_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/restaurant_menu/bloc.dart';
import '../presentation/restaurant_menu/state.dart';
import '../presentation/restaurant_menu/event.dart';
import '../service/attribute_service.dart';
import 'menu_item_attributes_dialog.dart';
import '../models/attribute_model.dart';
import '../widgets/item_added_popup.dart';

class MenuItemDetailsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onClose;

  const MenuItemDetailsBottomSheet({
    Key? key,
    required this.item,
    this.onClose,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> item,
    VoidCallback? onClose,
  }) async {
    final bloc = BlocProvider.of<RestaurantDetailsBloc>(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: bloc,
        child: MenuItemDetailsBottomSheet(
          item: item,
          onClose: onClose,
        ),
      ),
    );
  }

  @override
  State<MenuItemDetailsBottomSheet> createState() => _MenuItemDetailsBottomSheetState();
}

class _MenuItemDetailsBottomSheetState extends State<MenuItemDetailsBottomSheet> {
  bool _isLoading = true;
  Map<String, dynamic>? _itemDetails;
  String? _errorMessage;

  int _previousQuantity = 0;
  List<SelectedAttribute>? _selectedAttributes;

  @override
  void initState() {
    super.initState();
    _loadItemDetails();
  }

  Future<void> _loadItemDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final token = await TokenService.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please login to view item details';
        });
        return;
      }

      final menuId = widget.item['id'];
      if (menuId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Item ID not found';
        });
        return;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/menu_item/$menuId');
      
      debugPrint('MenuItemDetailsBottomSheet: Fetching details from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('MenuItemDetailsBottomSheet: API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          setState(() {
            _itemDetails = responseData['data'] as Map<String, dynamic>;
            _isLoading = false;
          });
          debugPrint('MenuItemDetailsBottomSheet: Item details loaded successfully');
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = responseData['message'] ?? 'Failed to load item details';
          });
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Your session has expired. Please login again.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Server error. Please try again later.';
        });
      }
    } catch (e) {
      debugPrint('MenuItemDetailsBottomSheet: Error loading item details: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error. Please check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 16, bottom: 8),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: ColorManager.cardGrey,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          
          // Header with close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item Details',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.black,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onClose?.call();
                  },
                  icon: Icon(
                    Icons.close,
                    size: 24,
                    color: ColorManager.black,
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
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading item details...',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: ColorManager.black.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : _buildContentWidget(screenWidth),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColorManager.signUpRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: ColorManager.signUpRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ColorManager.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: ColorManager.black.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadItemDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentWidget(double screenWidth) {
    // Use the original item data for image and basic info, API data for additional details
    final originalItem = widget.item;
    final apiItem = _itemDetails;
    
    // Combine data: use original item for image and basic info, API data for additional details
    final item = {
      ...originalItem, // Start with original item data (includes image)
      ...?apiItem, // Override with API data if available
    };
    // Ensure correct fields for cart logic
    item['id'] = item['id'] ?? item['menu_id'] ?? '';
    item['name'] = item['name'] ?? '';
    // Parse price as double
    if (item['price'] is String) {
      item['price'] = double.tryParse(item['price']) ?? 0.0;
    } else if (item['price'] is! double) {
      item['price'] = (item['price'] as num?)?.toDouble() ?? 0.0;
    }
    item['imageUrl'] = item['imageUrl'] ?? item['image_url'] ?? '';
    
    final isVeg = item['isVeg'] ?? false;
    final imageUrl = item['imageUrl'] ?? item['image_url'];
    final name = item['name'] ?? '';
    final price = item['price'] ?? 0;
    final description = item['description'] ?? '';
    final isAvailable = item['available'] ?? true;
    final isTaxIncluded = item['isTaxIncluded'] ?? false;
    final isCancellable = item['isCancellable'] ?? false;
    
    // Parse categories from different possible formats
    List<String> parsedCategories = [];
    try {
      final categoryData = item['category'];
      if (categoryData != null) {
        if (categoryData is List) {
          // If it's already a List, convert each item to String
          parsedCategories = List<String>.from(categoryData.map((e) => e.toString()));
        } else if (categoryData is String) {
          // If it's a String, try to parse as JSON array first, then as comma-separated
          String categoryStr = categoryData.toString().trim();
          if (categoryStr.startsWith('[') && categoryStr.endsWith(']')) {
            try {
              // Try to parse as JSON array
              final parsed = jsonDecode(categoryStr);
              if (parsed is List) {
                parsedCategories = parsed.map((e) => e.toString()).toList();
              }
            } catch (e) {
              // If JSON parsing fails, fall back to string splitting
              categoryStr = categoryStr.substring(1, categoryStr.length - 1);
              parsedCategories = categoryStr.split(',').map((cat) => cat.trim().replaceAll('"', '')).where((cat) => cat.isNotEmpty).toList();
            }
          } else {
            // Single category as string
            parsedCategories = [categoryStr];
          }
        }
      }
    } catch (e) {
      debugPrint('MenuItemDetailsBottomSheet: Error parsing categories: $e');
      parsedCategories = [];
    }
    
    // Join categories for display
    final categoryString = parsedCategories.join(', ');
    
    // Parse tags properly - handle both string and list formats
    List<String> tags = [];
    try {
      final tagsData = item['tags'];
      if (tagsData != null) {
        if (tagsData is String) {
          // Try to parse JSON string
          try {
            final parsed = jsonDecode(tagsData);
            if (parsed is List) {
              tags = parsed.map((tag) => tag.toString()).toList();
            } else if (parsed is Map) {
              tags = parsed.values.map((tag) => tag.toString()).toList();
            } else {
              tags = [parsed.toString()];
            }
          } catch (e) {
            // If JSON parsing fails, treat as single tag
            tags = [tagsData];
          }
        } else if (tagsData is List) {
          tags = tagsData.map((tag) => tag.toString()).toList();
        } else {
          tags = [tagsData.toString()];
        }
      }
    } catch (e) {
      debugPrint('MenuItemDetailsBottomSheet: Error parsing tags: $e');
      tags = [];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with enhanced styling
          if (imageUrl != null)
            Container(
              width: double.infinity,
              height: screenWidth * 0.7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: ColorManager.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ColorManager.cardGrey.withOpacity(0.3),
                          ColorManager.cardGrey.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Loading image...',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: ColorManager.black.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  errorWidget: (context, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ColorManager.cardGrey.withOpacity(0.3),
                          ColorManager.cardGrey.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant,
                          color: ColorManager.black.withOpacity(0.4),
                          size: 60,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: ColorManager.black.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Name and veg indicator with enhanced styling
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced veg indicator
              Container(
                margin: const EdgeInsets.only(top: 6, right: 16),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isVeg ? const Color(0xFF3CB043) : const Color(0xFFE53935),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: isVeg 
                          ? const Color(0xFF3CB043).withOpacity(0.4) 
                          : const Color(0xFFE53935).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  isVeg ? Icons.eco : Icons.restaurant,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              
              // Name with enhanced styling
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.black,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Category badge with enhanced styling
          if (categoryString.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorManager.yellowAcc.withOpacity(0.2),
                    ColorManager.yellowAcc.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: ColorManager.yellowAcc.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                categoryString,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: ColorManager.yellowAcc,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Price section with reduced size
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorManager.primary.withOpacity(0.1),
                  ColorManager.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ColorManager.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  '₹${price.toString()}',
                  style: GoogleFonts.poppins(
                    fontSize: 24, // Reduced from 32 to 24
                    fontWeight: FontWeight.bold,
                    color: ColorManager.primary,
                  ),
                ),
                if (isTaxIncluded) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3CB043).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF3CB043).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: const Color(0xFF3CB043),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tax Included',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF3CB043),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Description section with enhanced styling
          if (description.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorManager.otpField,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: ColorManager.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Description',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: ColorManager.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: ColorManager.black.withOpacity(0.8),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Availability status with enhanced styling
          if (!isAvailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorManager.signUpRed.withOpacity(0.1),
                    ColorManager.signUpRed.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ColorManager.signUpRed.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorManager.signUpRed.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: ColorManager.signUpRed,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This item is currently not available',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: ColorManager.signUpRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Add-to-cart section (always show, but disable if not available)
          BlocListener<RestaurantDetailsBloc, RestaurantDetailsState>(
            listenWhen: (previous, current) {
              if (current is RestaurantDetailsLoaded) {
                final itemId = item['id'];
                final prevQ = _previousQuantity;
                final newQ = current.cartQuantities[itemId] ?? 0;
                // Only listen if quantity changes
                return prevQ != newQ;
              }
              return false;
            },
            listener: (context, state) {
              if (state is RestaurantDetailsLoaded) {
                final itemId = item['id'];
                final prevQ = _previousQuantity;
                final newQ = state.cartQuantities[itemId] ?? 0;
                if (prevQ == 0 && newQ == 1) {
                  ItemAddedPopup.show(
                    context: context,
                    item: item,
                    onViewCart: () {
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.pushReplacementNamed(context, '/orderConfirmation');
                    },
                    onContinueShopping: () {},
                  );
                }
                _previousQuantity = newQ;
              }
            },
            child: BlocBuilder<RestaurantDetailsBloc, RestaurantDetailsState>(
              builder: (context, state) {
                int quantity = 0;
                if (state is RestaurantDetailsLoaded) {
                  quantity = state.cartQuantities[item['id']] ?? 0;
                }
                final isDisabled = !isAvailable;
                final screenWidth = MediaQuery.of(context).size.width;
                return Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                  child: Center(
                    child: isDisabled
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Not Available',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : quantity == 0
                            ? GestureDetector(
                                onTap: () async {
                                  final menuId = item['id'];
                                  final attributes = await AttributeService.fetchMenuItemAttributes(menuId);
                                  if (attributes.isNotEmpty) {
                                    MenuItemAttributesDialog.show(
                                      context: context,
                                      item: item,
                                      onAttributesSelected: (selectedAttributes) {
                                        setState(() {
                                          _selectedAttributes = selectedAttributes;
                                        });
                                        context.read<RestaurantDetailsBloc>().add(
                                          AddItemToCart(item: item, quantity: 1, attributes: selectedAttributes),
                                        );
                                      },
                                    );
                                  } else {
                                    setState(() {
                                      _selectedAttributes = null;
                                    });
                                    context.read<RestaurantDetailsBloc>().add(
                                      AddItemToCart(item: item, quantity: 1),
                                    );
                                  }
                                },
                                child: Container(
                                  height: 48,
                                  width: screenWidth * 0.5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        ColorManager.primary,
                                        ColorManager.primary.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ColorManager.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Add',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.add_shopping_cart_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Minus button
                                    InkWell(
                                      onTap: () {
                                        if (quantity > 0) {
                                          // If removing to 0, clear stored attributes
                                          if (quantity - 1 == 0) {
                                            setState(() {
                                              _selectedAttributes = null;
                                            });
                                          }
                                          context.read<RestaurantDetailsBloc>().add(
                                            AddItemToCart(item: item, quantity: quantity - 1, attributes: _selectedAttributes),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(50),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '-',
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Quantity text
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        quantity.toString(),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    // Plus button
                                    InkWell(
                                      onTap: () async {
                                        final menuId = item['id'];
                                        if (quantity == 0) {
                                          final attributes = await AttributeService.fetchMenuItemAttributes(menuId);
                                          if (attributes.isNotEmpty) {
                                            MenuItemAttributesDialog.show(
                                              context: context,
                                              item: item,
                                              onAttributesSelected: (selectedAttributes) {
                                                setState(() {
                                                  _selectedAttributes = selectedAttributes;
                                                });
                                                context.read<RestaurantDetailsBloc>().add(
                                                  AddItemToCart(item: item, quantity: quantity + 1, attributes: selectedAttributes),
                                                );
                                              },
                                            );
                                            return;
                                          } else {
                                            setState(() {
                                              _selectedAttributes = null;
                                            });
                                          }
                                        } else {
                                          // Use stored attributes for subsequent additions
                                          context.read<RestaurantDetailsBloc>().add(
                                            AddItemToCart(item: item, quantity: quantity + 1, attributes: _selectedAttributes),
                                          );
                                          return;
                                        }
                                        context.read<RestaurantDetailsBloc>().add(
                                          AddItemToCart(item: item, quantity: quantity + 1),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(50),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '+',
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            color: ColorManager.primary,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
} 