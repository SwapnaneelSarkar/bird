import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../service/location_services.dart';
import 'event.dart';
import 'state.dart';

class AddressPickerBloc extends Bloc<AddressPickerEvent, AddressPickerState> {
  final LocationService _locationService = LocationService();
  final String _placesApiKey = 'AIzaSyBmRJ1-tX0oWD3FFKAuV8NB7Hg9h6NQXeU';
  
  // For caching recent addresses
  List<AddressSuggestion> _recentAddresses = [];
  
  // Debounce for search
  Timer? _debounce;

  AddressPickerBloc() : super(AddressPickerInitial()) {
    on<InitializeAddressPickerEvent>(_onInitialize);
    on<SearchAddressEvent>(_onSearchAddress);
    on<SelectAddressEvent>(_onSelectAddress);
    on<UseCurrentLocationEvent>(_onUseCurrentLocation);
    on<ClearSearchEvent>(_onClearSearch);
    on<CloseAddressPickerEvent>(_onCloseAddressPicker);
  }

  Future<void> _onInitialize(
      InitializeAddressPickerEvent event, Emitter<AddressPickerState> emit) async {
    try {
      debugPrint('AddressPickerBloc: Initializing address picker');
      
      // Load recent addresses from SharedPreferences
      await _loadRecentAddresses();
      
      // Emit initial state with recent addresses
      emit(AddressPickerLoadSuccess(
        suggestions: _recentAddresses,
      ));
      
      debugPrint('AddressPickerBloc: Initialized with ${_recentAddresses.length} recent addresses');
    } catch (e) {
      debugPrint('AddressPickerBloc: Error initializing address picker: $e');
      emit(AddressPickerLoadFailure(error: 'Failed to initialize address picker'));
    }
  }

  Future<void> _onSearchAddress(
    SearchAddressEvent event, Emitter<AddressPickerState> emit) async {
    // Cancel any previous debounce timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // If search query is empty, show recent addresses
    if (event.query.isEmpty) {
      debugPrint('AddressPickerBloc: Empty query, showing recent addresses');
      emit(AddressPickerLoadSuccess(
        suggestions: _recentAddresses,
        searchQuery: '',
      ));
      return;
    }

    // Show loading state immediately
    emit(AddressPickerLoading());
    debugPrint('AddressPickerBloc: Searching for address: ${event.query}');

    // Create a completer to properly handle the debounce
    final completer = Completer();
    
    // Set a debounce to avoid too many API calls
    _debounce = Timer(const Duration(milliseconds: 500), () {
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
      debugPrint('AddressPickerBloc: Address selected:');
      debugPrint('  Main text: ${event.address}');
      debugPrint('  Secondary text: ${event.subAddress}');
      debugPrint('  Latitude: ${event.latitude}');
      debugPrint('  Longitude: ${event.longitude}');
      
      // Create the address suggestion object
      final suggestion = AddressSuggestion(
        mainText: event.address,
        secondaryText: event.subAddress,
        latitude: event.latitude,
        longitude: event.longitude,
      );
      
      // Add to recent addresses if not already present
      await _addToRecentAddresses(suggestion);
      
      // Emit the selected address state
      emit(AddressSelected(
        address: event.address,
        subAddress: event.subAddress,
        latitude: event.latitude,
        longitude: event.longitude,
      ));
    } catch (e) {
      debugPrint('AddressPickerBloc: Error selecting address: $e');
      emit(AddressPickerLoadFailure(error: 'Failed to select address'));
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
        
        // Create address suggestion and add to recent addresses
        final suggestion = AddressSuggestion(
          mainText: addressParts['main'] ?? '',
          secondaryText: addressParts['secondary'] ?? '',
          latitude: locationData['latitude'],
          longitude: locationData['longitude'],
        );
        
        // Add to recent addresses
        await _addToRecentAddresses(suggestion);

        emit(LocationDetected(
          address: addressParts['main'] ?? '',
          subAddress: addressParts['secondary'] ?? '',
          latitude: locationData['latitude'],
          longitude: locationData['longitude'],
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
    ));
  }
  
  void _onCloseAddressPicker(
      CloseAddressPickerEvent event, Emitter<AddressPickerState> emit) {
    debugPrint('AddressPickerBloc: Closing address picker');
    emit(AddressPickerClosed());
  }

  // Helper method to get address suggestions from Places API
  Future<List<AddressSuggestion>> _getAddressSuggestions(String query) async {
    if (query.isEmpty) return _recentAddresses;

    try {
      debugPrint('AddressPickerBloc: Getting address suggestions for query: $query');
      
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

  // Helper method to get place details (including coordinates) from Places API
  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    try {
      debugPrint('AddressPickerBloc: Getting place details for place ID: $placeId');
      
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

          return {
            'latitude': location['lat'],
            'longitude': location['lng'],
            'address': formattedAddress,
          };
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
  
  // Helper to fetch coordinates for place ID
  Future<AddressSuggestion> _getCoordinatesForSuggestion(AddressSuggestion suggestion) async {
    if (suggestion.latitude != null && suggestion.longitude != null && 
        suggestion.latitude != 0.0 && suggestion.longitude != 0.0) {
      debugPrint('AddressPickerBloc: Suggestion already has coordinates');
      return suggestion;
    }
    
    if (suggestion.placeId == null) {
      debugPrint('AddressPickerBloc: Cannot get coordinates without place ID');
      return suggestion; // Can't get coordinates without place ID
    }
    
    try {
      debugPrint('AddressPickerBloc: Getting coordinates for suggestion: ${suggestion.mainText}');
      final details = await _getPlaceDetails(suggestion.placeId!);
      if (details != null) {
        debugPrint('AddressPickerBloc: Found coordinates for suggestion');
        return AddressSuggestion(
          mainText: suggestion.mainText,
          secondaryText: suggestion.secondaryText,
          latitude: details['latitude'],
          longitude: details['longitude'],
          placeId: suggestion.placeId,
        );
      }
    } catch (e) {
      debugPrint('AddressPickerBloc: Error getting coordinates for place: $e');
    }
    
    return suggestion;
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
    return super.close();
  }
}