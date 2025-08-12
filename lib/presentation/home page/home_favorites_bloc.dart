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

  HomeFavoritesBloc() : super(HomeFavoritesInitial()) {
    on<ToggleHomeFavorite>(_onToggleHomeFavorite);
    on<CheckHomeFavoriteStatus>(_onCheckHomeFavoriteStatus);
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

      // Clear cache for all other restaurants to ensure fresh data on next check
      _clearCacheExcept(event.partnerId);

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
      // Always check status from server for accurate data
      final isFavorite = await FavoritesService.checkFavoriteStatus(event.partnerId);
      
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
      debugPrint('HomeFavoritesBloc: Error checking favorite status: $e');
    }
  }

  void _onRefreshHomeFavoriteCache(RefreshHomeFavoriteCache event, Emitter<HomeFavoritesState> emit) {
    // Clear all cache when favorites are updated from other screens
    _favoriteStatusCache.clear();
    _checkedRestaurants.clear();
  }

  // Helper method to clear cache except for specified partnerId
  void _clearCacheExcept(String exceptPartnerId) {
    final currentValue = _favoriteStatusCache[exceptPartnerId];
    _favoriteStatusCache.clear();
    _checkedRestaurants.clear();
    if (currentValue != null) {
      _favoriteStatusCache[exceptPartnerId] = currentValue;
      _checkedRestaurants.add(exceptPartnerId);
    }
  }

  // Helper method to get cached favorite status
  bool? getCachedFavoriteStatus(String partnerId) {
    return _favoriteStatusCache[partnerId];
  }
}