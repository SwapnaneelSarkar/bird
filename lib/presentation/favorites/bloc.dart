import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../service/favorites_service.dart';
import '../../models/favorite_model.dart';
import 'event.dart';
import 'state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc() : super(FavoritesInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<ToggleFavorite>(_onToggleFavorite);
    on<RefreshFavorites>(_onRefreshFavorites);
    on<CheckFavoriteStatus>(_onCheckFavoriteStatus);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
    on<ClearAllFavorites>(_onClearAllFavorites);
  }

  Future<void> _onLoadFavorites(LoadFavorites event, Emitter<FavoritesState> emit) async {
    try {
      emit(FavoritesLoading());
      
      final favoritesData = await FavoritesService.getFavorites();
      
      if (favoritesData == null) {
        emit(const FavoritesError(message: 'Failed to load favorites'));
        return;
      }

      if (favoritesData.isEmpty) {
        emit(const FavoritesEmpty(message: 'No favorites yet. Tap the heart icon on any restaurant to add it to your favorites!'));
        return;
      }

      final favorites = favoritesData.map((json) => FavoriteModel.fromJson(json)).toList();
      emit(FavoritesLoaded(favorites: favorites, totalCount: favorites.length));
      
    } catch (e) {
      debugPrint('FavoritesBloc: Error loading favorites: $e');
      emit(FavoritesError(message: 'Failed to load favorites: $e'));
    }
  }

  Future<void> _onToggleFavorite(ToggleFavorite event, Emitter<FavoritesState> emit) async {
    try {
      emit(FavoriteToggling(
        partnerId: event.partnerId,
        isAdding: !event.isCurrentlyFavorite,
      ));

      final result = await FavoritesService.toggleFavorite(event.partnerId);
      
      if (result == null) {
        emit(FavoriteToggleError(
          partnerId: event.partnerId,
          message: 'Failed to toggle favorite',
        ));
        return;
      }

      // Reload favorites to get updated list
      final favoritesData = await FavoritesService.getFavorites();
      
      if (favoritesData == null) {
        emit(FavoriteToggleError(
          partnerId: event.partnerId,
          message: 'Failed to refresh favorites list',
        ));
        return;
      }

      final updatedFavorites = favoritesData.map((json) => FavoriteModel.fromJson(json)).toList();
      
      emit(FavoriteToggled(
        partnerId: event.partnerId,
        isNowFavorite: !event.isCurrentlyFavorite,
        updatedFavorites: updatedFavorites,
      ));

    } catch (e) {
      debugPrint('FavoritesBloc: Error toggling favorite: $e');
      emit(FavoriteToggleError(
        partnerId: event.partnerId,
        message: 'Failed to toggle favorite: $e',
      ));
    }
  }

  Future<void> _onRefreshFavorites(RefreshFavorites event, Emitter<FavoritesState> emit) async {
    try {
      emit(FavoritesLoading());
      
      final favoritesData = await FavoritesService.getFavorites();
      
      if (favoritesData == null) {
        emit(const FavoritesError(message: 'Failed to refresh favorites'));
        return;
      }

      if (favoritesData.isEmpty) {
        emit(const FavoritesEmpty(message: 'No favorites yet. Tap the heart icon on any restaurant to add it to your favorites!'));
        return;
      }

      final favorites = favoritesData.map((json) => FavoriteModel.fromJson(json)).toList();
      emit(FavoritesLoaded(favorites: favorites, totalCount: favorites.length));
      
    } catch (e) {
      debugPrint('FavoritesBloc: Error refreshing favorites: $e');
      emit(FavoritesError(message: 'Failed to refresh favorites: $e'));
    }
  }

  Future<void> _onCheckFavoriteStatus(CheckFavoriteStatus event, Emitter<FavoritesState> emit) async {
    try {
      final isFavorite = await FavoritesService.checkFavoriteStatus(event.partnerId);
      
      if (isFavorite == null) {
        debugPrint('FavoritesBloc: Failed to check favorite status for ${event.partnerId}');
        return;
      }

      debugPrint('FavoritesBloc: Favorite status for ${event.partnerId}: $isFavorite');
      
    } catch (e) {
      debugPrint('FavoritesBloc: Error checking favorite status: $e');
    }
  }

  Future<void> _onRemoveFromFavorites(RemoveFromFavorites event, Emitter<FavoritesState> emit) async {
    try {
      emit(FavoriteToggling(
        partnerId: event.partnerId,
        isAdding: false,
      ));

      final result = await FavoritesService.removeFromFavorites(event.partnerId);
      
      if (result == null) {
        emit(FavoriteToggleError(
          partnerId: event.partnerId,
          message: 'Failed to remove from favorites',
        ));
        return;
      }

      // Reload favorites to get updated list
      final favoritesData = await FavoritesService.getFavorites();
      
      if (favoritesData == null) {
        emit(FavoriteToggleError(
          partnerId: event.partnerId,
          message: 'Failed to refresh favorites list',
        ));
        return;
      }

      final updatedFavorites = favoritesData.map((json) => FavoriteModel.fromJson(json)).toList();
      
      if (updatedFavorites.isEmpty) {
        emit(const FavoritesEmpty(message: 'No favorites yet. Tap the heart icon on any restaurant to add it to your favorites!'));
      } else {
        emit(FavoriteToggled(
          partnerId: event.partnerId,
          isNowFavorite: false,
          updatedFavorites: updatedFavorites,
        ));
      }

    } catch (e) {
      debugPrint('FavoritesBloc: Error removing from favorites: $e');
      emit(FavoriteToggleError(
        partnerId: event.partnerId,
        message: 'Failed to remove from favorites: $e',
      ));
    }
  }

  Future<void> _onClearAllFavorites(ClearAllFavorites event, Emitter<FavoritesState> emit) async {
    try {
      emit(FavoritesLoading());

      // Get current favorites list
      final favoritesData = await FavoritesService.getFavorites();
      
      if (favoritesData == null || favoritesData.isEmpty) {
        emit(const FavoritesEmpty(message: 'No favorites yet. Tap the heart icon on any restaurant to add it to your favorites!'));
        return;
      }

      final favorites = favoritesData.map((json) => FavoriteModel.fromJson(json)).toList();
      
      // Remove each favorite one by one
      for (final favorite in favorites) {
        await FavoritesService.removeFromFavorites(favorite.partnerId);
      }

      // Show empty state after clearing all
      emit(const FavoritesEmpty(message: 'All favorites cleared. Tap the heart icon on any restaurant to add it to your favorites!'));
      
    } catch (e) {
      debugPrint('FavoritesBloc: Error clearing all favorites: $e');
      emit(FavoritesError(message: 'Failed to clear all favorites: $e'));
    }
  }
}