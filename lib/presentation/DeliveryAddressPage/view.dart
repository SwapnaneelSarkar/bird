import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/color/colorConstant.dart';
import '../../widgets/custom_button_large.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocProvider(
        create: (context) => AddressBloc(),
        child: BlocConsumer<AddressBloc, AddressState>(
          listener: (context, state) {
            if (state is AddressSubmittedState) {
              // Navigate to next screen
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
              );
            }
            if (state is LocationDetectedState) {
              // Update text field with detected address
              addressController.text = state.location;
              // Store coordinates for later use
              _latitude = state.latitude;
              _longitude = state.longitude;
              
              debugPrint('Location detected:');
              debugPrint('Address: ${state.location}');
              debugPrint('Latitude: ${state.latitude}');
              debugPrint('Longitude: ${state.longitude}');
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Location detected successfully")),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      Center(
                        child: Image.asset(
                          'assets/logo.png',
                          height: 54,
                          color: ColorManager.primary,
                        ),
                      ),
                      // Title
                      Text(
                        'Choose Delivery Address',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 20.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Manual address entry card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 3,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Address input row
                            Row(
                              children: [
                                // Icon container
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFCE4D6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.keyboard,
                                    color: ColorManager.primary,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                // Text field
                                Expanded(
                                  child: TextField(
                                    controller: addressController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your delivery address',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                      helperText: _latitude != null && _longitude != null 
                                          ? 'Location: $_latitude, $_longitude' 
                                          : null,
                                      helperStyle: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: ColorManager.primary,
                                          width: 1,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            // Continue button
                            // Continue button
                            CustomLargeButton(
                              text: state is AddressLoadingState ? 'Loading...' : 'Continue',
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
                                
                                double latitude = _latitude ?? 0.0;
                                double longitude = _longitude ?? 0.0;
                                
                                debugPrint('Submitting address: $address');
                                debugPrint('With coordinates: $latitude, $longitude');
                                
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
                      SizedBox(height: 20),
                      // OR divider
                      Row(
                        children: [
                          Spacer(),
                          Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Spacer(),
                        ],
                      ),

                      SizedBox(height: 20),
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
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: state is AddressLoadingState ? null : () {
                              context.read<AddressBloc>().add(DetectLocationEvent());
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Location icon container
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFCE4D6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.location_on,
                                      color: Color(0xFFE67E22),
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  // Text content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Use My Current Location',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Detect your current location automatically',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (state is AddressLoadingState)
                                    const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
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