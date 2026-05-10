import 'package:flutter/material.dart';
import 'package:polaris/features/spots/models/spot.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';

extension SpotCategoryX on SpotCategory {
  String label(AppLocalizations l) {
    switch (this) {
      case SpotCategory.food:
        return l.categoryFood;
      case SpotCategory.entertainment:
        return l.categoryEntertainment;
      case SpotCategory.sightseeing:
        return l.categorySightseeing;
      case SpotCategory.shopping:
        return l.categoryShopping;
      case SpotCategory.lodging:
        return l.categoryLodging;
      case SpotCategory.other:
        return l.categoryOther;
    }
  }

  IconData get icon {
    switch (this) {
      case SpotCategory.food:
        return Icons.restaurant;
      case SpotCategory.entertainment:
        return Icons.celebration;
      case SpotCategory.sightseeing:
        return Icons.photo_camera;
      case SpotCategory.shopping:
        return Icons.shopping_bag_outlined;
      case SpotCategory.lodging:
        return Icons.hotel;
      case SpotCategory.other:
        return Icons.place_outlined;
    }
  }

  Color get color {
    switch (this) {
      case SpotCategory.food:
        return const Color(0xFFEF6C00);
      case SpotCategory.entertainment:
        return const Color(0xFFAB47BC);
      case SpotCategory.sightseeing:
        return const Color(0xFF26A69A);
      case SpotCategory.shopping:
        return const Color(0xFFEC407A);
      case SpotCategory.lodging:
        return const Color(0xFF5C6BC0);
      case SpotCategory.other:
        return const Color(0xFF78909C);
    }
  }
}
