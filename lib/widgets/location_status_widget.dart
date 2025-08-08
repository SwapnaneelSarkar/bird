import 'package:flutter/material.dart';
import 'package:bird/constants/color/colorConstant.dart';
import 'package:bird/constants/font/fontManager.dart';
import 'package:bird/service/location_services.dart';

class LocationStatusWidget extends StatelessWidget {
  final Map<String, bool>? locationAvailability;
  final bool hasExistingLocation;
  final String? existingAddress;
  final VoidCallback? onEnableLocation;
  final VoidCallback? onSkip;
  final bool showActions;

  const LocationStatusWidget({
    Key? key,
    this.locationAvailability,
    this.hasExistingLocation = false,
    this.existingAddress,
    this.onEnableLocation,
    this.onSkip,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locationService = LocationService();
    
    if (locationAvailability == null) {
      return const SizedBox.shrink();
    }

    final isAvailable = locationAvailability!['available'] == true;
    final statusMessage = locationService.getLocationStatusMessage(locationAvailability!);
    final canPrompt = locationService.canPromptForLocation(locationAvailability!);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? Colors.green.shade200 : Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isAvailable ? Icons.location_on : Icons.location_off,
                color: isAvailable ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAvailable ? 'Location Services Active' : 'Location Services Unavailable',
                  style: TextStyle(
                    fontSize: FontSize.s16,
                    fontFamily: FontFamily.Montserrat,
                    fontWeight: FontWeightManager.semiBold,
                    color: isAvailable ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusMessage,
            style: TextStyle(
              fontSize: FontSize.s14,
              fontFamily: FontFamily.Montserrat,
              fontWeight: FontWeightManager.medium,
                              color: Colors.grey[600],
            ),
          ),
          if (hasExistingLocation && existingAddress != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bookmark_border,
                    color: Colors.blue.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Using saved location: $existingAddress',
                      style: TextStyle(
                        fontSize: FontSize.s12,
                        fontFamily: FontFamily.Montserrat,
                        fontWeight: FontWeightManager.medium,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (showActions && !isAvailable) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (canPrompt && onEnableLocation != null) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onEnableLocation,
                      icon: const Icon(Icons.settings, size: 16),
                      label: Text(
                        'Enable Location',
                        style: TextStyle(
                          fontSize: FontSize.s14,
                          fontFamily: FontFamily.Montserrat,
                          fontWeight: FontWeightManager.medium,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (onSkip != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSkip,
                      icon: const Icon(Icons.skip_next, size: 16),
                      label: Text(
                        'Continue Without Location',
                        style: TextStyle(
                          fontSize: FontSize.s14,
                          fontFamily: FontFamily.Montserrat,
                          fontWeight: FontWeightManager.medium,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorManager.primary,
                        side: BorderSide(color: ColorManager.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class LocationStatusBanner extends StatelessWidget {
  final Map<String, bool>? locationAvailability;
  final bool hasExistingLocation;
  final VoidCallback? onTap;

  const LocationStatusBanner({
    Key? key,
    this.locationAvailability,
    this.hasExistingLocation = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (locationAvailability == null || locationAvailability!['available'] == true) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasExistingLocation ? Colors.blue.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasExistingLocation ? Colors.blue.shade200 : Colors.orange.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasExistingLocation ? Icons.bookmark : Icons.location_off,
              color: hasExistingLocation ? Colors.blue.shade600 : Colors.orange.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasExistingLocation 
                  ? 'Using saved location. Tap to update.'
                  : 'Location services disabled. Tap to enable.',
                style: TextStyle(
                  fontSize: FontSize.s14,
                  fontFamily: FontFamily.Montserrat,
                  fontWeight: FontWeightManager.medium,
                  color: hasExistingLocation ? Colors.blue.shade700 : Colors.orange.shade700,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: hasExistingLocation ? Colors.blue.shade600 : Colors.orange.shade600,
            ),
          ],
        ),
      ),
    );
  }
}