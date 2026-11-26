import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:to_camp/core/const/data.dart';
import 'package:to_camp/core/service/toast_service.dart';
import 'package:to_camp/core/theme/res/layout.dart';
import 'package:to_camp/presentation/camping/base/based_list_view_model.dart';
import 'package:to_camp/presentation/camping/base/camping_screen.dart';
import 'package:to_camp/presentation/camping/location/utils/location_utils.dart';
import 'package:to_camp/presentation/camping/location/widgets/location_camping_card.dart';
import 'package:to_camp/presentation/camping/location/widgets/refresh_button.dart';
import 'package:to_camp/presentation/camping/location/widgets/show_card_button.dart';
import 'package:to_camp/presentation/camping/wishlist/utils/wishlist_utils.dart';
import 'package:to_camp/presentation/camping/wishlist/wishlist_view_model.dart';
import 'package:to_camp/presentation/common/layout/default_layout.dart';
import 'package:to_camp/presentation/common/widgets/custom_map_view.dart';
import 'package:to_camp/data/models/camping_model.dart';
import 'package:to_camp/presentation/camping/location/view_model/location_camping_view_model.dart';
import 'package:to_camp/presentation/camping/location/view_model/location_state.dart';
import 'package:to_camp/core/models/pagination_state.dart';

final cameraPositionProvider = StateProvider<NCameraPosition?>(
  (ref) => null,
);

class LocationCampingScreen extends ConsumerStatefulWidget {
  final LocationState location;
  final void Function(NaverMapController controller) onTapMyLocation;
  const LocationCampingScreen({
    super.key,
    required this.location,
    required this.onTapMyLocation,
  });

  @override
  ConsumerState<LocationCampingScreen> createState() =>
      _LocationCampingScreenState();
}

class _LocationCampingScreenState
    extends ConsumerState<LocationCampingScreen>
    with AutomaticKeepAliveClientMixin {
  bool showRefresh = false;
  bool showCard = true;
  bool refreshing = false;
  String? selectedId;
  int selectionRequest = 0;

  NaverMapController? mapController;

  @override
  bool get wantKeepAlive => true;

  late NLatLng initialLatLng;

  @override
  void initState() {
    super.initState();
    if (widget.location is LocationSuccess) {
      final location = widget.location as LocationSuccess;
      initialLatLng = NLatLng(location.lat, location.lng);
    } else {
      // 서울의 lat lng
      initialLatLng = const NLatLng(LAT_OF_SEOUL, LNG_OF_SEOUL);
    }
  }

  // home에서 Pagination이 끝나지 않았다면,showCard를 해주기 위해서
  void listenLocationCampingState() {
    ref.listen(locationCampingViewModelProvider, (p, n) {
      if (!refreshing &&
          p is! PaginationSuccess &&
          n is PaginationSuccess<CampingModel> &&
          n.items.isNotEmpty) {
        onTapMarker(n.items.first);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    listenLocationCampingState();

    final wishlist = ref.watch(wishlistViewModelProvider);
    final locationCampingState = ref.watch(
      locationCampingViewModelProvider,
    );
    final modelsById = <String, CampingModel>{};
    if (locationCampingState is PaginationSuccess<CampingModel>) {
      for (final model in [
        ...locationCampingState.items,
        ...WishlistUtils.extractCampingList(wishlist),
      ]) {
        modelsById.putIfAbsent(model.id, () => model);
      }
    }
    final totalModels = modelsById.values.toList();
    final hasItem = totalModels.isNotEmpty;
    final targetModel =
        modelsById[selectedId] ?? totalModels.firstOrNull;

    return DefaultLayout(
      isLoading:
          locationCampingState is PaginationFetchingMore ||
          locationCampingState is PaginationLoading,
      bottomNavigationBar: Align(
        alignment: Alignment.bottomRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Show Card / List Button
            if (hasItem)
              SizedBox(
                width: context.layout(
                  null,
                  desktop: MediaQuery.of(context).size.width / 2,
                ),
                child: ShowCardButton(
                  showCard: showCard,
                  onTapShowCard: () =>
                      onTapShowCard(totalModels, targetModel!),
                  onTapMyLocation: () {
                    final controller = mapController;
                    if (controller != null) {
                      widget.onTapMyLocation(controller);
                    }
                  },
                ),
              ),

            /// CampingCard
            const SizedBox(height: 4),
            if (hasItem && showCard)
              Flexible(
                child: GestureDetector(
                  child: LocationCampingCard(model: targetModel!),
                  onTap: () => ref
                      .read(basedListViewModelProvider.notifier)
                      .onCampingCardTap(context, targetModel),
                ),
              ),
          ],
        ),
      ),
      child: Stack(
        children: [
          CustomMapView(
            logoTopInset: MediaQuery.paddingOf(context).top,
            initialCameraPosition: NCameraPosition(
              target: initialLatLng,
              zoom: 12,
            ),
            selectedId: targetModel?.id,
            infoText: targetModel == null
                ? null
                : [
                    targetModel.name,
                    targetModel.address,
                  ].where((part) => part.isNotEmpty).join('\n'),
            markers: LocationUtils.createMarkers(
              totalModels: totalModels,
              wishlist: wishlist,
              selectedId: targetModel?.id,
            ),
            onMarkerTap: (id) {
              final model = modelsById[id];
              if (model != null) onTapMarker(model);
            },
            onMapCreated: (controller) {
              mapController = controller;
              if (targetModel != null) onTapMarker(targetModel);
            },
            onCameraMoveStarted: () => setState(() {
              showCard = false;
            }),
            onCameraMove: (cameraPosition) {
              ref.read(cameraPositionProvider.notifier).state =
                  cameraPosition;
            },

            onCameraIdle: () {
              if (!refreshing && !showRefresh) {
                setState(() => showRefresh = true);
              }
            },
          ),
          if (showRefresh)
            LocationRefreshButton(onRefresh: onTapRefresh),
        ],
      ),
    );
  }

  Future<void> onTapMarker(CampingModel targetModel) async {
    final controller = mapController;
    if (controller == null) return;
    final request = ++selectionRequest;
    setState(() => selectedId = targetModel.id);
    final canceled = await controller.updateCamera(
      NCameraUpdate.withParams(
        target: NLatLng(targetModel.lat, targetModel.lng),
      ),
    );
    if (mounted && !canceled && request == selectionRequest) {
      setState(() => showCard = true);
    }
  }

  void onTapShowCard(
    List<CampingModel> models,
    CampingModel targetModel,
  ) {
    /// 이미 카드가 띄워져 있다면
    if (showCard) {
      /// 캠핑장 목록으로 라우팅
      context.pushNamed(
        CampingScreen.routeName,
        extra: models,
        pathParameters: {'title': '이 지역 캠핑장'},
      );
    } else {
      /// 현재 index에 대한 카드 띄우기
      onTapMarker(targetModel);
    }
  }

  Future<void> onTapRefresh() async {
    final controller = mapController;
    if (refreshing || controller == null) return;
    refreshing = true;
    try {
      final position = await controller.getCameraPosition();
      if (!mounted || controller != mapController) return;
      ref.read(cameraPositionProvider.notifier).state = position;
      await ref
          .read(locationCampingViewModelProvider.notifier)
          .paginate(isReFetch: true);
      if (!mounted) return;
      final state = ref.read(locationCampingViewModelProvider);
      if (state is PaginationFetchingError<CampingModel>) {
        ToastService.show(text: state.message, isError: true);
      } else if (state is PaginationError) {
        ToastService.show(text: state.message, isError: true);
      } else if (state is PaginationSuccess<CampingModel>) {
        if (state.items.isEmpty) {
          ToastService.show(text: '근처 캠핑장을 찾을 수 없어요', isError: true);
        } else {
          await onTapMarker(state.items.first);
        }
      }
    } finally {
      refreshing = false;
      if (mounted) setState(() => showRefresh = false);
    }
  }
}
