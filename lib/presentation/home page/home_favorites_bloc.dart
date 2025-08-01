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
      // Skip if we already checked this restaurant recently
      if (_checkedRestaurants.contains(event.partnerId)) {
        return;
      }

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

  // Helper method to get cached favorite status
  bool? getCachedFavoriteStatus(String partnerId) {
    return _favoriteStatusCache[partnerId];
  }
} 