# Food Type Filter Implementation

## Overview
Implemented client-side food type filtering for restaurants using the `availableFoodTypes` field from the API response, with fallback logic for restaurants that don't have food type data.

## Changes Made

### 1. Restaurant Model Updates (`lib/models/restaurant_model.dart`)
- Added `availableFoodTypes` field to the `Restaurant` class
- Updated constructor to include the new field
- Added parsing logic for `availableFoodTypes` in `fromJson` method
- Handles both array and string representations of the field

### 2. API Service Updates (`lib/presentation/home page/bloc.dart`)
- Modified `_fetchRestaurants` method to support supercategory parameter for server-side filtering
- Kept client-side food type filtering for better control and fallback handling
- Updated `_onFilterByFoodType` to use local state filtering instead of API calls

### 3. Food Type Filtering Logic (`lib/presentation/home page/state.dart`)
- Updated food type filtering to use `availableFoodTypes` field instead of `restaurantFoodType`
- Strict filtering: Only shows restaurants that have the selected food type in their `availableFoodTypes`
- Fallback logic maps `veg_nonveg` field to food type IDs when `availableFoodTypes` is empty
- Supports jain, vegetarian, and non-vegetarian food type filters

### 4. Event Handling Updates (`lib/presentation/home page/bloc.dart`)
- Modified `_onFilterByFoodType` method to update state with food type filter
- Uses local state filtering instead of API calls for better performance
- Maintains existing restaurant list and applies filters locally

## API Endpoint Changes

The API supports the following parameters:
- `latitude` (required): User's latitude
- `longitude` (required): User's longitude  
- `radius` (required): Search radius in kilometers
- `supercategory` (optional): Filter by supercategory ID

### Example API Calls:
```
# Basic call
GET /api/partner/restaurants?latitude=12.9580577&longitude=77.6995769&radius=30

# With supercategory filter
GET /api/partner/restaurants?latitude=12.9580577&longitude=77.6995769&radius=30&supercategory=7acc47a2fa5a4eeb906a753b3
```

**Note**: Food type filtering is handled client-side for better control and fallback handling.

## Expected API Response Structure
The API response should include the `availableFoodTypes` field in each restaurant object:

```json
{
  "status": "SUCCESS",
  "message": "Restaurants fetched successfully",
  "data": [
    {
      "restaurant_name": "Restaurant Name",
      "availableFoodTypes": ["jain", "vegetarian", "non-vegetarian"],
      // ... other fields
    }
  ]
}
```

## Benefits
1. **Client-side filtering**: Provides immediate response and better user experience
2. **Strict filtering**: Only shows restaurants that actually have the selected food type
3. **Fallback handling**: Maps `veg_nonveg` field to food type IDs when `availableFoodTypes` is empty
4. **Performance**: No additional API calls needed for filtering

## Testing
The implementation has been tested with:
- Restaurant model parsing with `availableFoodTypes` field
- API URL construction with optional parameters
- Food type filtering logic using the new field
- Event handling for food type filter changes

## Notes
- The API requires authentication (Bearer token)
- Food type filtering is handled client-side for immediate response
- The `availableFoodTypes` field supports both array and string representations
- Strict filtering: Only restaurants with matching food types are shown
- Fallback logic maps `veg_nonveg` field to food type IDs when `availableFoodTypes` is empty
- Currently supports jain, vegetarian, and non-vegetarian filters
- Can be extended to support more food types as needed 