# Location Fetching Implementation

## Overview

This implementation adds automatic location fetching when the app restarts and integrates it seamlessly with the existing address management system. The system fetches the user's current location, updates their profile, and saves it as an address if needed.

## Key Components

### 1. AppStartupService (`lib/service/app_startup_service.dart`)

The main service that handles location fetching during app startup.

**Key Features:**
- **Automatic Location Fetching**: Fetches location when app starts (if user is logged in)
- **Smart Updates**: Only updates location if there's a significant change (>1km)
- **User Preferences**: Respects user's auto-location update preferences
- **Rate Limiting**: Prevents excessive location fetches (minimum 1 hour between updates)
- **Fallback Handling**: Gracefully handles location service failures

**Main Methods:**
- `initializeApp()`: Main initialization method called during app startup
- `manualLocationUpdate()`: Allows manual location updates
- `setAutoLocationEnabled(bool)`: Controls auto-location updates
- `isAutoLocationEnabled()`: Checks if auto-location is enabled

### 2. Integration Points

#### Splash Screen (`lib/presentation/splash_screen/view.dart`)
- Calls `AppStartupService.initializeApp()` during app startup
- Shows location update status to user
- Handles both logged-in and non-logged-in users

#### Settings Page (`lib/presentation/settings page/view.dart`)
- **Location Settings Section**: New section with auto-location toggle and manual update button
- **Auto-location Toggle**: Users can enable/disable automatic location updates
- **Manual Update Button**: Users can manually trigger location updates
- **Real-time Feedback**: Shows loading states and success/error messages

#### Home Page (`lib/presentation/home page/view.dart`)
- **Location Update Button**: Added refresh button next to address display
- **Quick Updates**: Users can update location directly from home page
- **Automatic Reload**: Home page reloads with new location data after updates

## How It Works

### 1. App Startup Flow

```
App Starts → Splash Screen → Check Login Status → 
If Logged In → Initialize App Services → Fetch Location → 
Update Profile → Refresh TokenService Data → Save as Address (if needed) → 
Navigate to Dashboard → Home Page Forces Profile Refresh → 
Use Latest Location for Restaurant Fetching
```

### 2. Location Fetching Logic

1. **Check User Status**: Only fetch location if user is logged in
2. **Check Preferences**: Respect user's auto-location settings
3. **Check Rate Limit**: Don't fetch if last fetch was <1 hour ago
4. **Fetch Location**: Use device GPS to get current coordinates
5. **Geocode Address**: Convert coordinates to human-readable address
6. **Compare Distance**: Only update if location changed by >1km
7. **Update Profile**: Save new location to user profile
8. **Refresh TokenService**: Update local user data to reflect new location
9. **Save Address**: Create new address entry if user has no addresses
10. **Home Page Refresh**: Force profile refresh when home page loads to ensure latest location

### 3. Address Management Integration

The system integrates with the existing address management system:

- **Profile Updates**: Updates user's primary address in profile
- **Address Saving**: Saves current location as a new address entry
- **Address Picker**: New location appears in address picker
- **Fallback Logic**: Uses saved addresses if location fetch fails

## User Experience

### Automatic Updates
- **Seamless**: Location updates happen automatically in background
- **Smart**: Only updates when there's a significant location change
- **Respectful**: Respects user preferences and rate limits
- **Informative**: Shows status messages during updates

### Manual Updates
- **Settings Page**: Full control over location settings
- **Home Page**: Quick location update button
- **Visual Feedback**: Loading indicators and success/error messages
- **Immediate Results**: Address updates immediately after location fetch

### User Control
- **Toggle Auto-Updates**: Users can enable/disable automatic updates
- **Manual Triggers**: Users can manually update location anytime
- **Clear Feedback**: Users know when location is being updated
- **Error Handling**: Graceful handling of location service failures

## Technical Implementation

### Location Services
- **GPS Integration**: Uses device GPS for accurate location
- **Geocoding**: Converts coordinates to addresses using multiple services
- **Fallback Services**: Uses OpenStreetMap if primary geocoding fails
- **Error Handling**: Graceful degradation when location services unavailable

### Data Management
- **SharedPreferences**: Stores user preferences and last fetch time
- **API Integration**: Updates user profile via existing API endpoints
- **Address Service**: Integrates with existing address management
- **State Management**: Updates UI state after location changes

### Performance Considerations
- **Rate Limiting**: Prevents excessive API calls
- **Distance Calculation**: Only updates when location change is significant
- **Background Processing**: Location fetching doesn't block UI
- **Caching**: Stores preferences and last fetch time locally

## Configuration

### User Preferences
- `auto_location_enabled`: Boolean flag for auto-location updates
- `last_location_fetch_time`: Timestamp of last location fetch

### System Settings
- **Minimum Distance**: 1km threshold for location updates
- **Rate Limit**: 1 hour minimum between automatic updates
- **GPS Accuracy**: High accuracy for location fetching
- **Geocoding Services**: Multiple fallback services

## Testing

Two test files are included to verify the complete functionality:

### `test_location_fetching.dart`
- Service initialization
- Location fetching
- User preferences
- Manual updates
- Distance calculations

### `test_location_flow.dart`
- Complete flow from app startup to home page
- Profile data consistency verification
- TokenService data refresh validation
- Manual location update flow testing

## Future Enhancements

1. **Background Location**: Periodic location updates in background
2. **Location History**: Track location changes over time
3. **Geofencing**: Trigger updates when entering/leaving areas
4. **Battery Optimization**: Smart location fetching to save battery
5. **Offline Support**: Cache location data for offline use

## Troubleshooting

### Common Issues
1. **Location Permission Denied**: App will gracefully handle and show appropriate messages
2. **GPS Unavailable**: Falls back to last known location or saved addresses
3. **Network Issues**: Geocoding may fail, but coordinates are still saved
4. **API Errors**: Profile updates may fail, but location data is preserved locally

### Debug Information
- All location operations are logged with debug messages
- Error states are clearly communicated to users
- Fallback mechanisms ensure app continues to work

## Security & Privacy

- **Local Storage**: User preferences stored locally on device
- **API Security**: Location updates use existing secure API endpoints
- **User Control**: Users have full control over location sharing
- **Data Minimization**: Only necessary location data is stored
- **Transparency**: Users are informed when location is being accessed 