# Favorites Service Performance Optimization

## Problem Identified

The `FavoritesService` was making repeated API calls in the background, causing performance issues and connection errors. The logs showed:

```
I/flutter ( 4744): FavoritesService: Checking favorite status: https://api.bird.delivery/api/user/favorites/check/R4dcc94f725
I/flutter ( 4744): FavoritesService: Checking favorite status: https://api.bird.delivery/api/user/favorites/check/R8d946500de
I/flutter ( 4744): FavoritesService: Checking favorite status: https://api.bird.delivery/api/user/favorites/check/Rb3ec6e3ab3
```

This was happening because:
1. **Automatic checking**: The app was automatically checking favorite status for every restaurant displayed
2. **Multiple simultaneous requests**: No protection against duplicate API calls
3. **Background processing**: API calls were happening even when not on homepage/favorites page

## Solution Implemented

### 1. Removed Automatic Favorite Status Checking

**Before**: Every restaurant card automatically checked favorite status when displayed
```dart
// Check favorite status when restaurant is first displayed (only once)
if (restaurant.id != null && restaurant.id.isNotEmpty && cachedStatus == null) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<HomeFavoritesBloc>().add(
      CheckHomeFavoriteStatus(partnerId: restaurant.id),
    );
  });
}
```

**After**: No automatic checking - only when user interacts with favorite button
```dart
// Only check favorite status when user interacts with favorite button
// No automatic checking to prevent background API calls
```

### 2. Enhanced Caching and Request Management

**Added tracking for restaurants being checked**:
```dart
final Set<String> _checkingRestaurants = {}; // Track restaurants being checked
```

**Prevented duplicate requests**:
```dart
// Prevent multiple simultaneous checks for the same restaurant
if (_checkingRestaurants.contains(event.partnerId)) {
  debugPrint('HomeFavoritesBloc: Already checking status for ${event.partnerId}');
  return;
}
```

### 3. New Combined Event: CheckAndToggleHomeFavorite

**Created a single event that handles both checking and toggling**:
```dart
class CheckAndToggleHomeFavorite extends HomeFavoritesEvent {
  final String partnerId;
  CheckAndToggleHomeFavorite({required this.partnerId});
}
```

**Benefits**:
- Eliminates the need for `Future.delayed`
- Handles the entire operation in one atomic event
- Prevents race conditions
- More efficient and reliable

### 4. Updated Favorite Button Callbacks

**Before**: Complex async logic with delays
```dart
onFavoriteToggle: () async {
  final bloc = context.read<HomeFavoritesBloc>();
  if (!bloc.hasCheckedRestaurant(restaurant.id)) {
    bloc.add(CheckHomeFavoriteStatus(partnerId: restaurant.id));
    await Future.delayed(const Duration(milliseconds: 200));
    // ... complex logic
  }
}
```

**After**: Simple, direct event dispatch
```dart
onFavoriteToggle: () {
  context.read<HomeFavoritesBloc>().add(
    CheckAndToggleHomeFavorite(partnerId: restaurant.id),
  );
}
```

## Files Modified

1. **`lib/presentation/home page/home_favorites_bloc.dart`**
   - Added `CheckAndToggleHomeFavorite` event
   - Enhanced caching with `_checkingRestaurants` tracking
   - Improved error handling and request deduplication

2. **`lib/presentation/home page/view.dart`**
   - Removed automatic favorite status checking
   - Updated favorite button callbacks to use new event
   - Simplified async logic

3. **`lib/presentation/search_page/searchPage.dart`**
   - Removed automatic favorite status checking
   - Updated favorite button callbacks to use new event
   - Applied same optimizations as home page

## Performance Improvements

### Before Optimization
- ❌ API calls for every restaurant displayed
- ❌ Multiple simultaneous requests
- ❌ Background processing on all pages
- ❌ Connection errors due to too many requests
- ❌ Poor user experience with delays

### After Optimization
- ✅ API calls only when user interacts with favorite button
- ✅ Request deduplication prevents duplicate calls
- ✅ Efficient caching reduces server load
- ✅ No background processing on irrelevant pages
- ✅ Smooth user experience with instant feedback

## Usage Guidelines

### For Home Page and Search Page
- Favorite status is only checked when user taps the heart icon
- Cached results are used for subsequent interactions
- No automatic background checking

### For Favorites Page
- Uses separate `FavoritesBloc` for managing favorites list
- Loads all favorites at once when page is opened
- No performance impact on other pages

## Testing

To verify the optimization:
1. Open the app and navigate to home page
2. Check logs - no automatic favorite status API calls
3. Tap a favorite button - single API call for that restaurant
4. Tap the same button again - no additional API call (uses cache)
5. Navigate to other pages - no background favorite checking

## Future Considerations

1. **Batch API calls**: Consider implementing batch favorite status checking for better efficiency
2. **Offline support**: Cache favorite status locally for offline usage
3. **Background sync**: Periodic sync of favorite status when app is active
4. **User preferences**: Allow users to choose between real-time and cached favorite status 