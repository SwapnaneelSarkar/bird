import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/color/colorConstant.dart';

import '../../constants/font/fontManager.dart';
import '../../widgets/custom_button_location.dart';
import '../address bottomSheet/view.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import '../../constants/router/router.dart';

class AddressScreen extends StatefulWidget {
  final String? name;
  final String? email;
  final String? photoPath;
  final Map<String, dynamic>? userData;
  final String? token;

  const AddressScreen({
    Key? key,
    this.name,
    this.email,
    this.photoPath,
    this.userData,
    this.token,
  }) : super(key: key);

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final TextEditingController addressController = TextEditingController();
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    
    // Responsive font size calculation
    final responsiveFontScale = screenWidth / 375; // Base on iPhone 8 width
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocProvider(
        create: (context) => AddressBloc(),
        child: BlocConsumer<AddressBloc, AddressState>(
          listener: (context, state) {
            if (state is AddressSubmittedState) {
              // Navigate to next screen
              debugPrint('AddressScreen: Address submitted successfully, navigating to dashboard');
              Navigator.of(context).pushNamedAndRemoveUntil(
                Routes.dashboard,
                (route) => false,
              );
            }
            if (state is LocationDetectedState) {
              // Update text field with detected address
              addressController.text = state.location;
              // Store coordinates for later use
              setState(() {
                _latitude = state.latitude;
                _longitude = state.longitude;
              });
              
              debugPrint('AddressScreen: Location detected:');
              debugPrint('AddressScreen: Address: ${state.location}');
              debugPrint('AddressScreen: Latitude: ${state.latitude}');
              debugPrint('AddressScreen: Longitude: ${state.longitude}');
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Location detected successfully")),
              );
            }
            if (state is AddressErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05, // 5% of screen width
                    vertical: screenHeight * 0.03, // 3% of screen height
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      Center(
                        child: Image.asset(
                          'assets/logo.png',
                          height: screenHeight * 0.07, // 7% of screen height
                          color: ColorManager.primary,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02), // 2% of screen height
                      
                      // Title
                      Text(
                        'Choose Delivery Address',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: FontSize.s20 * responsiveFontScale,
                          fontWeight: FontWeightManager.bold,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03), // 3% of screen height
                      
                      // Address input card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 3,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(screenWidth * 0.04), // 4% of screen width
                        child: Column(
                          children: [
                            // Address input row with search icon
                            InkWell(
                              onTap: () async {
                                // Show address picker bottom sheet
                                final result = await AddressPickerBottomSheet.show(context);
                                
                                if (result != null) {
                                  setState(() {
                                    // Format the address for display
                                    if (result['subAddress'].toString().isNotEmpty) {
                                      addressController.text = '${result['address']}, ${result['subAddress']}';
                                    } else {
                                      addressController.text = result['address'];
                                    }
                                    
                                    // Save coordinates
                                    _latitude = result['latitude'];
                                    _longitude = result['longitude'];
                                    
                                    debugPrint('AddressScreen: Address selected from picker:');
                                    debugPrint('AddressScreen: Address: ${addressController.text}');
                                    debugPrint('AddressScreen: Latitude: $_latitude');
                                    debugPrint('AddressScreen: Longitude: $_longitude');
                                  });
                                }
                              },
                              child: Row(
                                children: [
                                  // Icon container
                                  Container(
                                    width: screenWidth * 0.1, // 10% of screen width
                                    height: screenWidth * 0.1, // Square aspect ratio
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFCE4D6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.search,
                                      color: ColorManager.primary,
                                      size: screenWidth * 0.05, // 5% of screen width
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.03), // 3% of screen width
                                  
                                  // Text field (non-editable, opens picker)
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              addressController.text.isEmpty 
                                                  ? 'Enter your delivery address *' 
                                                  : addressController.text,
                                              style: TextStyle(
                                                color: addressController.text.isEmpty
                                                    ? Colors.grey[400]
                                                    : Colors.black87,
                                                fontSize: FontSize.s14 * responsiveFontScale,
                                                fontFamily: FontFamily.Montserrat,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Debug information about coordinates (hidden in production)
                            if (_latitude != null && _longitude != null)
                              Padding(
                                padding: EdgeInsets.only(top: 8, left: screenWidth * 0.13),
                                child: Row(
                                  children: [
                                    // Uncomment for debugging
                                    // Icon(
                                    //   Icons.location_on,
                                    //   color: Colors.green,
                                    //   size: 14,
                                    // ),
                                    // SizedBox(width: 4),
                                    // Text(
                                    //   'Coordinates: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                    //   style: TextStyle(
                                    //     color: Colors.green,
                                    //     fontSize: FontSize.s12 * responsiveFontScale,
                                    //     fontFamily: FontFamily.Montserrat,
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            
                            SizedBox(height: screenHeight * 0.02), // 2% of screen height
                            
                            // Continue button
                            CustomButton(
                              text: state is AddressLoadingState ? 'Loading...' : 'Continue',
                              isLoading: state is AddressLoadingState,
                              onPressed: state is AddressLoadingState ? () {} : () {
                                final address = addressController.text.trim();
                                if (address.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter an address'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                // Make sure we have coordinates
                                double latitude = _latitude ?? 0.0;
                                double longitude = _longitude ?? 0.0;
                                
                                debugPrint('AddressScreen: Submitting address: $address');
                                debugPrint('AddressScreen: With coordinates: $latitude, $longitude');
                                
                                context.read<AddressBloc>().add(
                                  SubmitAddressEvent(
                                    address: address,
                                    latitude: latitude,
                                    longitude: longitude,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: screenHeight * 0.02), // 2% of screen height
                      
                      // OR divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: FontSize.s16 * responsiveFontScale,
                                fontWeight: FontWeightManager.semiBold,
                                letterSpacing: 1.2,
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.02), // 2% of screen height
                      
                      // Current location card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 3,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: state is AddressLoadingState ? null : () {
                              debugPrint('AddressScreen: Getting current location');
                              context.read<AddressBloc>().add(DetectLocationEvent());
                            },
                            child: Padding(
                              padding: EdgeInsets.all(screenWidth * 0.04), // 4% of screen width
                              child: Row(
                                children: [
                                  // Location icon container
                                  Container(
                                    width: screenWidth * 0.1, // 10% of screen width
                                    height: screenWidth * 0.1, // Square aspect ratio
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFCE4D6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.location_on,
                                      color: ColorManager.primary ?? const Color(0xFFE67E22),
                                      size: screenWidth * 0.05, // 5% of screen width
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.03), // 3% of screen width
                                  
                                  // Text content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Use My Current Location',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: FontSize.s16 * responsiveFontScale,
                                            fontWeight: FontWeightManager.semiBold,
                                            fontFamily: FontFamily.Montserrat,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Detect your location automatically',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: FontSize.s14 * responsiveFontScale,
                                            fontFamily: FontFamily.Montserrat,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (state is AddressLoadingState)
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: ColorManager.primary,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[400],
                                    ),
                                ],
                              ),
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
    );
  }
}