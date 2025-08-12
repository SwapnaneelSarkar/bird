import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../service/favorites_service.dart';

// Events
abstract class HomeFavoritesEvent {}

class ToggleHomeFavorite extends HomeFavoritesEvent {
  final String partnerId;
  final bool isCurrentlyFavorite;

  ToggleHomeFavorite({
    required this.partnerId,
    required this.isCurrentlyFavorite,
  });
}

class CheckHomeFavoriteStatus extends HomeFavoritesEvent {
  final String partnerId;

  CheckHomeFavoriteStatus({required this.partnerId});
}

// New event to check and toggle in one operation
class CheckAndToggleHomeFavorite extends HomeFavoritesEvent {
  final String partnerId;

  CheckAndToggleHomeFavorite({required this.partnerId});
}

// Add this new event to refresh cache
class RefreshHomeFavoriteCache extends HomeFavoritesEvent {}

// States
abstract class HomeFavoritesState {}

class HomeFavoritesInitial extends HomeFavoritesState {}

class HomeFavoriteToggling extends HomeFavoritesState {
  final String partnerId;
  final bool isAdding;

  HomeFavoriteToggling({
    required this.partnerId,
    required this.isAdding,
  });
}

class HomeFavoriteToggled extends HomeFavoritesState {
  final String partnerId;
  final bool isNowFavorite;

  HomeFavoriteToggled({
    required this.partnerId,
    required this.isNowFavorite,
  });
}

class HomeFavoriteToggleError extends HomeFavoritesState {
  final String partnerId;
  final String message;

  HomeFavoriteToggleError({
    required this.partnerId,
    required this.message,
  });
}

class HomeFavoriteStatusChecked extends HomeFavoritesState {
  final String partnerId;
  final bool isFavorite;

  HomeFavoriteStatusChecked({
    required this.partnerId,
    required this.isFavorite,
  });
}

// Bloc
class HomeFavoritesBloc extends Bloc<HomeFavoritesEvent, HomeFavoritesState> {
  // Cache to store favorite status and avoid repeated API calls
  final Map<String, bool> _favoriteStatusCache = {};
  final Set<String> _checkedRestaurants = {};
  final Set<String> _checkingRestaurants = {}; // Track restaurants being checked

  HomeFavoritesBloc() : super(HomeFavoritesInitial()) {
    on<ToggleHomeFavorite>(_onToggleHomeFavorite);
    on<CheckHomeFavoriteStatus>(_onCheckHomeFavoriteStatus);
    on<CheckAndToggleHomeFavorite>(_onCheckAndToggleHomeFavorite);
    on<RefreshHomeFavoriteCache>(_onRefreshHomeFavoriteCache);
  }

  Future<void> _onToggleHomeFavorite(ToggleHomeFavorite event, Emitter<HomeFavoritesState> emit) async {
    try {
      emit(HomeFavoriteToggling(
        partnerId: event.partnerId,
        isAdding: !event.isCurrentlyFavorite,
      ));

      final result = await FavoritesService.toggleFavorite(event.partnerId);
      
      if (result == null) {
        emit(HomeFavoriteToggleError(
          partnerId: event.partnerId,
          message: 'Failed to toggle favorite',
        ));
        return;
      }

      // Update cache immediately for instant UI feedback
      final newStatus = !event.isCurrentlyFavorite;
      _favoriteStatusCache[event.partnerId] = newStatus;
      _checkedRestaurants.add(event.partnerId);

      emit(HomeFavoriteToggled(
        partnerId: event.partnerId,
        isNowFavorite: newStatus,
      ));

    } catch (e) {
      debugPrint('HomeFavoritesBloc: Error toggling favorite: $e');
      emit(HomeFavoriteToggleError(
        partnerId: event.partnerId,
        message: 'Failed to toggle favorite: $e',
      ));
    }
  }

  Future<void> _onCheckHomeFavoriteStatus(CheckHomeFavoriteStatus event, Emitter<HomeFavoritesState> emit) async {
    try {
      // Prevent multiple simultaneous checks for the same restaurant
      if (_checkingRestaurants.contains(event.partnerId)) {
        debugPrint('HomeFavoritesBloc: Already checking status for ${event.partnerId}');
        return;
      }

      // Return cached result if already checked
      if (_checkedRestaurants.contains(event.partnerId)) {
        final cachedStatus = _favoriteStatusCache[event.partnerId];
        if (cachedStatus != null) {
          emit(HomeFavoriteStatusChecked(
            partnerId: event.partnerId,
            isFavorite: cachedStatus,
          ));
        }
        return;
      }

      // Mark as checking to prevent duplicate requests
      _checkingRestaurants.add(event.partnerId);

      // Check status from server
      final isFavorite = await FavoritesService.checkFavoriteStatus(event.partnerId);
      
      // Remove from checking set
      _checkingRestaurants.remove(event.partnerId);
      
      if (isFavorite != null) {
        // Cache the result
        _favoriteStatusCache[event.partnerId] = isFavorite;
        _checkedRestaurants.add(event.partnerId);
        
        emit(HomeFavoriteStatusChecked(
          partnerId: event.partnerId,
          isFavorite: isFavorite,
        ));
      }
    } catch (e) {
      // Remove from checking set on error
      _checkingRestaurants.remove(event.partnerId);
      debugPrint('HomeFavoritesBloc: Error checking favorite status: $e');
    }
  }

  Future<void> _onCheckAndToggleHomeFavorite(CheckAndToggleHomeFavorite event, Emitter<HomeFavoritesState> emit) async {
    try {
      // Prevent multiple simultaneous operations for the same restaurant
      if (_checkingRestaurants.contains(event.partnerId)) {
        debugPrint('HomeFavoritesBloc: Already processing ${event.partnerId}');
        return;
      }

      // Mark as checking to prevent duplicate requests
      _checkingRestaurants.add(event.partnerId);

      // Check current status first
      bool currentStatus = false;
      if (_checkedRestaurants.contains(event.partnerId)) {
        currentStatus = _favoriteStatusCache[event.partnerId] ?? false;
      } else {
        final isFavorite = await FavoritesService.checkFavoriteStatus(event.partnerId);
        if (isFavorite != null) {
          currentStatus = isFavorite;
          _favoriteStatusCache[event.partnerId] = currentStatus;
          _checkedRestaurants.add(event.partnerId);
        }
      }

      // Emit toggling state
      emit(HomeFavoriteToggling(
        partnerId: event.partnerId,
        isAdding: !currentStatus,
      ));

      // Toggle the favorite
      final result = await FavoritesService.toggleFavorite(event.partnerId);
      
      // Remove from checking set
      _checkingRestaurants.remove(event.partnerId);
      
      if (result == null) {
        emit(HomeFavoriteToggleError(
          partnerId: event.partnerId,
          message: 'Failed to toggle favorite',
        ));
        return;
      }

      // Update cache with new status
      final newStatus = !currentStatus;
      _favoriteStatusCache[event.partnerId] = newStatus;
      _checkedRestaurants.add(event.partnerId);

      emit(HomeFavoriteToggled(
        partnerId: event.partnerId,
        isNowFavorite: newStatus,
      ));

    } catch (e) {
      // Remove from checking set on error
      _checkingRestaurants.remove(event.partnerId);
      debugPrint('HomeFavoritesBloc: Error in check and toggle: $e');
      emit(HomeFavoriteToggleError(
        partnerId: event.partnerId,
        message: 'Failed to toggle favorite: $e',
      ));
    }
  }

  void _onRefreshHomeFavoriteCache(RefreshHomeFavoriteCache event, Emitter<HomeFavoritesState> emit) {
    // Clear all cache when favorites are updated from other screens
    _favoriteStatusCache.clear();
    _checkedRestaurants.clear();
    _checkingRestaurants.clear();
  }

  // Helper method to get cached favorite status
  bool? getCachedFavoriteStatus(String partnerId) {
    return _favoriteStatusCache[partnerId];
  }

  // Helper method to check if a restaurant has been checked
  bool hasCheckedRestaurant(String partnerId) {
    return _checkedRestaurants.contains(partnerId);
  }

  // Helper method to check if a restaurant is currently being checked
  bool isCheckingRestaurant(String partnerId) {
    return _checkingRestaurants.contains(partnerId);
  }
}