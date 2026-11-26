import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:to_camp/presentation/common/widgets/custom_divider.dart';
import 'package:to_camp/presentation/common/widgets/custom_map_view.dart';
import 'package:to_camp/presentation/common/widgets/tile.dart';
import 'package:to_camp/core/theme/res/layout.dart';
import 'package:to_camp/core/theme/service/theme_service.dart';
import 'package:to_camp/core/service/toast_service.dart';
import 'package:to_camp/data/models/camping_model.dart';
import 'package:to_camp/core/provider/marker_icon_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailMap extends ConsumerWidget {
  final CampingModel model;
  const DetailMap({super.key, required this.model});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 16,
      ),
      child: Column(
        children: [
          context.layout(const CustomDivider(), desktop: SizedBox()),
          _Address(address: model.address),
          const SizedBox(height: 8),
          _Map(model: model),
          const SizedBox(height: 8),
          _Tel(model: model),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Address extends ConsumerWidget {
  final String address;
  const _Address({super.key, required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeServiceProvider);
    if (address.isEmpty) return SizedBox();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// Location Icon
        Icon(
          PhosphorIcons.mapPin(),
          color: theme.color.primary,
          size: 28,
        ),

        /// Address
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typo.subtitle1.copyWith(
              color: theme.color.subtext,
            ),
          ),
        ),

        /// Copy Button
        const SizedBox(width: 8.0),
        InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () {
            Clipboard.setData(ClipboardData(text: address));
            ToastService.show(text: '클립보드에 복사되었습니다');
          },
          child: Icon(
            PhosphorIcons.copySimple(),
            color: theme.color.subtext,
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _Map extends StatelessWidget {
  final CampingModel model;
  const _Map({required this.model});

  @override
  Widget build(BuildContext context) {
    if (model.lat == 0 || model.lng == 0) {
      return const SizedBox.shrink();
    }

    final position = NLatLng(model.lat, model.lng);
    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(16),
      child: SizedBox(
        height: 300,
        child: CustomMapView(
          key: ValueKey((model.id, model.lat, model.lng)),
          forceGesture: true,
          initialCameraPosition: NCameraPosition(
            target: position,
            zoom: 14,
          ),
          markers: [
            NMarker(
              id: model.id,
              position: position,
              icon: CampingMarkerIcon.tent.image,
              size: const Size(36, 42),
              anchor: const NPoint(0.5, 1),
            ),
          ],
          selectedId: model.id,
          infoText: [
            model.name,
            model.address,
          ].where((line) => line.isNotEmpty).join('\n'),
        ),
      ),
    );
  }
}

class _Tel extends StatelessWidget {
  final CampingModel model;
  const _Tel({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final hasTel = model.tel.isNotEmpty;
    if (!hasTel) return const SizedBox();
    return Tile(
      onTap: () {
        final uri = Uri(scheme: 'tel', path: model.tel);
        launchUrl(uri);
      },
      text: model.tel,
      trailing: PhosphorIcons.phoneTransfer(),
    );
  }
}
