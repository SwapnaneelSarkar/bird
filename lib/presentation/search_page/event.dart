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
  final String? supercategoryId; // Add supercategoryId parameter

  const SearchQueryChangedEvent({
    required this.query,
    this.latitude,
    this.longitude,
    this.radius = 25.0,
    this.supercategoryId, // Add supercategoryId parameter
  });

  @override
  List<Object?> get props => [query, latitude, longitude, radius, supercategoryId];
}

class SearchClearEvent extends SearchEvent {}