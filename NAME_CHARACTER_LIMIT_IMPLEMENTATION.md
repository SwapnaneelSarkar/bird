# Name Character Limit Implementation

## Overview
This document outlines the implementation of a 30-character limit for name fields in the Bird app, specifically in the signup page (complete profile) and profile page (settings).

## Changes Made

### 1. CustomTextField Widget Enhancement
**File:** `lib/widgets/text_field2.dart`
- Added `maxLength` parameter to support character limits
- Added `counterText: ''` to hide the character counter display
- Updated constructor to accept the new parameter

### 2. Complete Profile Page (Signup)
**File:** `lib/presentation/complete profile/view.dart`
- Added `maxLength: 30` to the name field
- Updated hint text to indicate the character limit: "Enter your name (max 30 characters)"

**File:** `lib/presentation/complete profile/bloc.dart`
- Added validation logic to check if name exceeds 30 characters
- Added appropriate error message: "Name cannot exceed 30 characters"

### 3. Settings Page (Profile)
**File:** `lib/presentation/settings page/view.dart`
- Added `maxLength: 30` to the name field in `_buildSettingsField` method
- Updated hint text to indicate the character limit: "Enter your full name (alphabets only, max 30 characters)"
- Enhanced `_isValidName` method to include length validation
- Updated validation error messages to distinguish between format and length errors
- Added real-time validation in `onChanged` callback

### 4. Address Name Fields (Bonus Enhancement)
**Files:** 
- `lib/presentation/address bottomSheet/view.dart`
- `lib/presentation/profile_view/view.dart`
- Added `maxLength: 20` for address name fields (e.g., "Home", "Office")
- Updated hint texts to indicate the character limit

## Validation Logic

### Name Validation Rules
1. **Length Limit:** Maximum 30 characters
2. **Character Format:** Only alphabets (a-z, A-Z) and spaces allowed
3. **Real-time Validation:** Errors are shown as user types
4. **Form Submission:** Validation occurs before form submission

### Error Messages
- **Empty Field:** "Name is required"
- **Too Long:** "Name cannot exceed 30 characters"
- **Invalid Format:** "Name can only contain alphabets and spaces"

## Testing

### Test File: `test/test_name_character_limit.dart`
- Tests for names within 30 character limit
- Tests for names exceeding 30 character limit
- Tests for combined format and length validation
- Tests for edge cases (empty strings, spaces)

### Test Results
```
00:01 +4: All tests passed!
```

## User Experience Improvements

1. **Visual Feedback:** Character counter is hidden to avoid UI clutter
2. **Clear Hints:** Updated placeholder text indicates character limits
3. **Real-time Validation:** Users see errors immediately as they type
4. **Consistent Limits:** All name fields have consistent character limits
5. **Graceful Handling:** Appropriate error messages for different validation failures

## Technical Implementation Details

### TextField Configuration
```dart
TextField(
  controller: controller,
  maxLength: 30, // Character limit
  decoration: InputDecoration(
    counterText: '', // Hide character counter
    // ... other decoration properties
  ),
)
```

### Validation Method
```dart
bool _isValidName(String name) {
  final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
  return nameRegex.hasMatch(name.trim()) && name.trim().length <= 30;
}
```

## Files Modified
1. `lib/widgets/text_field2.dart` - Enhanced CustomTextField widget
2. `lib/presentation/complete profile/view.dart` - Signup page name field
3. `lib/presentation/complete profile/bloc.dart` - Signup validation logic
4. `lib/presentation/settings page/view.dart` - Profile page name field
5. `lib/presentation/address bottomSheet/view.dart` - Address name fields
6. `lib/presentation/profile_view/view.dart` - Address name fields
7. `test/test_name_character_limit.dart` - Test cases

## Future Considerations
- Consider adding similar limits to other text fields if needed
- Monitor user feedback on the character limits
- Consider internationalization for names with special characters if required 