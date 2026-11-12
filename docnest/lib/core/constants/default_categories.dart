import 'package:flutter/material.dart';

class DefaultCategory {
  const DefaultCategory({required this.name, required this.icon});

  final String name;
  final IconData icon;
}

/// Default categories from blueprint section 16.
const defaultCategories = <DefaultCategory>[
  DefaultCategory(name: 'Identity & Travel', icon: Icons.badge_rounded),
  DefaultCategory(name: 'Education', icon: Icons.school_rounded),
  DefaultCategory(name: 'Finance', icon: Icons.account_balance_rounded),
  DefaultCategory(name: 'Health', icon: Icons.health_and_safety_rounded),
  DefaultCategory(name: 'Vehicle', icon: Icons.directions_car_rounded),
  DefaultCategory(name: 'Home & Property', icon: Icons.home_work_rounded),
  DefaultCategory(name: 'Bills', icon: Icons.receipt_long_rounded),
  DefaultCategory(name: 'Warranty & Purchases', icon: Icons.verified_rounded),
  DefaultCategory(name: 'Work & Employment', icon: Icons.work_rounded),
  DefaultCategory(name: 'Insurance', icon: Icons.shield_rounded),
  DefaultCategory(name: 'Other', icon: Icons.folder_open_rounded),
];

/// Categories shown on the home dashboard (blueprint section 11).
const homeFeaturedCategoryNames = <String>{
  'Identity & Travel',
  'Education',
  'Finance',
  'Health',
  'Vehicle',
  'Home & Property',
  'Bills',
  'Insurance',
};

/// Stable id of the built-in folder for a default category. The same id is used
/// when the folder is seeded and when the home grid counts its documents.
String builtInFolderId(String categoryName) {
  final slug = categoryName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return 'builtin-$slug';
}
