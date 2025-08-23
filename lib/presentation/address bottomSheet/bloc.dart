// lib/presentation/address bottomSheet/bloc.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../service/location_services.dart';
import '../../service/token_service.dart';
import '../../constants/api_constant.dart';
import 'event.dart';
import 'state.dart';

class AddressPickerBloc extends Bloc<AddressPickerEvent, AddressPickerState> {
  final LocationService _locationService = LocationService();
  final String _placesApiKey = 'AIzaSyBmRJ1-tX0oWD3FFKAuV8NB7Hg9h6NQXeU';
  
  // For caching recent addresses
  List<AddressSuggestion> _recentAddresses = [];
  
  // For caching saved addresses
  List<SavedAddress> _savedAddresses = [];
  
  // Debounce for search - REDUCED from 500ms to 300ms for faster response
  Timer? _debounce;
  
  // Cache for API responses to avoid redundant calls
  Map<String, dynamic> _apiCache = {};
  Timer? _cacheCleanupTimer;

  AddressPickerBloc() : super(AddressPickerInitial()) {
    on<InitializeAddressPickerEvent>(_onInitialize);
    on<SearchAddressEvent>(_onSearchAddress);
    on<SelectAddressEvent>(_onSelectAddress);
    on<UseCurrentLocationEvent>(_onUseCurrentLocation);
    on<ClearSearchEvent>(_onClearSearch);
    on<CloseAddressPickerEvent>(_onCloseAddressPicker);
    on<SaveAddressEvent>(_onSaveAddress);
    on<LoadSavedAddressesEvent>(_onLoadSavedAddresses);
    on<SelectSavedAddressEvent>(_onSelectSavedAddress);
    on<DeleteSavedAddressEvent>(_onDeleteSavedAddress);
    on<EditAddressEvent>(_onEditAddress);
    on<UpdateAddressEvent>(_onUpdateAddress);
    on<ShareAddressEvent>(_onShareAddress);
    
    // Start cache cleanup timer
    _startCacheCleanup();
  }

  void _startCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _apiCache.clear();
      debugPrint('AddressPickerBloc: Cache cleaned up');
    });
  }

  Future<void> _onInitialize(
      InitializeAddressPickerEvent event, Emitter<AddressPickerState> emit) async {
    try {
      debugPrint('AddressPickerBloc: Initializing address picker');
      
      // Load recent addresses from SharedPreferences
      await _loadRecentAddresses();
      
      // Load saved addresses from API with caching
      await _loadSavedAddressesFromAPI();
      
      // Emit initial state with recent addresses and saved addresses
      emit(AddressPickerLoadSuccess(
        suggestions: _recentAddresses,
        savedAddresses: _savedAddresses,
      ));
      
      debugPrint('AddressPickerBloc: Initialized with ${_recentAddresses.length} recent addresses and ${_savedAddresses.length} saved addresses');
    } catch (e) {
      debugPrint('AddressPickerBloc: Error initializing address picker: $e');
      emit(AddressPickerLoadFailure(error: 'Failed to initialize address picker'));
    }
  }

  Future<void> _onLoadSavedAddresses(
      LoadSavedAddressesEvent event, Emitter<AddressPickerState> emit) async {
    try {
      debugPrint('AddressPickerBloc: Loading saved addresses');
      emit(SavedAddressesLoading());
      
      await _loadSavedAddressesFromAPI();
      
      emit(SavedAddressesLoaded(
        savedAddresses: _savedAddresses,
        suggestions: _recentAddresses,
      ));
      
      debugPrint('AddressPickerBloc: Loaded ${_savedAddresses.length} saved addresses');
    } catch (e) {
      debugPrint('AddressPickerBloc: Error loading saved addresses: $e');
      emit(SavedAddressesLoadFailure(error: 'Failed to load saved addresses'));
    }
  }

  Future<void> _onSelectSavedAddress(
      SelectSavedAddressEvent event, Emitter<AddressPickerState> emit) async {
    try {
      debugPrint('AddressPickerBloc: Saved address selected: ${event.savedAddress.displayName}');
      
      emit(SavedAddressSelected(savedAddress: event.savedAddress));
    } catch (e) {
      debugPrint('AddressPickerBloc: Error selecting saved address: $e');
      emit(AddressPickerLoadFailure(error: 'Failed to select saved address'));
    }
  }

  Future<void> _onDeleteSavedAddress(
      DeleteSavedAddressEvent event, Emitter<AddressPickerState> emit) async {
    try {
      debugPrint('AddressPickerBloc: Deleting saved address: ${event.addressId}');
      emit(AddressDeleting());

      // Get authentication token
      final token = await TokenService.getToken();
      
      if (token == null) {
        debugPrint('AddressPickerBloc: No authentication token found');
        emit(AddressPickerLoadFailure(error: 'Please login again'));
        return;
      }

      // Make API call to delete address
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/user/addresses/${event.addressId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('AddressPickerBloc: Delete API response status: ${response.statusCode}');
      debugPrint('AddressPickerBloc: Delete API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == true) {
          debugPrint('AddressPickerBloc: Address deleted successfully');
          
          // Remove from local cache
          _savedAddresses.removeWhere((addr) => addr.addressId == event.addressId);
          
          // Clear API cache to ensure fresh data
          _apiCache.clear();
          
          // Emit success state
          emit(AddressDeletedSuccessfully(deletedAddressId: event.addressId));
          
          // Reload the list
          emit(SavedAddressesLoaded(
            savedAddresses: _savedAddresses,
            suggestions: _recentAddresses,
          ));
        } else {
          debugPrint('AddressPickerBloc: API returned error: ${responseData['message']}');
          emit(AddressPickerLoadFailure(
            error: responseData['message'] ?? 'Failed to delete address'
          ));
        }
      } else {
        debugPrint('AddressPickerBloc: HTTP error ${response.statusCode}');
        emit(AddressPickerLoadFailure(
          error: 'Failed to delete address. Please try again.'
        ));
      }
    } catch (e) {
      debugPrint('AddressPickerBloc: Error deleting saved address: $e');
      emit(AddressPickerLoadFailure(error: 'Error deleting address. Please try again.'));
    }
  }

  Future<void> _onEditAddress(
      EditAddressEvent event, Emitter<AddressPickerState> emit) async {
    try {
      debugPrint('AddressPickerBloc: Editing address: ${event.savedAddress.addressId}');
      emit(AddressEditing(savedAddress: event.savedAddress));
    } catch (e) {
      debugPrint('AddressPickerBloc: Error editing address: $e');
      emit(AddressPickerLoadFailure(error: 'Error editing address. Please try again.'));
    }
  }

  Future<void> _onUpdateAddress(
      UpdateAddressEvent event, Emitter<AddressPickerState> emit) async {
    try {
      debugPrint('AddressPickerBloc: Updating address: ${event.addressId}');
      emit(AddressUpdating());

      // Get authentication token
      final token = await TokenService.getToken();
      
      if (token == null) {
        debugPrint('AddressPickerBloc: No authentication token found');
        emit(AddressPickerLoadFailure(error: 'Please login again'));
        return;
      }

      // Prepare API request body
      final requestBody = {
        "address_line1": event.addressLine1,
        "address_line2": event.addressLine2,
        "city": event.city,
        "state": event.state,
        "postal_code": event.postalCode,
        "country": event.country,
        "is_default": event.isDefault,
        "latitude": event.latitude,
        "longitude": event.longitude,
      };

      debugPrint('AddressPickerBloc: Sending request to update address: $requestBody');

      // Make API call to update address
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/user/addresses/${event.addressId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('AddressPickerBloc: Update API response status: ${response.statusCode}');
      debugPrint('AddressPickerBloc: Update API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == true) {
          debugPrint('AddressPickerBloc: Address updated successfully');
          
          // Update local cache
          final updatedAddress = SavedAddress(
            addressId: event.addressId,
            userId: _savedAddresses.firstWhere((addr) => addr.addressId == event.addressId).userId,
            addressLine1: event.addressLine1,
            addressLine2: event.addressLine2,
            city: event.city,
            state: event.state,
            postalCode: event.postalCode,
            country: event.country,
            isDefault: event.isDefault,
            latitude: event.latitude,
            longitude: event.longitude,
            createdAt: _savedAddresses.firstWhere((addr) => addr.addressId == event.addressId).createdAt,
            updatedAt: DateTime.now(),
          );
          
          // Update in local cache
          final index = _savedAddresses.indexWhere((addr) => addr.addressId == event.addressId);
          if (index != -1) {
            _savedAddresses[index] = updatedAddress;
          }
          
          // Clear API cache to ensure fresh data
          _apiCache.clear();
          
          // Emit success state
          emit(AddressUpdatedSuccessfully(updatedAddress: updatedAddress));
          
          // Reload the list
          emit(SavedAddressesLoaded(
            savedAddresses: _savedAddresses,
            suggestions: _recentAddresses,
          ));
        } else {
          debugPrint('AddressPickerBloc: API returned error: ${responseData['message']}');
          emit(AddressPickerLoadFailure(
            error: responseData['message'] ?? 'Failed to update address'
          ));
        }
      } else {
        debugPrint('AddressPickerBloc: HTTP error ${response.statusCode}');
        emit(AddressPickerLoadFailure(
          error: 'Failed to update address. Please try again.'
        ));
      }
    } catch (e) {
      debugPrint('AddressPickerBloc: Error updating address: $e');
      emit(AddressPickerLoadFailure(error: 'Error updating address. Please try again.'));
    }
  }

  Future<void> _onShareAddress(
      ShareAddressEvent event, Emitter<AddressPickerState> emit) async {
    try {
      debugPrint('AddressPickerBloc: Sharing address: ${event.savedAddress.addressId}');
      emit(AddressSharing());
      
      // For now, just emit success - the actual sharing will be handled in the UI
      emit(AddressSharedSuccessfully(sharedAddress: event.savedAddress));
    } catch (e) {
      debugPrint('AddressPickerBloc: Error sharing address: $e');
      emit(AddressPickerLoadFailure(error: 'Error sharing address. Please try again.'));
    }
  }

  Future<void> _onSearchAddress(
    SearchAddressEvent event, Emitter<AddressPickerState> emit) async {
    // Cancel any previous debounce timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // If search query is empty, show recent addresses and saved addresses
    if (event.query.isEmpty) {
      debugPrint('AddressPickerBloc: Empty query, showing recent and saved addresses');
      emit(AddressPickerLoadSuccess(
        suggestions: _recentAddresses,
        searchQuery: '',
        savedAddresses: _savedAddresses,
      ));
      return;
    }

    // Show loading state immediately
    emit(AddressPickerLoading());
    debugPrint('AddressPickerBloc: Searching for address: ${event.query}');

    // Create a completer to properly handle the debounce
    final completer = Completer();
    
    // OPTIMIZATION: Reduced debounce from 500ms to 300ms for faster response
    _debounce = Timer(const Duration(milliseconds: 300), () {
      completer.complete();
    });
    
    // Wait for the debounce timer to complete
    await completer.future;
    
    // Check if the emitter is still active
    if (emit.isDone) return;
    
    try {
      final suggestions = await _getAddressSuggestions(event.query);
      debugPrint('AddressPickerBloc: Got ${suggestions.length} address suggestions');
      
      // Check again if the emitter is still active before emitting
      if (!emit.isDone) {
        emit(AddressPickerLoadSuccess(
          suggestions: suggestions,
          searchQuery: event.query,
          savedAddresses: _savedAddresses,
        ));
      }
    } catch (e) {
      debugPrint('AddressPickerBloc: Error searching for address: $e');
      
      // Check if the emitter is still active before emitting
      if (!emit.isDone) {
        emit(AddressPickerLoadFailure(error: 'Failed to search for addresses'));
      }
    }
  }

  Future<void> _onSelectAddress(
      SelectAddressEvent event, Emitter<AddressPickerState> emit) async {
    try {
      debugPrint('AddressPickerBloc: Address selected, showing name input dialog');
      
      // Emit state to show address name input dialog
      emit(AddressNameInputRequired(
        address: event.address,
        subAddress: event.subAddress,
        latitude: event.latitude,
        longitude: event.longitude,
        fullAddress: event.fullAddress,
      ));
    } catch (e) {
      debugPrint('AddressPickerBloc: Error selecting address: $e');
      emit(AddressPickerLoadFailure(error: 'Failed to select address'));
    }
  }

  Future<void> _onSaveAddress(
      SaveAddressEvent event, Emitter<AddressPickerState> emit) async {
    try {
      debugPrint('AddressPickerBloc: Saving address to server');
      emit(AddressSaving());

      // Get authentication token and user ID using TokenService
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('AddressPickerBloc: No authentication token or user ID found');
        emit(AddressPickerLoadFailure(error: 'Please login again'));
        return;
      }

      debugPrint('AddressPickerBloc: Using token and user ID for API call');

      // Parse address to get different components
      final addressComponents = _parseAddressComponents(event.fullAddress);
      
      // Prepare API request body
      final requestBody = {
        "user_id": userId,
        "address_line1": event.address,
        "address_line2": event.addressName.isNotEmpty ? event.addressName : null,
        "city": addressComponents['city'] ?? '',
        "state": addressComponents['state'] ?? '',
        "postal_code": '1',
        "country": addressComponents['country'] ?? 'India',
        "is_default": false,
        "latitude": event.latitude,
        "longitude": event.longitude,
      };

      debugPrint('AddressPickerBloc: Sending request to save address: $requestBody');

      // Make API call
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/user/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('AddressPickerBloc: API response status: ${response.statusCode}');
      debugPrint('AddressPickerBloc: API response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == true) {
          debugPrint('AddressPickerBloc: Address saved successfully');
          
          // Create the address suggestion object
          final suggestion = AddressSuggestion(
            mainText: event.address,
            secondaryText: event.subAddress,
            latitude: event.latitude,
            longitude: event.longitude,
          );
          
          // Add to recent addresses
          await _addToRecentAddresses(suggestion);
          
          // OPTIMIZATION: Update local cache immediately instead of reloading from API
          final newAddress = SavedAddress(
            addressId: responseData['data']['address_id']?.toString() ?? '',
            userId: userId,
            addressLine1: event.address,
            addressLine2: event.addressName.isNotEmpty ? event.addressName : 'Other',
            city: addressComponents['city'] ?? '',
            state: addressComponents['state'] ?? '',
            postalCode: '1',
            country: addressComponents['country'] ?? 'India',
            isDefault: false,
            latitude: event.latitude,
            longitude: event.longitude,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          // Add to local cache
          _savedAddresses.add(newAddress);
          
          // Clear API cache to ensure fresh data
          _apiCache.clear();
          
          // Emit success state
          emit(AddressSavedSuccessfully(
            address: event.address,
            subAddress: event.subAddress,
            latitude: event.latitude,
            longitude: event.longitude,
            addressName: event.addressName,
            addressId: responseData['data']['address_id']?.toString() ?? '',
          ));
        } else {
          debugPrint('AddressPickerBloc: API returned error: ${responseData['message']}');
          emit(AddressPickerLoadFailure(
            error: responseData['message'] ?? 'Failed to save address'
          ));
        }
      } else {
        debugPrint('AddressPickerBloc: HTTP error ${response.statusCode}');
        emit(AddressPickerLoadFailure(
          error: 'Failed to save address. Please try again.'
        ));
      }
    } catch (e) {
      debugPrint('AddressPickerBloc: Error saving address: $e');
      emit(AddressPickerLoadFailure(error: 'Error saving address. Please try again.'));
    }
  }

  Future<void> _onUseCurrentLocation(
      UseCurrentLocationEvent event, Emitter<AddressPickerState> emit) async {
    try {
      debugPrint('AddressPickerBloc: Using current location');
      emit(LocationDetecting());

      final locationData = await _locationService.getCurrentLocationAndAddress();

      if (locationData != null) {
        debugPrint('AddressPickerBloc: Location detected successfully');
        debugPrint('  Latitude: ${locationData['latitude']}');
        debugPrint('  Longitude: ${locationData['longitude']}');
        debugPrint('  Address: ${locationData['address']}');

        // Parse the full address to get main and secondary parts
        final addressParts = _parseAddress(locationData['address']);
        
        // Emit state to show address name input dialog
        emit(AddressNameInputRequired(
          address: addressParts['main'] ?? '',
          subAddress: addressParts['secondary'] ?? '',
          latitude: locationData['latitude'],
          longitude: locationData['longitude'],
          fullAddress: locationData['address'],
        ));
      } else {
        debugPrint('AddressPickerBloc: Failed to detect location');
        emit(AddressPickerLoadFailure(
            error: 'Could not detect location. Please enable location services.'));
      }
    } catch (e) {
      debugPrint('AddressPickerBloc: Error detecting location: $e');
      emit(AddressPickerLoadFailure(
          error: 'Error detecting location. Please try again.'));
    }
  }

  void _onClearSearch(ClearSearchEvent event, Emitter<AddressPickerState> emit) {
    debugPrint('AddressPickerBloc: Clearing search');
    emit(AddressPickerLoadSuccess(
      suggestions: _recentAddresses,
      searchQuery: '',
      savedAddresses: _savedAddresses,
    ));
  }
  
  void _onCloseAddressPicker(
      CloseAddressPickerEvent event, Emitter<AddressPickerState> emit) {
    debugPrint('AddressPickerBloc: Closing address picker');
    emit(AddressPickerClosed());
  }

  // Helper method to load saved addresses from API with caching
  Future<void> _loadSavedAddressesFromAPI() async {
    try {
      debugPrint('AddressPickerBloc: Loading saved addresses from API');
      
      // Get authentication token and user ID
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('AddressPickerBloc: No authentication token or user ID found');
        _savedAddresses = [];
        return;
      }

      // Check cache first
      final cacheKey = 'saved_addresses_$userId';
      if (_apiCache.containsKey(cacheKey)) {
        final cachedData = _apiCache[cacheKey];
        final cacheTime = cachedData['timestamp'] as DateTime;
        final cacheAge = DateTime.now().difference(cacheTime);
        
        // Use cache if it's less than 2 minutes old
        if (cacheAge.inMinutes < 2) {
          debugPrint('AddressPickerBloc: Using cached saved addresses');
          _savedAddresses = List<SavedAddress>.from(cachedData['data']);
          return;
        }
      }

      // Make API call to get saved addresses
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/user/all-addresses?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
        }),
      );

      debugPrint('AddressPickerBloc: Get addresses API response status: ${response.statusCode}');
      debugPrint('AddressPickerBloc: Get addresses API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == true) {
          final List<dynamic> addressesData = responseData['data'] ?? [];
          
          _savedAddresses = addressesData.map((addressJson) {
            return SavedAddress.fromJson(addressJson);
          }).toList();
          
          // Cache the result
          _apiCache[cacheKey] = {
            'data': _savedAddresses,
            'timestamp': DateTime.now(),
          };
          
          debugPrint('AddressPickerBloc: Loaded ${_savedAddresses.length} saved addresses from API');
        } else {
          debugPrint('AddressPickerBloc: API returned error: ${responseData['message']}');
          _savedAddresses = [];
        }
      } else {
        debugPrint('AddressPickerBloc: HTTP error ${response.statusCode}');
        _savedAddresses = [];
      }
    } catch (e) {
      debugPrint('AddressPickerBloc: Error loading saved addresses from API: $e');
      _savedAddresses = [];
    }
  }

  // Helper method to get address suggestions from Places API with caching
  Future<List<AddressSuggestion>> _getAddressSuggestions(String query) async {
    if (query.isEmpty) return _recentAddresses;

    try {
      debugPrint('AddressPickerBloc: Getting address suggestions for query: $query');
      
      // Check cache first
      final cacheKey = 'address_suggestions_$query';
      if (_apiCache.containsKey(cacheKey)) {
        final cachedData = _apiCache[cacheKey];
        final cacheTime = cachedData['timestamp'] as DateTime;
        final cacheAge = DateTime.now().difference(cacheTime);
        
        // Use cache if it's less than 5 minutes old
        if (cacheAge.inMinutes < 5) {
          debugPrint('AddressPickerBloc: Using cached address suggestions');
          return List<AddressSuggestion>.from(cachedData['data']);
        }
      }
      
      // For India-specific places
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_placesApiKey&components=country:in');

      debugPrint('AddressPickerBloc: Sending request to Places API: ${url.toString()}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('AddressPickerBloc: Places API response received');

        // Check if the API returned successfully
        if (data['status'] == 'OK') {
          final List<dynamic> predictions = data['predictions'];
          debugPrint('AddressPickerBloc: Got ${predictions.length} predictions');
          
          // Convert predictions to suggestion objects
          final suggestions = <AddressSuggestion>[];
          
          for (var prediction in predictions) {
            final mainText = prediction['structured_formatting']['main_text'] ?? '';
            final secondaryText = prediction['structured_formatting']['secondary_text'] ?? '';
            final placeId = prediction['place_id'];
            
            debugPrint('AddressPickerBloc: Processing prediction:');
            debugPrint('  Main text: $mainText');
            debugPrint('  Secondary text: $secondaryText');
            debugPrint('  Place ID: $placeId');
            
            // Get coordinates for this place ID
            Map<String, dynamic>? placeDetails;
            try {
              placeDetails = await _getPlaceDetails(placeId);
            } catch (e) {
              debugPrint('AddressPickerBloc: Error getting place details: $e');
            }
            
            double? latitude;
            double? longitude;
            
            if (placeDetails != null) {
              latitude = placeDetails['latitude'];
              longitude = placeDetails['longitude'];
              debugPrint('AddressPickerBloc: Got coordinates - Lat: $latitude, Lng: $longitude');
            }
            
            suggestions.add(AddressSuggestion(
              mainText: mainText,
              secondaryText: secondaryText,
              placeId: placeId,
              latitude: latitude ?? 0.0,
              longitude: longitude ?? 0.0,
            ));
          }
          
          // Cache the result
          _apiCache[cacheKey] = {
            'data': suggestions,
            'timestamp': DateTime.now(),
          };
          
          return suggestions;
        } else {
          debugPrint('AddressPickerBloc: Places API error: ${data['status']}');
          return [];
        }
      } else {
        debugPrint('AddressPickerBloc: HTTP error ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('AddressPickerBloc: Error fetching address suggestions: $e');
      return [];
    }
  }

  // Helper method to get place details (including coordinates) from Places API with caching
  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    try {
      debugPrint('AddressPickerBloc: Getting place details for place ID: $placeId');
      
      // Check cache first
      final cacheKey = 'place_details_$placeId';
      if (_apiCache.containsKey(cacheKey)) {
        final cachedData = _apiCache[cacheKey];
        final cacheTime = cachedData['timestamp'] as DateTime;
        final cacheAge = DateTime.now().difference(cacheTime);
        
        // Use cache if it's less than 10 minutes old
        if (cacheAge.inMinutes < 10) {
          debugPrint('AddressPickerBloc: Using cached place details');
          return cachedData['data'];
        }
      }
      
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry,formatted_address&key=$_placesApiKey');
          
      debugPrint('AddressPickerBloc: Sending request to Places Details API: ${url.toString()}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('AddressPickerBloc: Place details response received: ${response.statusCode}');

        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          final formattedAddress = data['result']['formatted_address'];
          
          debugPrint('AddressPickerBloc: Got coordinates from Places API:');
          debugPrint('  Latitude: ${location['lat']}');
          debugPrint('  Longitude: ${location['lng']}');
          debugPrint('  Address: $formattedAddress');

          final result = {
            'latitude': location['lat'],
            'longitude': location['lng'],
            'address': formattedAddress,
          };
          
          // Cache the result
          _apiCache[cacheKey] = {
            'data': result,
            'timestamp': DateTime.now(),
          };

          return result;
        } else {
          debugPrint('AddressPickerBloc: Places API error: ${data['status']}');
          return null;
        }
      } else {
        debugPrint('AddressPickerBloc: HTTP error ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('AddressPickerBloc: Error fetching place details: $e');
      return null;
    }
  }
  
  // Helper method to parse address into main and secondary parts
  Map<String, String> _parseAddress(String fullAddress) {
    try {
      debugPrint('AddressPickerBloc: Parsing address: $fullAddress');
      final parts = fullAddress.split(',');
      
      if (parts.length <= 1) {
        debugPrint('AddressPickerBloc: Address has only one part');
        return {
          'main': fullAddress.trim(),
          'secondary': '',
        };
      }
      
      // Take the first part as the main address
      final mainPart = parts[0].trim();
      
      // Join the remaining parts as the secondary address
      final secondaryPart = parts.sublist(1).join(',').trim();
      
      debugPrint('AddressPickerBloc: Parsed address:');
      debugPrint('  Main: $mainPart');
      debugPrint('  Secondary: $secondaryPart');
      
      return {
        'main': mainPart,
        'secondary': secondaryPart,
      };
    } catch (e) {
      debugPrint('AddressPickerBloc: Error parsing address: $e');
      return {
        'main': fullAddress,
        'secondary': '',
      };
    }
  }

  // Helper method to parse address components for API
  Map<String, String> _parseAddressComponents(String fullAddress) {
    try {
      final parts = fullAddress.split(',').map((e) => e.trim()).toList();
      
      // Basic parsing logic - you may need to adjust based on your address format
      String city = '';
      String state = '';
      String postalCode = '';
      String country = 'India';
      
      // Look for postal code (digits)
      for (int i = parts.length - 1; i >= 0; i--) {
        final part = parts[i];
        if (RegExp(r'^\d{6}$').hasMatch(part)) {
          postalCode = part;
          break;
        }
      }
      
      // Look for state and city (this is a simplified approach)
      if (parts.length >= 2) {
        state = parts[parts.length - 2];
        if (parts.length >= 3) {
          city = parts[parts.length - 3];
        }
      }
      
      return {
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'country': country,
      };
    } catch (e) {
      debugPrint('AddressPickerBloc: Error parsing address components: $e');
      return {
        'city': '',
        'state': '',
        'postalCode': '',
        'country': 'India',
      };
    }
  }
  
  // Load recent addresses from SharedPreferences
  Future<void> _loadRecentAddresses() async {
    try {
      debugPrint('AddressPickerBloc: Loading recent addresses from SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      final recentAddressesJson = prefs.getStringList('recent_addresses') ?? [];
      
      debugPrint('AddressPickerBloc: Found ${recentAddressesJson.length} saved addresses');
      
      _recentAddresses = recentAddressesJson.map((json) {
        final data = jsonDecode(json);
        return AddressSuggestion(
          mainText: data['mainText'],
          secondaryText: data['secondaryText'],
          latitude: data['latitude'],
          longitude: data['longitude'],
        );
      }).toList();
    } catch (e) {
      debugPrint('AddressPickerBloc: Error loading recent addresses: $e');
      _recentAddresses = [];
    }
  }
  
  // Add an address to recent addresses and save to SharedPreferences
  Future<void> _addToRecentAddresses(AddressSuggestion suggestion) async {
    try {
      debugPrint('AddressPickerBloc: Adding address to recent list: ${suggestion.mainText}');
      
      // Remove if already exists to avoid duplicates
      _recentAddresses.removeWhere((addr) => 
          addr.mainText == suggestion.mainText && 
          addr.secondaryText == suggestion.secondaryText);
      
      // Add to the beginning of the list
      _recentAddresses.insert(0, suggestion);
      
      // Keep only the most recent 10 addresses
      if (_recentAddresses.length > 10) {
        _recentAddresses = _recentAddresses.sublist(0, 10);
      }
      
      debugPrint('AddressPickerBloc: Saving ${_recentAddresses.length} recent addresses');
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final recentAddressesJson = _recentAddresses.map((addr) => 
          jsonEncode({
            'mainText': addr.mainText,
            'secondaryText': addr.secondaryText,
            'latitude': addr.latitude,
            'longitude': addr.longitude,
          })
      ).toList();
      
      await prefs.setStringList('recent_addresses', recentAddressesJson);
      debugPrint('AddressPickerBloc: Recent addresses saved successfully');
    } catch (e) {
      debugPrint('AddressPickerBloc: Error saving recent addresses: $e');
    }
  }
  
  @override
  Future<void> close() {
    debugPrint('AddressPickerBloc: Closing and cleaning up resources');
    _debounce?.cancel();
    _cacheCleanupTimer?.cancel();
    return super.close();
  }
}