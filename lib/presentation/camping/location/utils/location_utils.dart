import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import 'package:to_camp/core/provider/marker_icon_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';
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

  static List<Marker> createMarkers({
    required List<CampingModel> totalModels,
    required List<LikeCategoryModel> wishlist,
    required List<Uint8List> markerIcons,
    required String? selectedId,
    required Function(CampingModel model) onTap,
  }) {
    if (markerIcons.isEmpty) return [];

    final icons = markerIcons
        .map(BitmapDescriptor.fromBytes)
        .toList();
    return List.generate(totalModels.length, (index) {
      final model = totalModels[index];
      final isLiked = WishlistUtils.checkIsLiked(wishlist, model);
      final selected = model.id == selectedId;
      final icon = switch ((selected, isLiked)) {
        (true, true) => CampingMarkerIcon.likedTent,
        (true, false) => CampingMarkerIcon.tent,
        (false, true) => CampingMarkerIcon.likedDot,
        (false, false) => CampingMarkerIcon.dot,
      };
      return Marker(
        markerId: MarkerId(model.id),
        icon: icons[icon.index],
        anchor: selected
            ? const Offset(0.5, 1)
            : const Offset(0.5, 0.5),

        position: LatLng(model.lat, model.lng),
        onTap: () => onTap(model),

        consumeTapEvents: true,
        infoWindow: InfoWindow(
          title: model.name,
          snippet: model.address,
        ),
      );
    });
  }
}
