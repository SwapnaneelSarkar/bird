// lib/presentation/category_homepage/event.dart
import 'package:equatable/equatable.dart';

abstract class CategoryHomepageEvent extends Equatable {
  const CategoryHomepageEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategoryHomepage extends CategoryHomepageEvent {
  const LoadCategoryHomepage();
}

class RefreshCategoryHomepage extends CategoryHomepageEvent {
  const RefreshCategoryHomepage();
}

class SelectCategory extends CategoryHomepageEvent {
  final String categoryId;
  final String categoryName;

  const SelectCategory({
    required this.categoryId,
    required this.categoryName,
  });

  @override
  List<Object?> get props => [categoryId, categoryName];
}


