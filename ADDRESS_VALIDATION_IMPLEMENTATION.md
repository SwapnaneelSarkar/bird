# Address Validation Implementation

## Overview
This implementation ensures that only one address can have the name "home" (case-insensitive) in the address management system. If one address already has the name "home", then no other address can be saved with that name.

## Implementation Details

### 1. Address Bottom Sheet (`lib/presentation/address bottomSheet/view.dart`)

#### New Address Creation
- Added `_isHomeNameExists()` helper function to check if "home" name already exists
- Enhanced validation in the save button to specifically check for "home" name
- Added visual feedback with error icon and warning message when "home" is already taken
- Case-insensitive validation using `toLowerCase()`

#### Edit Address Dialog
- Added `_isHomeNameExistsExcludingCurrent()` helper function to check for "home" name while excluding the current address being edited
- This allows users to edit their existing "home" address without conflicts
- Same validation logic as new address creation

### 2. Profile View (`lib/presentation/profile_view/view.dart`)

#### Edit Address Dialog
- Added similar validation logic for editing addresses in the profile view
- Uses the AddressPickerBloc state to access saved addresses
- Prevents creating duplicate "home" addresses while allowing editing of existing ones

### 3. Validation Logic

#### For New Addresses
```dart
if (lowerName == 'home' && _isHomeNameExists()) {
  // Show error message and prevent saving
}
```

#### For Editing Addresses
```dart
if (lowerName == 'home' && _isHomeNameExistsExcludingCurrent()) {
  // Show error message and prevent updating
}
```

### 4. User Experience Improvements

#### Visual Feedback
- Error icon appears in the address name field when "home" is already taken
- Warning message appears below the field explaining the restriction
- Real-time feedback as user types

#### Error Messages
- Clear, user-friendly error messages
- Explains that only one address can be named "Home"
- Consistent messaging across all address management screens

### 5. Testing

Created comprehensive tests in `test/test_address_validation.dart`:
- Tests duplicate "home" name prevention
- Tests editing existing "home" address (should be allowed)
- Tests case-insensitive validation
- All tests pass successfully

## Files Modified

1. `lib/presentation/address bottomSheet/view.dart`
   - Added validation functions
   - Enhanced save and edit dialogs
   - Added visual feedback

2. `lib/presentation/profile_view/view.dart`
   - Added validation for edit address dialog
   - Integrated with AddressPickerBloc state

3. `test/test_address_validation.dart`
   - Created comprehensive test suite
   - Validates all validation scenarios

## Key Features

- ✅ Prevents multiple addresses with "home" name
- ✅ Case-insensitive validation
- ✅ Allows editing existing "home" addresses
- ✅ Visual feedback for users
- ✅ Comprehensive error messages
- ✅ Tested and verified functionality
- ✅ Consistent across all address management screens

## Usage

The validation automatically works when users:
1. Create a new address and try to name it "home"
2. Edit an existing address and try to change its name to "home"
3. Use any case variation of "home" (Home, HOME, home, etc.)

The system will show appropriate error messages and prevent the action if another address already has the "home" name. 