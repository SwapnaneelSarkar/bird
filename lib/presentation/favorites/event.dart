import 'package:equatable/equatable.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

class LoadFavorites extends FavoritesEvent {
  const LoadFavorites();
}

class ToggleFavorite extends FavoritesEvent {
  final String partnerId;
  final bool isCurrentlyFavorite;

  const ToggleFavorite({
    required this.partnerId,
    required this.isCurrentlyFavorite,
  });

  @override
  List<Object?> get props => [partnerId, isCurrentlyFavorite];
}

class RefreshFavorites extends FavoritesEvent {
  const RefreshFavorites();
}

class CheckFavoriteStatus extends FavoritesEvent {
  final String partnerId;

  const CheckFavoriteStatus({required this.partnerId});

  @override
  List<Object?> get props => [partnerId];
}

class RemoveFromFavorites extends FavoritesEvent {
  final String partnerId;

  const RemoveFromFavorites({required this.partnerId});

  @override
  List<Object?> get props => [partnerId];
}

class ClearAllFavorites extends FavoritesEvent {
  const ClearAllFavorites();
}