# Location Fetching Implementation

## Overview
This document describes the implementation of location fetching functionality in the Bird app, including automatic location updates on app startup, manual location updates, and location validation for serviceable areas.

## Key Components

### 1. AppStartupService (`lib/service/app_startup_service.dart`)
- **Purpose**: Handles location fetching and profile updates during app startup
- **Key Methods**:
  - `initializeApp()`: Main initialization method that fetches location and updates profile
  - `manualLocationUpdate()`: Manually triggers location update
  - `setAutoLocationEnabled()`: Controls auto-location updates
  - `isAutoLocationEnabled()`: Checks if auto-location is enabled

### 2. LocationService (`lib/service/location_services.dart`)
- **Purpose**: Handles device location services and geocoding
- **Key Methods**:
  - `getCurrentPosition()`: Gets current GPS coordinates
  - `getAddressFromCoordinates()`: Converts coordinates to address
  - `getCurrentLocationAndAddress()`: Combines position and address fetching

### 3. LocationValidationService (`lib/service/location_validation_service.dart`)
- **Purpose**: Validates if a location is within serviceable areas
- **Key Methods**:
  - `checkLocationServiceability()`: Tests if a location is serviceable via API
  - `checkCurrentLocationServiceability()`: Checks current user location
  - `getUnserviceableLocationMessage()`: Returns user-friendly error message

### 4. UpdateUserService (`lib/service/update_user_service.dart`)
- **Purpose**: Updates user profile with new location data
- **Key Methods**:
  - `updateUserProfileWithId()`: Updates user profile via API

## How It Works

### 1. App Startup Flow
1. **Splash Screen**: Calls `AppStartupService.initializeApp()`
2. **Location Fetch**: Gets current GPS coordinates and converts to address
3. **Distance Check**: Compares with existing location (only updates if >1km difference)
4. **Profile Update**: Attempts to update user profile with new location
5. **Refresh TokenService Data**: Ensures local data is synchronized
6. **Home Page Forces Profile Refresh**: HomeBloc fetches fresh profile data

### 2. Location Validation Flow
1. **Dashboard Check**: Dashboard validates location serviceability on load
2. **API Validation**: Makes test API call to check if location is serviceable
3. **Warning Display**: Shows warning if location is outside serviceable areas
4. **Address Picker**: Provides address picker bottom sheet for location change
5. **Navigation Block**: Prevents navigation to home page if location not serviceable

### 3. Manual Location Update
1. **Settings Page**: User can manually update location
2. **Home Page**: Location update button (removed as per user request)
3. **Force Update**: Bypasses time-based restrictions for manual updates

## Integration Points

### 1. Splash Screen (`lib/presentation/splash_screen/view.dart`)
- Calls `AppStartupService.initializeApp()` after login check
- Shows status messages during location initialization
- Refreshes user data after successful location update

### 2. Dashboard (`lib/presentation/dashboard/view.dart`)
- **Location Validation**: Checks serviceability on load
- **Warning Display**: Shows location warning if not serviceable
- **Address Picker**: Integrates address picker bottom sheet
- **Navigation Control**: Blocks navigation if location not serviceable

### 3. Home Page (`lib/presentation/home page/bloc.dart`)
- **Force Profile Refresh**: Always fetches fresh profile data from API
- **Location-Based Restaurant Fetching**: Uses current location for restaurant search
- **Debug Logging**: Extensive logging for location flow verification

### 4. Settings Page (`lib/presentation/settings page/view.dart`)
- **Auto-Location Toggle**: Enable/disable automatic location updates
- **Manual Update Button**: Trigger immediate location update
- **Location Settings Section**: Dedicated UI for location management

## Data Flow

### 1. Location Data Sources
- **GPS**: Primary source via `geolocator` package
- **Geocoding**: Google Geocoding API with OpenStreetMap fallback
- **Profile API**: Backend user profile data
- **TokenService**: Local cached user data

### 2. Location Data Storage
- **SharedPreferences**: User preferences and timestamps
- **TokenService**: User profile data including location
- **Backend API**: Primary source of truth for user location

### 3. Location Data Usage
- **Restaurant Fetching**: Home page uses location for restaurant search
- **Distance Calculation**: Haversine formula for distance calculations
- **Currency Detection**: Location-based currency symbol detection

## Error Handling

### 1. Location Service Errors
- **Permission Denied**: Graceful fallback to last known location
- **GPS Unavailable**: Shows appropriate error message
- **Network Errors**: Retry mechanism with exponential backoff

### 2. API Errors
- **Serviceable Area**: Shows warning and address picker
- **Authentication**: Redirects to login
- **Network**: Retry with user feedback

### 3. Validation Errors
- **Invalid Coordinates**: Fallback to last known good location
- **Empty Address**: Uses coordinates as fallback
- **API Timeout**: Graceful degradation

## User Experience

### 1. Location Warning System
- **Visual Warning**: Orange warning card in dashboard
- **Clear Message**: User-friendly explanation of the issue
- **Action Button**: Direct access to address picker
- **Navigation Block**: Prevents ordering from unserviceable location

### 2. Address Management
- **Bottom Sheet**: Full-featured address picker
- **Search Functionality**: Real-time address search
- **Current Location**: One-tap current location selection
- **Saved Addresses**: Access to previously saved addresses

### 3. Settings Integration
- **Auto-Location Toggle**: User control over automatic updates
- **Manual Updates**: On-demand location refresh
- **Visual Feedback**: Loading states and success/error messages

## Testing

### 1. Unit Tests
- `test/test_location_fetching.dart`: Basic location functionality tests
- `test/test_location_flow.dart`: Complete location flow testing
- `test/test_location_validation.dart`: Location validation service tests

### 2. Integration Tests
- **App Startup**: Complete startup flow with location fetching
- **Location Updates**: Manual and automatic location updates
- **Address Picker**: Address selection and validation
- **Navigation Flow**: Dashboard to home page with location validation

### 3. Manual Testing
- **Location Changes**: Test with different GPS locations
- **Serviceable Areas**: Test with locations inside/outside service areas
- **Network Conditions**: Test with poor network connectivity
- **Permission Scenarios**: Test with location permissions denied

## Configuration

### 1. Environment Variables
- **Google API Key**: For geocoding services
- **API Base URL**: Backend API endpoint
- **Serviceable Areas**: Backend configuration for service areas

### 2. User Preferences
- **Auto-Location Enabled**: Default true, user can disable
- **Location Fetch Interval**: Minimum 1 hour between automatic updates
- **Distance Threshold**: 1km minimum for location updates

### 3. Debug Settings
- **Debug Logging**: Extensive logging for development
- **Test Mode**: Bypass certain restrictions for testing
- **Mock Location**: Use mock location for testing

## Performance Considerations

### 1. Location Fetching
- **Debouncing**: Prevents excessive location requests
- **Caching**: Caches location data to reduce API calls
- **Background Updates**: Minimal background location usage

### 2. API Optimization
- **Batch Updates**: Combines location and profile updates
- **Conditional Updates**: Only updates when necessary
- **Error Recovery**: Graceful handling of API failures

### 3. UI Performance
- **Lazy Loading**: Location validation on demand
- **Smooth Animations**: Animated transitions for better UX
- **Responsive Design**: Adapts to different screen sizes

## Security Considerations

### 1. Location Privacy
- **Minimal Data**: Only stores necessary location data
- **User Control**: Users can disable location features
- **Secure Storage**: Location data stored securely

### 2. API Security
- **Authentication**: All location updates require valid token
- **Validation**: Server-side validation of location data
- **Rate Limiting**: Prevents abuse of location services

### 3. Data Protection
- **Encryption**: Sensitive data encrypted in transit
- **Access Control**: Limited access to location data
- **Audit Trail**: Logging of location-related actions

## Future Enhancements

### 1. Advanced Features
- **Geofencing**: Automatic location updates based on area changes
- **Location History**: Track location changes over time
- **Predictive Updates**: Anticipate location changes

### 2. Performance Improvements
- **Background Processing**: More efficient background location handling
- **Offline Support**: Basic functionality without network
- **Caching Strategy**: Improved location data caching

### 3. User Experience
- **Location Insights**: Show users their location patterns
- **Smart Suggestions**: Suggest addresses based on usage
- **Integration**: Better integration with system location services 