// lib/presentation/address bottomSheet/view.dart - Updated with real-time address updates
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import 'package:lottie/lottie.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class AddressPickerBottomSheet extends StatefulWidget {
  final Function(String address, String subAddress, double latitude, double longitude)? onAddressSelected;
  final List<Map<String, dynamic>>? savedAddresses;

  const AddressPickerBottomSheet({
    Key? key,
    this.onAddressSelected,
    this.savedAddresses,
  }) : super(key: key);

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    List<Map<String, dynamic>>? savedAddresses,
  }) async {
    Map<String, dynamic>? result;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressPickerBottomSheet(
        savedAddresses: savedAddresses,
        onAddressSelected: (address, subAddress, latitude, longitude) {
          result = {
            'address': address,
            'subAddress': subAddress,
            'latitude': latitude,
            'longitude': longitude,
          };
          Navigator.of(context).pop();
        },
      ),
    );
    
    return result;
  }

  @override
  State<AddressPickerBottomSheet> createState() => _AddressPickerBottomSheetState();
}

class _AddressPickerBottomSheetState extends State<AddressPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSavedAddresses = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.savedAddresses == null || widget.savedAddresses!.isEmpty) {
        _searchFocusNode.requestFocus();
        _showSavedAddresses = false;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final sheetHeight = size.height * 0.8 + bottomPadding;
    final textScale = size.width / 375;

    return BlocProvider(
      create: (context) => AddressPickerBloc()..add(InitializeAddressPickerEvent()),
      child: BlocConsumer<AddressPickerBloc, AddressPickerState>(
        listener: (context, state) {
          if (state is AddressNameInputRequired) {
            _showAddressNameDialog(
              context, 
              state.address, 
              state.subAddress, 
              state.latitude, 
              state.longitude,
              state.fullAddress,
            );
          }
          
          if (state is SavedAddressSelected) {
            if (widget.onAddressSelected != null) {
              widget.onAddressSelected!(
                state.savedAddress.addressLine1,
                state.savedAddress.displayName,
                state.savedAddress.latitude,
                state.savedAddress.longitude,
              );
            }
          }
          
          if (state is AddressSavedSuccessfully) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Address saved successfully'),
                backgroundColor: Colors.green,
              ),
            );
            
            // CRITICAL: Immediately call the callback to update home page
            if (widget.onAddressSelected != null) {
              widget.onAddressSelected!(
                state.address,
                state.addressName,
                state.latitude,
                state.longitude,
              );
            }
          }
          
          if (state is AddressPickerLoadFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          }
          
          if (state is AddressPickerClosed) {
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          return Container(
            height: sheetHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20 * textScale),
                topRight: Radius.circular(20 * textScale),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Padding(
                  padding: EdgeInsets.only(top: 8.0 * textScale),
                  child: Container(
                    width: 40 * textScale,
                    height: 4 * textScale,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2 * textScale),
                    ),
                  ),
                ),
                
                // Header
                _buildHeader(textScale),
                
                // Content
                Expanded(
                  child: _showSavedAddresses && (widget.savedAddresses?.isNotEmpty ?? false)
                      ? _buildSavedAddressesList(textScale)
                      : _buildSearchContent(context, state, textScale),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(double textScale) {
    return Padding(
      padding: EdgeInsets.all(20 * textScale),
      child: Row(
        children: [
          Text(
            'Select Address',
            style: TextStyle(
              fontSize: FontSize.s18 * textScale,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          const Spacer(),
          if (!_showSavedAddresses && (widget.savedAddresses?.isNotEmpty ?? false))
            TextButton(
              onPressed: () {
                setState(() {
                  _showSavedAddresses = true;
                });
              },
              child: Text(
                'Saved',
                style: TextStyle(
                  color: ColorManager.primary,
                  fontSize: FontSize.s14 * textScale,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSavedAddressesList(double textScale) {
    return Column(
      children: [
        // Search new address button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * textScale, vertical: 8 * textScale),
          child: InkWell(
            onTap: () {
              setState(() {
                _showSavedAddresses = false;
              });
              _searchFocusNode.requestFocus();
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16 * textScale),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12 * textScale),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[600], size: 20 * textScale),
                  SizedBox(width: 12 * textScale),
                  Text(
                    'Search for a new address',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: FontSize.s14 * textScale,
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Saved addresses list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 20 * textScale),
            itemCount: widget.savedAddresses!.length,
            itemBuilder: (context, index) {
              final address = widget.savedAddresses![index];
              return _buildSavedAddressItem(address, textScale);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSavedAddressItem(Map<String, dynamic> address, double textScale) {
    final addressName = address['address_line2'] ?? 'Other';
    final addressLine = address['address_line1'] ?? '';
    final city = address['city'] ?? '';
    final state = address['state'] ?? '';
    final isDefault = address['is_default'] == 1;
    
    IconData iconData;
    Color iconColor;
    
    switch (addressName.toLowerCase()) {
      case 'home':
        iconData = Icons.home;
        iconColor = Colors.green;
        break;
      case 'office':
      case 'work':
        iconData = Icons.work;
        iconColor = Colors.blue;
        break;
      case 'friend':
      case 'friends':
      case "friend's home":
        iconData = Icons.people;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.location_on;
        iconColor = Colors.grey[600]!;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8 * textScale),
      child: InkWell(
        onTap: () {
          final latitude = double.tryParse(address['latitude']?.toString() ?? '') ?? 0.0;
          final longitude = double.tryParse(address['longitude']?.toString() ?? '') ?? 0.0;
          
          if (widget.onAddressSelected != null) {
            widget.onAddressSelected!(addressLine, addressName, latitude, longitude);
          }
        },
        borderRadius: BorderRadius.circular(12 * textScale),
        child: Container(
          padding: EdgeInsets.all(16 * textScale),
          decoration: BoxDecoration(
            color: isDefault ? ColorManager.primary.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12 * textScale),
            border: Border.all(
              color: isDefault ? ColorManager.primary : Colors.grey[300]!,
              width: isDefault ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8 * textScale),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8 * textScale),
                ),
                child: Icon(iconData, color: iconColor, size: 20 * textScale),
              ),
              SizedBox(width: 12 * textScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          addressName,
                          style: TextStyle(
                            fontSize: FontSize.s16 * textScale,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            fontFamily: FontFamily.Montserrat,
                          ),
                        ),
                        if (isDefault) ...[
                          SizedBox(width: 8 * textScale),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6 * textScale,
                              vertical: 2 * textScale,
                            ),
                            decoration: BoxDecoration(
                              color: ColorManager.primary,
                              borderRadius: BorderRadius.circular(4 * textScale),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: TextStyle(
                                fontSize: 10 * textScale,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4 * textScale),
                    Text(
                      '$addressLine, $city, $state',
                      style: TextStyle(
                        fontSize: FontSize.s14 * textScale,
                        color: Colors.grey[600],
                        fontFamily: FontFamily.Montserrat,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16 * textScale,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchContent(BuildContext context, AddressPickerState state, double textScale) {
    return Column(
      children: [
        // Search bar
        _buildSearchBar(context, textScale),
        
        // Current location button
        _buildCurrentLocationButton(context, textScale),
        
        SizedBox(height: 16 * textScale),
        
        // Results
        Expanded(child: _buildResultsContent(context, state, textScale)),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, double textScale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * textScale, vertical: 8 * textScale),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12 * textScale),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            SizedBox(width: 12 * textScale),
            Icon(Icons.search, color: Colors.grey[600], size: 20 * textScale),
            SizedBox(width: 12 * textScale),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Enter your address *',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: FontSize.s14 * textScale,
                    fontFamily: FontFamily.Montserrat,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16 * textScale),
                ),
                onChanged: (query) {
                  context.read<AddressPickerBloc>().add(SearchAddressEvent(query: query));
                },
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, size: 20 * textScale),
                onPressed: () {
                  _searchController.clear();
                  context.read<AddressPickerBloc>().add(ClearSearchEvent());
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationButton(BuildContext context, double textScale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * textScale),
      child: InkWell(
        onTap: () {
          context.read<AddressPickerBloc>().add(UseCurrentLocationEvent());
        },
        borderRadius: BorderRadius.circular(12 * textScale),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16 * textScale),
          decoration: BoxDecoration(
            color: ColorManager.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12 * textScale),
            border: Border.all(color: ColorManager.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.my_location, color: ColorManager.primary, size: 20 * textScale),
              SizedBox(width: 12 * textScale),
              Text(
                'Use current location',
                style: TextStyle(
                  color: ColorManager.primary,
                  fontSize: FontSize.s14 * textScale,
                  fontWeight: FontWeight.w500,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsContent(BuildContext context, AddressPickerState state, double textScale) {
    if (state is LocationDetecting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60 * textScale,
              height: 60 * textScale,
              child: Lottie.asset('assets/lottie/loading.json', fit: BoxFit.contain),
            ),
            SizedBox(height: 16 * textScale),
            Text(
              'Getting your location...',
              style: TextStyle(
                fontSize: FontSize.s14 * textScale,
                color: Colors.grey[600],
                fontFamily: FontFamily.Montserrat,
              ),
            ),
          ],
        ),
      );
    }

    if (state is AddressPickerLoadSuccess) {
      if (state.suggestions.isEmpty && state.searchQuery.isNotEmpty) {
        return _buildEmptyState(textScale);
      }

      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20 * textScale),
        itemCount: state.suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = state.suggestions[index];
          return _buildSuggestionItem(context, suggestion, textScale);
        },
      );
    }

    return _buildDefaultState(textScale);
  }

  Widget _buildSuggestionItem(BuildContext context, AddressSuggestion suggestion, double textScale) {
    return InkWell(
      onTap: () {
        context.read<AddressPickerBloc>().add(
          SelectAddressEvent(
            address: suggestion.mainText,
            subAddress: suggestion.secondaryText,
            latitude: suggestion.latitude,
            longitude: suggestion.longitude,
            fullAddress: '${suggestion.mainText}, ${suggestion.secondaryText}',
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16 * textScale, horizontal: 12 * textScale),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.grey[600], size: 20 * textScale),
            SizedBox(width: 12 * textScale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.mainText,
                    style: TextStyle(
                      fontSize: FontSize.s14 * textScale,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                  if (suggestion.secondaryText.isNotEmpty) ...[
                    SizedBox(height: 2 * textScale),
                    Text(
                      suggestion.secondaryText,
                      style: TextStyle(
                        fontSize: FontSize.s12 * textScale,
                        color: Colors.grey[600],
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double textScale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 40 * textScale, color: Colors.grey[400]),
          SizedBox(height: 16 * textScale),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: FontSize.s14 * textScale,
              color: Colors.grey[600],
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          Text(
            'Try searching with a different keyword',
            style: TextStyle(
              fontSize: FontSize.s12 * textScale,
              color: Colors.grey[500],
              fontFamily: FontFamily.Montserrat,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultState(double textScale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_searching, size: 40 * textScale, color: Colors.grey[400]),
          SizedBox(height: 16 * textScale),
          Text(
            'Search for your address',
            style: TextStyle(
              fontSize: FontSize.s14 * textScale,
              color: Colors.grey[600],
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          Text(
            'Type in the search box above',
            style: TextStyle(
              fontSize: FontSize.s12 * textScale,
              color: Colors.grey[500],
              fontFamily: FontFamily.Montserrat,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressNameDialog(
    BuildContext context,
    String address,
    String subAddress,
    double latitude,
    double longitude,
    String fullAddress,
  ) {
    final nameController = TextEditingController();
    bool makeDefault = false;
    
    // CRITICAL FIX: Capture the parent context that has access to AddressPickerBloc
    final parentContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Save Address',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorManager.primary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Give this address a name (optional)',
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorManager.black.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Home, Office, Friend\'s place',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: ColorManager.otpField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: makeDefault,
                      activeColor: ColorManager.primary,
                      onChanged: (value) {
                        setState(() {
                          makeDefault = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Make this my default address',
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorManager.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (widget.onAddressSelected != null) {
                  widget.onAddressSelected!(address, 'Other', latitude, longitude);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: ColorManager.primary,
              ),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final addressName = nameController.text.trim().isEmpty
                    ? 'Other'
                    : nameController.text.trim();

                // CRITICAL FIX: Use parentContext instead of builderContext
                // parentContext has access to the AddressPickerBloc provider
                parentContext.read<AddressPickerBloc>().add(
                  SaveAddressEvent(
                    address: address,
                    subAddress: subAddress,
                    addressName: addressName,
                    latitude: latitude,
                    longitude: longitude,
                    fullAddress: fullAddress,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}