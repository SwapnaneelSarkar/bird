import 'package:equatable/equatable.dart';
import '../../models/favorite_model.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<FavoriteModel> favorites;
  final int totalCount;

  const FavoritesLoaded({
    required this.favorites,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [favorites, totalCount];

  FavoritesLoaded copyWith({
    List<FavoriteModel>? favorites,
    int? totalCount,
  }) {
    return FavoritesLoaded(
      favorites: favorites ?? this.favorites,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class FavoritesEmpty extends FavoritesState {
  final String message;

  const FavoritesEmpty({this.message = 'No favorite restaurants found'});

  @override
  List<Object?> get props => [message];
}

class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError({required this.message});

  @override
  List<Object?> get props => [message];
}

class FavoriteToggling extends FavoritesState {
  final String partnerId;
  final bool isAdding;

  const FavoriteToggling({
    required this.partnerId,
    required this.isAdding,
  });

  @override
  List<Object?> get props => [partnerId, isAdding];
}

class FavoriteToggled extends FavoritesState {
  final String partnerId;
  final bool isNowFavorite;
  final List<FavoriteModel> updatedFavorites;

  const FavoriteToggled({
    required this.partnerId,
    required this.isNowFavorite,
    required this.updatedFavorites,
  });

  @override
  List<Object?> get props => [partnerId, isNowFavorite, updatedFavorites];
}

class FavoriteToggleError extends FavoritesState {
  final String partnerId;
  final String message;

  const FavoriteToggleError({
    required this.partnerId,
    required this.message,
  });

  @override
  List<Object?> get props => [partnerId, message];
} 