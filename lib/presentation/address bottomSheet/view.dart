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

  const AddressPickerBottomSheet({
    Key? key,
    this.onAddressSelected,
  }) : super(key: key);

  static Future<Map<String, dynamic>?> show(BuildContext context) async {
    Map<String, dynamic>? result;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressPickerBottomSheet(
        onAddressSelected: (address, subAddress, latitude, longitude) {
          // Store the selection in the result map
          result = {
            'address': address,
            'subAddress': subAddress,
            'latitude': latitude,
            'longitude': longitude,
          };
          
          // Close the bottom sheet
          Navigator.of(context).pop();
        },
      ),
    );
    
    // Return the selected address or null if canceled
    return result;
  }

  @override
  State<AddressPickerBottomSheet> createState() => _AddressPickerBottomSheetState();
}

class _AddressPickerBottomSheetState extends State<AddressPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field when the bottom sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
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
    // Get screen size for responsive design
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    // Calculate responsive height (80% of screen height plus keyboard height)
    final sheetHeight = size.height * 0.8 + bottomPadding;
    
    // Responsive scaling factor
    final textScale = size.width / 375;

    return BlocProvider(
      create: (context) => AddressPickerBloc()..add(InitializeAddressPickerEvent()),
      child: BlocConsumer<AddressPickerBloc, AddressPickerState>(
        listener: (context, state) {
          if (state is AddressSelected || state is LocationDetected) {
            // Extract address data
            String address = '';
            String subAddress = '';
            double latitude = 0.0;
            double longitude = 0.0;

            if (state is AddressSelected) {
              address = state.address;
              subAddress = state.subAddress;
              latitude = state.latitude;
              longitude = state.longitude;
            } else if (state is LocationDetected) {
              address = (state as LocationDetected).address;
              subAddress = (state as LocationDetected).subAddress;
              latitude = (state as LocationDetected).latitude;
              longitude = (state as LocationDetected).longitude;
            }

            debugPrint('AddressPickerBottomSheet: Address selected:');
            debugPrint('  Address: $address');
            debugPrint('  Sub-address: $subAddress');
            debugPrint('  Latitude: $latitude');
            debugPrint('  Longitude: $longitude');

            // Call the callback if provided
            if (widget.onAddressSelected != null) {
              widget.onAddressSelected!(address, subAddress, latitude, longitude);
            }
          }
          
          // Show error messages
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
                // Handle bar at top of bottom sheet
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
                
                // Header with back button
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * textScale, 
                    vertical: 16 * textScale
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back, 
                          color: Colors.black87, 
                          size: 22 * textScale
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () {
                          context.read<AddressPickerBloc>().add(CloseAddressPickerEvent());
                        },
                      ),
                      SizedBox(width: 16 * textScale),
                      Text(
                        'Add Address',
                        style: TextStyle(
                          fontSize: FontSize.s20 * textScale,
                          fontWeight: FontWeightManager.bold,
                          color: Colors.black87,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Search box with grey background
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * textScale, 
                    vertical: 12 * textScale
                  ),
                  color: Colors.grey[100],
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4 * textScale),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 12 * textScale),
                        Icon(
                          Icons.search, 
                          color: Colors.grey[600], 
                          size: 20 * textScale
                        ),
                        SizedBox(width: 12 * textScale),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Enter your address',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: FontSize.s16 * textScale,
                                fontFamily: FontFamily.Montserrat,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 16 * textScale
                              ),
                            ),
                            onChanged: (query) {
                              context.read<AddressPickerBloc>().add(
                                SearchAddressEvent(query: query),
                              );
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.clear, 
                              size: 20 * textScale
                            ),
                            onPressed: () {
                              _searchController.clear();
                              context.read<AddressPickerBloc>().add(ClearSearchEvent());
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Loading indicator with Lottie
                if (state is AddressPickerLoading || state is LocationDetecting)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 160 * textScale,
                            width: 160 * textScale,
                            child: Lottie.asset(
                              'assets/lottie/loading.json',
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(height: 16 * textScale),
                          Text(
                            state is LocationDetecting 
                              ? 'Detecting location...' 
                              : 'Searching...',
                            style: TextStyle(
                              fontSize: FontSize.s16 * textScale,
                              fontWeight: FontWeightManager.medium,
                              color: Colors.grey[700],
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Suggestions header (only in success state)
                if (state is AddressPickerLoadSuccess)
                  Padding(
                    padding: EdgeInsets.only(
                      left: 16 * textScale, 
                      top: 16 * textScale, 
                      bottom: 8 * textScale
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        state.searchQuery.isEmpty ? 'Suggestions' : 'Search Results',
                        style: TextStyle(
                          fontSize: FontSize.s14 * textScale,
                          fontWeight: FontWeightManager.medium,
                          color: Colors.grey[700],
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                    ),
                  ),
                
                // Address suggestions list
                if (state is AddressPickerLoadSuccess)
                  Expanded(
                    child: state.suggestions.isEmpty
                        ? _buildEmptyState(textScale)
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: state.suggestions.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Color(0xFFEEEEEE),
                              indent: 72 * textScale,
                            ),
                            itemBuilder: (context, index) {
                              final suggestion = state.suggestions[index];
                              return _buildAddressItem(
                                context, 
                                suggestion.mainText, 
                                suggestion.secondaryText,
                                suggestion.latitude ?? 0.0,
                                suggestion.longitude ?? 0.0,
                                textScale,
                              );
                            },
                          ),
                  ),
                
                // Use current location button
                Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(height: 1, thickness: 0.5),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            context.read<AddressPickerBloc>().add(UseCurrentLocationEvent());
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              vertical: 16 * textScale, 
                              horizontal: 16 * textScale
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8 * textScale),
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(25 * textScale),
                                  ),
                                  child: Icon(
                                    Icons.my_location,
                                    color: Colors.deepOrange,
                                    size: 24 * textScale,
                                  ),
                                ),
                                SizedBox(width: 16 * textScale),
                                Text(
                                  'Use Current Location',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16 * textScale,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: FontFamily.Montserrat,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Add extra padding at the bottom for safe area
                      SizedBox(height: MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressItem(
    BuildContext context, 
    String mainText, 
    String secondaryText,
    double latitude,
    double longitude,
    double textScale,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint('AddressPickerBottomSheet: Address item tapped:');
          debugPrint('  Main text: $mainText');
          debugPrint('  Secondary text: $secondaryText');
          debugPrint('  Latitude: $latitude');
          debugPrint('  Longitude: $longitude');
          
          context.read<AddressPickerBloc>().add(
            SelectAddressEvent(
              address: mainText,
              subAddress: secondaryText,
              latitude: latitude,
              longitude: longitude,
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16 * textScale, 
            vertical: 12 * textScale
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 2 * textScale),
                child: Icon(
                  Icons.location_on,
                  color: Colors.grey[500],
                  size: 24 * textScale,
                ),
              ),
              SizedBox(width: 16 * textScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mainText,
                      style: TextStyle(
                        fontSize: FontSize.s16 * textScale,
                        fontWeight: FontWeightManager.medium,
                        color: Colors.black87,
                        fontFamily: FontFamily.Montserrat,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (secondaryText.isNotEmpty) ...[
                      SizedBox(height: 4 * textScale),
                      Text(
                        secondaryText,
                        style: TextStyle(
                          fontSize: FontSize.s14 * textScale,
                          color: Colors.grey[600],
                          fontFamily: FontFamily.Montserrat,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double textScale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 56 * textScale,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16 * textScale),
          Text(
            'No addresses found',
            style: TextStyle(
              fontSize: FontSize.s16 * textScale,
              fontWeight: FontWeightManager.medium,
              color: Colors.grey[700],
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          SizedBox(height: 8 * textScale),
          Text(
            'Try a different search term',
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
}