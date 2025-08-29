// lib/presentation/address bottomSheet/view.dart - Updated with real-time address updates
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
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
            // OPTIMIZATION: Show success message and immediately update home page
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Address saved successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
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
          
          if (state is AddressUpdatedSuccessfully) {
            // OPTIMIZATION: Show success message and reload addresses
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Address updated successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            
            // Reload saved addresses to reflect the changes
            context.read<AddressPickerBloc>().add(LoadSavedAddressesEvent());
          }
          
          if (state is AddressDeletedSuccessfully) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Address deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Reload saved addresses to reflect the changes
            context.read<AddressPickerBloc>().add(LoadSavedAddressesEvent());
          }
          
          if (state is AddressSharedSuccessfully) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Address shared successfully'),
                backgroundColor: Colors.green,
              ),
            );
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
                  child: _showSavedAddresses && _hasSavedAddresses(state)
                      ? _buildSavedAddressesList(textScale, state)
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

  bool _hasSavedAddresses(AddressPickerState state) {
    if (state is AddressPickerLoadSuccess) {
      return state.savedAddresses.isNotEmpty;
    }
    if (state is SavedAddressesLoaded) {
      return state.savedAddresses.isNotEmpty;
    }
    return widget.savedAddresses?.isNotEmpty ?? false;
  }

  Widget _buildSavedAddressesList(double textScale, AddressPickerState state) {
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
          child: _buildSavedAddressesListView(textScale, state),
        ),
      ],
    );
  }

  Widget _buildSavedAddressesListView(double textScale, AddressPickerState state) {
    List<Map<String, dynamic>> addresses = [];
    
    if (state is AddressPickerLoadSuccess) {
      addresses = state.savedAddresses.map((savedAddress) => {
        'address_id': savedAddress.addressId,
        'address_line1': savedAddress.addressLine1,
        'address_line2': savedAddress.displayName,
        'city': savedAddress.city,
        'state': savedAddress.state,
        'postal_code': savedAddress.postalCode,
        'country': savedAddress.country,
        'is_default': savedAddress.isDefault ? 1 : 0,
        'latitude': savedAddress.latitude.toString(),
        'longitude': savedAddress.longitude.toString(),
      }).toList();
    } else if (state is SavedAddressesLoaded) {
      addresses = state.savedAddresses.map((savedAddress) => {
        'address_id': savedAddress.addressId,
        'address_line1': savedAddress.addressLine1,
        'address_line2': savedAddress.displayName,
        'city': savedAddress.city,
        'state': savedAddress.state,
        'postal_code': savedAddress.postalCode,
        'country': savedAddress.country,
        'is_default': savedAddress.isDefault ? 1 : 0,
        'latitude': savedAddress.latitude.toString(),
        'longitude': savedAddress.longitude.toString(),
      }).toList();
    } else {
      addresses = widget.savedAddresses ?? [];
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20 * textScale),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        final bloc = BlocProvider.of<AddressPickerBloc>(context, listen: false);
        return _buildSavedAddressItem(address, textScale, bloc);
      },
    );
  }

  Widget _buildSavedAddressItem(Map<String, dynamic> address, double textScale, AddressPickerBloc bloc) {
    final addressName = address['address_line2'] ?? 'Other';
    final addressLine = address['address_line1'] ?? '';
    final city = address['city'] ?? '';
    final state = address['state'] ?? '';
    final isDefault = address['is_default'] == 1;
    final addressId = address['address_id']?.toString() ?? '';
    
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
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Share button
                  IconButton(
                    onPressed: () {
                      _showShareOptions(context, address, textScale);
                    },
                    icon: Icon(
                      Icons.share,
                      color: Colors.grey[600],
                      size: 18 * textScale,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 32 * textScale,
                      minHeight: 32 * textScale,
                    ),
                  ),
                  // Edit button
                  IconButton(
                    onPressed: () {
                      _showEditAddressDialog(context, address, textScale, bloc);
                    },
                    icon: Icon(
                      Icons.edit,
                      color: Colors.grey[600],
                      size: 18 * textScale,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 32 * textScale,
                      minHeight: 32 * textScale,
                    ),
                  ),
                  // Delete button
                  IconButton(
                    onPressed: () {
                      _showDeleteConfirmation(context, addressId, addressName, textScale, bloc);
                    },
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red[400],
                      size: 18 * textScale,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 32 * textScale,
                      minHeight: 32 * textScale,
                    ),
                  ),
                ],
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
    return BlocBuilder<AddressPickerBloc, AddressPickerState>(
      builder: (context, state) {
        final isLoading = state is LocationDetecting;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * textScale),
          child: InkWell(
            onTap: isLoading ? null : () {
              context.read<AddressPickerBloc>().add(UseCurrentLocationEvent());
            },
            borderRadius: BorderRadius.circular(12 * textScale),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16 * textScale),
              decoration: BoxDecoration(
                color: isLoading 
                    ? Colors.grey[100] 
                    : ColorManager.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12 * textScale),
                border: Border.all(
                  color: isLoading 
                      ? Colors.grey[300]! 
                      : ColorManager.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  if (isLoading) ...[
                    SizedBox(
                      width: 16 * textScale,
                      height: 16 * textScale,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                      ),
                    ),
                  ] else ...[
                    Icon(Icons.my_location, color: ColorManager.primary, size: 20 * textScale),
                  ],
                  SizedBox(width: 12 * textScale),
                  Text(
                    isLoading ? 'Getting location...' : 'Use current location',
                    style: TextStyle(
                      color: isLoading ? Colors.grey[600] : ColorManager.primary,
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
      },
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
    final houseFlatController = TextEditingController();
    final apartmentRoadController = TextEditingController();
    bool makeDefault = false;
    final parentContext = context;

    // Use the saved addresses passed in as a prop for duplicate check
    List<String> _getSavedNames() {
      if (widget.savedAddresses != null) {
        return widget.savedAddresses!
          .map((a) => (a['address_line2'] ?? 'Other').toString().toLowerCase())
          .toList();
      }
      return [];
    }

    // Check if "home" name already exists (case-insensitive)
    bool _isHomeNameExists() {
      final savedNames = _getSavedNames();
      return savedNames.any((name) => name.toLowerCase() == 'home');
    }

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
                // Display the fetched address
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                                                Text(
                        '📍 Current Location Detected:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        address,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ColorManager.black,
                        ),
                      ),
                      if (subAddress.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          subAddress,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '📍 ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Give this address a name (required)',
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorManager.black.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  maxLength: 20, // Add 20 character limit for address names
                  decoration: InputDecoration(
                    hintText: 'e.g., Home, Office, Friend\'s place (max 20 chars)',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: ColorManager.otpField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    counterText: '', // Hide the character counter
                    suffixIcon: nameController.text.toLowerCase() == 'home' && _isHomeNameExists()
                        ? Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      // Trigger rebuild to show/hide error icon
                    });
                  },
                ),
                if (nameController.text.toLowerCase() == 'home' && _isHomeNameExists())
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'An address with "Home" name already exists. Please choose a different name.',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'A detailed address will help our Delivery Partner reach your doorstep easily',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'HOUSE / FLAT / FLOOR NO.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.black,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: houseFlatController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Flat 101, House No. 123',
                    filled: true,
                    fillColor: ColorManager.otpField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'APARTMENT / ROAD / AREA (RECOMMENDED)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.black,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: apartmentRoadController,
                  decoration: InputDecoration(
                    hintText: 'e.g., ABC Apartment, Main Road',
                    filled: true,
                    fillColor: ColorManager.otpField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
            ElevatedButton(
              onPressed: () {
                final enteredName = nameController.text.trim();
                final houseFlat = houseFlatController.text.trim();
                final apartmentRoad = apartmentRoadController.text.trim();
                final lowerName = enteredName.toLowerCase();
                final savedNames = _getSavedNames();

                if (enteredName.isEmpty) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an address name.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Special validation for "home" name - only one address can have "home" name
                if (lowerName == 'home' && _isHomeNameExists()) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('An address with "Home" name already exists. Only one address can be named "Home".'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (savedNames.contains(lowerName)) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Name already exists.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Combine house/flat and apartment/road into a single address string
                String combinedAddress = address;
                if (houseFlat.isNotEmpty || apartmentRoad.isNotEmpty) {
                  List<String> addressParts = [];
                  if (houseFlat.isNotEmpty) addressParts.add(houseFlat);
                  if (apartmentRoad.isNotEmpty) addressParts.add(apartmentRoad);
                  if (address.isNotEmpty) addressParts.add(address);
                  
                  combinedAddress = addressParts.join(', ');
                }
                
                Navigator.of(dialogContext).pop();
                parentContext.read<AddressPickerBloc>().add(
                  SaveAddressEvent(
                    address: combinedAddress,
                    subAddress: subAddress,
                    addressName: enteredName,
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

  void _showShareOptions(BuildContext context, Map<String, dynamic> address, double textScale) {
    final addressName = address['address_line2'] ?? 'Other';
    final addressLine = address['address_line1'] ?? '';
    final city = address['city'] ?? '';
    final state = address['state'] ?? '';
    final fullAddress = '$addressLine, $city, $state';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20 * textScale),
            topRight: Radius.circular(20 * textScale),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Padding(
              padding: EdgeInsets.all(20 * textScale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share Address',
                    style: TextStyle(
                      fontSize: FontSize.s18 * textScale,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                  SizedBox(height: 8 * textScale),
                  Text(
                    'Choose how you want to share this address',
                    style: TextStyle(
                      fontSize: FontSize.s12 * textScale,
                      color: Colors.grey[500],
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                  SizedBox(height: 16 * textScale),
                  Container(
                    padding: EdgeInsets.all(12 * textScale),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8 * textScale),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addressName,
                          style: TextStyle(
                            fontSize: FontSize.s14 * textScale,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            fontFamily: FontFamily.Montserrat,
                          ),
                        ),
                        SizedBox(height: 4 * textScale),
                        Text(
                          fullAddress,
                          style: TextStyle(
                            fontSize: FontSize.s12 * textScale,
                            color: Colors.grey[600],
                            fontFamily: FontFamily.Montserrat,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20 * textScale),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _shareText(fullAddress);
                          },
                          icon: Icon(Icons.share, size: 18 * textScale),
                          label: Text(
                            'Share Address',
                            style: TextStyle(fontSize: FontSize.s14 * textScale),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8 * textScale),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * textScale),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Clipboard.setData(ClipboardData(text: fullAddress));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Address copied to clipboard'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: Icon(Icons.copy, size: 18 * textScale),
                          label: Text(
                            'Copy to Clipboard',
                            style: TextStyle(fontSize: FontSize.s14 * textScale),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ColorManager.primary,
                            side: BorderSide(color: ColorManager.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8 * textScale),
                            ),
                          ),
                        ),
                      ),
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

  void _showEditAddressDialog(BuildContext context, Map<String, dynamic> address, double textScale, AddressPickerBloc bloc) {
    final addressId = address['address_id']?.toString() ?? '';
    final addressNameController = TextEditingController(text: address['address_line2'] ?? '');
    final cityController = TextEditingController(text: address['city'] ?? '');
    final stateController = TextEditingController(text: address['state'] ?? '');
    final postalCodeController = TextEditingController(text: address['postal_code'] ?? '');
    final countryController = TextEditingController(text: address['country'] ?? 'India');
    bool isDefault = address['is_default'] == 1;
    final latitude = double.tryParse(address['latitude']?.toString() ?? '') ?? 0.0;
    final longitude = double.tryParse(address['longitude']?.toString() ?? '') ?? 0.0;
    
    // Helper function to check if "home" name exists (excluding current address)
    bool _isHomeNameExistsExcludingCurrent() {
      if (widget.savedAddresses != null) {
        return widget.savedAddresses!
          .where((a) => a['address_id']?.toString() != addressId) // Exclude current address
          .any((a) => (a['address_line2'] ?? 'Other').toString().toLowerCase() == 'home');
      }
      return false;
    }
    
    // Parse existing address to extract house/flat and apartment/road parts
    String existingAddress = address['address_line1'] ?? '';
    String houseFlat = '';
    String apartmentRoad = '';
    
    // Simple parsing logic - this can be improved based on your data format
    if (existingAddress.isNotEmpty) {
      List<String> parts = existingAddress.split(', ');
      if (parts.length >= 2) {
        houseFlat = parts[0];
        apartmentRoad = parts[1];
      } else if (parts.length == 1) {
        apartmentRoad = parts[0];
      }
    }
    
    final houseFlatController = TextEditingController(text: houseFlat);
    final apartmentRoadController = TextEditingController(text: apartmentRoad);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Edit Address',
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
                  'Address Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.black,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: addressNameController,
                  maxLength: 20, // Add 20 character limit for address names
                  decoration: InputDecoration(
                    hintText: 'e.g., Home, Office (max 20 chars)',
                    filled: true,
                    fillColor: ColorManager.otpField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    counterText: '', // Hide the character counter
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'A detailed address will help our Delivery Partner reach your doorstep easily',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'HOUSE / FLAT / FLOOR NO.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.black,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: houseFlatController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Flat 101, House No. 123',
                    filled: true,
                    fillColor: ColorManager.otpField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'APARTMENT / ROAD / AREA (RECOMMENDED)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.black,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: apartmentRoadController,
                  decoration: InputDecoration(
                    hintText: 'e.g., ABC Apartment, Main Road',
                    filled: true,
                    fillColor: ColorManager.otpField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'City',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ColorManager.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: cityController,
                            decoration: InputDecoration(
                              hintText: 'City',
                              filled: true,
                              fillColor: ColorManager.otpField,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'State',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ColorManager.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: stateController,
                            decoration: InputDecoration(
                              hintText: 'State',
                              filled: true,
                              fillColor: ColorManager.otpField,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isDefault,
                      activeColor: ColorManager.primary,
                      onChanged: (value) {
                        setState(() {
                          isDefault = value ?? false;
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
              },
              style: TextButton.styleFrom(
                foregroundColor: ColorManager.primary,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final addressName = addressNameController.text.trim();
                final houseFlat = houseFlatController.text.trim();
                final apartmentRoad = apartmentRoadController.text.trim();
                final city = cityController.text.trim();
                final state = stateController.text.trim();
                final postalCode = postalCodeController.text.trim();
                final country = countryController.text.trim();

                if (addressName.isEmpty || city.isEmpty || state.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in address name, city and state.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Special validation for "home" name - only one address can have "home" name
                final lowerName = addressName.toLowerCase();
                if (lowerName == 'home' && _isHomeNameExistsExcludingCurrent()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('An address with "Home" name already exists. Only one address can be named "Home".'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Combine house/flat and apartment/road into a single address string
                String combinedAddress = '';
                List<String> addressParts = [];
                if (houseFlat.isNotEmpty) addressParts.add(houseFlat);
                if (apartmentRoad.isNotEmpty) addressParts.add(apartmentRoad);
                
                combinedAddress = addressParts.join(', ');

                Navigator.of(dialogContext).pop();
                // Use the passed bloc instance
                bloc.add(
                  UpdateAddressEvent(
                    addressId: addressId,
                    addressLine1: combinedAddress,
                    addressLine2: addressName,
                    city: city,
                    state: state,
                    postalCode: postalCode,
                    country: country,
                    latitude: latitude,
                    longitude: longitude,
                    isDefault: isDefault,
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
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String addressId, String addressName, double textScale, AddressPickerBloc bloc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Address',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$addressName"? This action cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            color: ColorManager.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: ColorManager.primary,
            ),
            child: const Text('Cancel'),
          ),
                      ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Use the passed bloc instance
                bloc.add(
                  DeleteSavedAddressEvent(addressId: addressId),
                );
              },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _shareText(String text) {
    // Share to other apps
    SharePlus.instance.share(ShareParams(text: text));
  }
}