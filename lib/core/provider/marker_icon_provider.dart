import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:to_camp/core/const/data.dart';

enum CampingMarkerIcon {
  tent(NOverlayImage.fromAssetImage(MARKER)),
  likedTent(NOverlayImage.fromAssetImage(MARKER_PINK)),
  dot(NOverlayImage.fromAssetImage('asset/img/marker_dot.png')),
  likedDot(
    NOverlayImage.fromAssetImage('asset/img/marker_dot_pink.png'),
  );

  const CampingMarkerIcon(this.image);
  final NOverlayImage image;
}
