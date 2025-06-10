// lib/presentation/screens/search/event.dart
import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchInitialEvent extends SearchEvent {
  final double? latitude;
  final double? longitude;

  const SearchInitialEvent({
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

class SearchQueryChangedEvent extends SearchEvent {
  final String query;
  final double? latitude;
  final double? longitude;
  final double radius;

  const SearchQueryChangedEvent({
    required this.query,
    this.latitude,
    this.longitude,
    this.radius = 5.0,
  });

  @override
  List<Object?> get props => [query, latitude, longitude, radius];
}

class SearchClearEvent extends SearchEvent {}