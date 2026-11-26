import 'dart:ui' show Size;
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:to_camp/core/provider/marker_icon_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:to_camp/data/models/camping_model.dart';
import 'package:to_camp/data/models/like_category_model.dart';
import 'package:to_camp/presentation/camping/wishlist/utils/wishlist_utils.dart';

class LocationUtils {
  static double radiusByZoom(double zoom) {
    if (zoom > 12.0) {
      return 15000;
    } else if (zoom > 9.0) {
      return 20000;
    } else {
      return 50000;
    }
  }

  static List<CampingModel> sortByDistance(
    List<CampingModel> models,
    double lat,
    double lng,
  ) {
    models.sort((a, b) {
      final distanceA = Geolocator.distanceBetween(
        lat,
        lng,
        a.lat,
        a.lng,
      );
      final distanceB = Geolocator.distanceBetween(
        lat,
        lng,
        b.lat,
        b.lng,
      );

      return distanceA.compareTo(distanceB);
    });
    return models;
  }

  static List<NMarker> createMarkers({
    required List<CampingModel> totalModels,
    required List<LikeCategoryModel> wishlist,
    required String? selectedId,
  }) {
    final likedIds = WishlistUtils.extractCampingList(
      wishlist,
    ).map((model) => model.id).toSet();
    return totalModels.map((model) {
      final isLiked = likedIds.contains(model.id);
      final selected = model.id == selectedId;
      final icon = switch ((selected, isLiked)) {
        (true, true) => CampingMarkerIcon.likedTent,
        (true, false) => CampingMarkerIcon.tent,
        (false, true) => CampingMarkerIcon.likedDot,
        (false, false) => CampingMarkerIcon.dot,
      };
      return NMarker(
        id: model.id,
        position: NLatLng(model.lat, model.lng),
        icon: icon.image,
        anchor: selected
            ? const NPoint(0.5, 1)
            : const NPoint(0.5, 0.5),
        size: selected ? const Size(36, 42) : const Size.square(36),
      )..setZIndex(selected ? 1 : 0);
    }).toList();
  }
}
