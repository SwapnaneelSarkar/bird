// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../constants/color/colorConstant.dart';
// import '../../constants/font/fontManager.dart';

// import 'bloc.dart';
// import 'event.dart';
// import 'state.dart';

// class RestaurantProfileView extends StatefulWidget {
//   final String restaurantId;

//   const RestaurantProfileView({
//     Key? key,
//     required this.restaurantId,
//   }) : super(key: key);

//   @override
//   State<RestaurantProfileView> createState() => _RestaurantProfileViewState();
// }

// class _RestaurantProfileViewState extends State<RestaurantProfileView> {
  
//   @override
//   void initState() {
//     super.initState();
//     // Trigger loading of restaurant data when the view is built
//     context.read<RestaurantProfileBloc>().add(
//           LoadRestaurantProfile(restaurantId: widget.restaurantId),
//         );
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: BlocBuilder<RestaurantProfileBloc, RestaurantProfileState>(
//         builder: (context, state) {
//           if (state is RestaurantProfileLoading) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           } else if (state is RestaurantProfileLoaded) {
//             return _buildContent(context, state);
//           } else if (state is RestaurantProfileError) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     'Error: ${state.message}',
//                     style: const TextStyle(
//                       color: Colors.red,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: () {
//                       context.read<RestaurantProfileBloc>().add(
//                             LoadRestaurantProfile(restaurantId: widget.restaurantId),
//                           );
//                     },
//                     child: const Text('Retry'),
//                   ),
//                 ],
//               ),
//             );
//           }
//           // Initial state or any other state
//           return const Center(
//             child: CircularProgressIndicator(),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildContent(BuildContext context, RestaurantProfileLoaded state) {
//     final restaurant = state.restaurant;
//     final size = MediaQuery.of(context).size;
//     final horizontalPadding = size.width * 0.045;
    
//     return SafeArea(
//       child: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Back Button
//             Padding(
//               padding: EdgeInsets.all(horizontalPadding),
//               child: GestureDetector(
//                 onTap: () => Navigator.pop(context),
//                 child: const Icon(
//                   Icons.arrow_back,
//                   size: 24,
//                 ),
//               ),
//             ),
            
//             // Restaurant Name
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
//               child: Text(
//                 restaurant.name,
//                 style: TextStyle(
//                   fontSize: _responsiveFontSize(context, 28),
//                   fontWeight: FontWeight.bold,
//                   color: ColorManager.black,
//                   fontFamily: FontFamily.ArbutusSlab,
//                 ),
//               ),
//             ),
            
//             // Cuisine
//             Padding(
//               padding: EdgeInsets.only(
//                 left: horizontalPadding,
//                 right: horizontalPadding,
//                 top: size.height * 0.008,
//               ),
//               child: Text(
//                 restaurant.cuisine,
//                 style: TextStyle(
//                   fontSize: _responsiveFontSize(context, 16),
//                   fontWeight: FontWeightManager.regular,
//                   color: ColorManager.black,
//                   fontFamily: FontFamily.Montserrat,
//                 ),
//               ),
//             ),
            
//             // Address
//             Padding(
//               padding: EdgeInsets.only(
//                 left: horizontalPadding,
//                 right: horizontalPadding,
//                 top: size.height * 0.01,
//               ),
//               child: Text(
//                 restaurant.address,
//                 style: TextStyle(
//                   fontSize: _responsiveFontSize(context, 14),
//                   fontWeight: FontWeightManager.regular,
//                   color: ColorManager.black,
//                   fontFamily: FontFamily.Montserrat,
//                 ),
//               ),
//             ),
            
//             SizedBox(height: size.height * 0.025),
            
//             // Opening Hours Row
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   // Open Now with clock icon
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.access_time_rounded, 
//                         size: _responsiveFontSize(context, 20), 
//                         color: restaurant.openNow == true ? Colors.green : Colors.red,
//                       ),
//                       SizedBox(width: size.width * 0.02),
//                       Text(
//                         restaurant.openNow == true ? "Open Now" : "Closed",
//                         style: TextStyle(
//                           fontSize: _responsiveFontSize(context, 14),
//                           fontWeight: FontWeightManager.medium,
//                           color: restaurant.openNow == true ? Colors.green : Colors.red,
//                           fontFamily: FontFamily.Montserrat,
//                         ),
//                       ),
//                     ],
//                   ),
                  
//                   // Closing time
//                   Text(
//                     "Closes at ${restaurant.closesAt ?? '5:30 PM'}",
//                     style: TextStyle(
//                       fontSize: _responsiveFontSize(context, 14),
//                       fontWeight: FontWeightManager.regular,
//                       color: ColorManager.black,
//                       fontFamily: FontFamily.Montserrat,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
            
//             SizedBox(height: size.height * 0.035),
            
//             // Photos Section Title
//             Padding(
//               padding: EdgeInsets.only(left: horizontalPadding),
//               child: Text(
//                 "Photos",
//                 style: TextStyle(
//                   fontSize: _responsiveFontSize(context, 20),
//                   fontWeight: FontWeightManager.semiBold,
//                   color: ColorManager.black,
//                   fontFamily: FontFamily.Montserrat,
//                 ),
//               ),
//             ),
            
//             SizedBox(height: size.height * 0.015),
            
//             // Photos Grid using placeholder containers instead of real images
//             _buildPhotoGrid(context),
            
//             SizedBox(height: size.height * 0.035),
            
//             // // Legal Information Section
//             // Padding(
//             //   padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
//             //   child: Column(
//             //     crossAxisAlignment: CrossAxisAlignment.start,
//             //     children: [
//             //       // Legal Information Title
//             //       Text(
//             //         "Legal Information",
//             //         style: TextStyle(
//             //           fontSize: _responsiveFontSize(context, 20),
//             //           fontWeight: FontWeightManager.semiBold,
//             //           color: ColorManager.black,
//             //           fontFamily: FontFamily.Montserrat,
//             //         ),
//             //       ),
                  
//             //       SizedBox(height: size.height * 0.02),
                  
//             //       // Legal Name
//             //       _buildLegalInfoItem(
//             //         context, 
//             //         "Legal Name", 
//             //         restaurant.legalName ?? "Legal Name Not Available"
//             //       ),
                  
//             //       SizedBox(height: size.height * 0.02),
                  
//             //       // GST Number
//             //       _buildLegalInfoItem(
//             //         context, 
//             //         "GST Number", 
//             //         restaurant.gstNumber ?? "GST Number Not Available"
//             //       ),
                  
//             //       SizedBox(height: size.height * 0.02),
                  
//             //       // FSSAI License Number
//             //       _buildLegalInfoItem(
//             //         context, 
//             //         "FSSAI License Number", 
//             //         restaurant.fssaiLicenseNumber ?? "License Number Not Available"
//             //       ),
//             //     ],
//             //   ),
//             // ),
            
//             SizedBox(height: size.height * 0.05),
//           ],
//         ),
//       ),
//     );
//   }
  
//   // Build photo grid with placeholder containers instead of images
//   Widget _buildPhotoGrid(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final horizontalPadding = size.width * 0.045;
    
//     return SizedBox(
//       height: size.width * 0.5,
//       child: ListView(
//         scrollDirection: Axis.horizontal,
//         padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
//         children: List.generate(4, (index) {
//           return Padding(
//             padding: EdgeInsets.only(right: size.width * 0.02),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: Container(
//                 width: size.width * 0.6,
//                 height: size.width * 0.5,
//                 color: Colors.grey.shade300,
//                 child: Center(
//                   child: Icon(
//                     _getIconForIndex(index),
//                     size: 50,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }
  
//   // Helper method to get different icons for each photo placeholder
//   IconData _getIconForIndex(int index) {
//     switch (index) {
//       case 0: return Icons.restaurant;
//       case 1: return Icons.food_bank;
//       case 2: return Icons.dinner_dining;
//       case 3: return Icons.chair;
//       default: return Icons.image;
//     }
//   }
  
//   // Helper widget for building legal information items
//   Widget _buildLegalInfoItem(BuildContext context, String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: _responsiveFontSize(context, 14),
//             fontWeight: FontWeightManager.regular,
//             color: Colors.grey.shade600,
//             fontFamily: FontFamily.Montserrat,
//           ),
//         ),
//         SizedBox(height: 4),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: _responsiveFontSize(context, 16),
//             fontWeight: FontWeightManager.regular,
//             color: ColorManager.black,
//             fontFamily: FontFamily.Montserrat,
//           ),
//         ),
//       ],
//     );
//   }
  
//   // Helper method for responsive font sizing
//   double _responsiveFontSize(BuildContext context, double size) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     // Base width for calculations
//     const baseWidth = 390.0;
//     return size * (screenWidth / baseWidth);
//   }
// }