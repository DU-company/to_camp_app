import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_camp/core/theme/service/theme_service.dart';
import 'package:to_camp/core/service/naver_map_service.dart';

class CustomMapView extends ConsumerStatefulWidget {
  const CustomMapView({
    super.key,
    required this.initialCameraPosition,
    required this.markers,
    this.selectedId,
    this.infoText,
    this.onMarkerTap,
    this.logoTopInset = 0,
    this.onMapCreated,
    this.onMapGestureStarted,
    this.onCameraMove,
    this.onCameraIdle,
  });

  final NCameraPosition initialCameraPosition;
  final List<NMarker> markers;
  final String? selectedId;
  final String? infoText;
  final ValueChanged<String>? onMarkerTap;
  final double logoTopInset;
  final ValueChanged<NaverMapController>? onMapCreated;
  final VoidCallback? onMapGestureStarted;
  final ValueChanged<NCameraPosition>? onCameraMove;
  final VoidCallback? onCameraIdle;

  @override
  ConsumerState<CustomMapView> createState() => _CustomMapViewState();
}

class _CustomMapViewState extends ConsumerState<CustomMapView> {
  final _markers = <String, NMarker>{};
  NaverMapController? _controller;
  NInfoWindow? _info;
  String? _infoText;
  bool _moving = false;
  bool _syncing = false;
  bool _dirty = false;

  @override
  void didUpdateWidget(CustomMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  Future<void> _sync() async {
    _dirty = true;
    final controller = _controller;
    if (_syncing || controller == null) return;
    _syncing = true;
    try {
      while (mounted && _dirty) {
        _dirty = false;
        await _applyMarkers(controller);
      }
    } finally {
      _syncing = false;
    }
  }

  Future<void> _applyMarkers(NaverMapController controller) async {
    final desired = {
      for (final marker in widget.markers) marker.info.id: marker,
    };
    final selectedId = widget.selectedId;
    final text = widget.infoText;
    if (_info != null &&
        (_info!.info.id != selectedId ||
            text == null ||
            !desired.containsKey(selectedId))) {
      await controller.deleteOverlay(_info!.info);
      if (!mounted) return;
      _info = null;
    }
    for (final id in _markers.keys.toSet().difference(
      desired.keys.toSet(),
    )) {
      await controller.deleteOverlay(_markers[id]!.info);
      _markers.remove(id);
      if (!mounted) return;
    }

    final added = <NMarker>{};
    for (final entry in desired.entries) {
      final next = entry.value;
      final existing = _markers[entry.key];
      if (existing == null) {
        next.setOnTapListener(
          (marker) => widget.onMarkerTap?.call(marker.info.id),
        );
        added.add(next);
        continue;
      }
      if (existing.position != next.position) {
        existing.setPosition(next.position);
      }
      if (existing.icon != next.icon) {
        existing.setIcon(next.icon);
      }
      if (existing.anchor != next.anchor) {
        existing.setAnchor(next.anchor);
      }
      if (existing.size != next.size) {
        existing.setSize(next.size);
      }
      if (existing.zIndex != next.zIndex) {
        existing.setZIndex(next.zIndex);
      }
    }
    if (added.isNotEmpty) {
      await controller.addOverlayAll(added);
      if (!mounted) return;
      for (final marker in added) {
        _markers[marker.info.id] = marker;
      }
    }

    final marker = _markers[selectedId];
    if (_dirty || marker == null || text == null) return;
    if (_info == null) {
      final window = NInfoWindow.onMarker(
        id: marker.info.id,
        text: text,
      );
      await marker.openInfoWindow(window);
      _info = window;
    } else if (_infoText != text) {
      _info!.setText(text);
    }
    _infoText = text;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return const SizedBox.shrink();
    }
    if (!hasNaverMapClientId) {
      return const Center(child: Text('지도 설정을 확인해 주세요.'));
    }
    final isDark =
        ref.watch(
          themeServiceProvider.select((theme) => theme.brightness),
        ) ==
        Brightness.dark;
    return NaverMap(
      options: NaverMapViewOptions(
        initialCameraPosition: widget.initialCameraPosition,
        mapType: isDark ? NMapType.navi : NMapType.basic,
        nightModeEnable: isDark,
        rotationGesturesEnable: false,
        logoAlign: NLogoAlign.leftTop,
        logoMargin: EdgeInsets.only(
          left: 12,
          top: 12 + widget.logoTopInset,
        ),
      ),
      onMapReady: (controller) {
        _controller = controller;
        controller.setLocationTrackingMode(
          NLocationTrackingMode.noFollow,
        );
        _sync();
        widget.onMapCreated?.call(controller);
      },
      onCameraChange: (reason, _) {
        if (!_moving && reason == NCameraUpdateReason.gesture) {
          _moving = true;
          widget.onMapGestureStarted?.call();
        }
        final position = _controller?.nowCameraPosition;
        if (position != null) widget.onCameraMove?.call(position);
      },
      onCameraIdle: () {
        _moving = false;
        final position = _controller?.nowCameraPosition;
        if (position != null) widget.onCameraMove?.call(position);
        widget.onCameraIdle?.call();
      },
    );
  }
}
