import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_camp/core/const/data.dart';
import 'package:to_camp/core/utils/platform_utils.dart';
import 'package:flutter_riverpod/legacy.dart';

enum CampingMarkerIcon {
  tent(MARKER),
  likedTent(MARKER_PINK),
  dot('asset/img/marker_dot.png'),
  likedDot('asset/img/marker_dot_pink.png');

  const CampingMarkerIcon(this.asset);
  final String asset;
}

final markerIconProvider =
    StateNotifierProvider<MarkerIconProvider, List<Uint8List>>(
      (ref) => MarkerIconProvider(),
    );

class MarkerIconProvider extends StateNotifier<List<Uint8List>> {
  MarkerIconProvider() : super([]) {
    setMarkerIcon();
  }

  void setMarkerIcon() async {
    try {
      final width = PlatformUtils.setMarkerSize();
      state = await Future.wait(
        CampingMarkerIcon.values.map(
          (icon) => getBytesFromAsset(icon.asset, width),
        ),
      );
    } catch (e) {
      state = [];
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);

    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
      allowUpscaling: false,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }
}
