import 'package:flutter/material.dart';
import 'package:to_camp/data/models/camping_model.dart';
import 'package:to_camp/presentation/camping/location/widgets/location_camping_card.dart';

class LocationCardCarousel extends StatefulWidget {
  const LocationCardCarousel({
    super.key,
    required this.models,
    required this.selectedIndex,
    required this.onSelect,
    required this.onOpen,
  });

  final List<CampingModel> models;
  final int selectedIndex;
  final ValueChanged<CampingModel> onSelect;
  final ValueChanged<CampingModel> onOpen;

  @override
  State<LocationCardCarousel> createState() =>
      _LocationCardCarouselState();
}

class _LocationCardCarouselState extends State<LocationCardCarousel> {
  late final _pages = PageController(
    initialPage: widget.selectedIndex,
    viewportFraction: 0.88,
    keepPage: false,
  );

  @override
  void didUpdateWidget(LocationCardCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex == widget.selectedIndex) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pages.hasClients) return;
      final index = widget.selectedIndex;
      if (_pages.page?.round() != index) _pages.jumpToPage(index);
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pages,
      itemCount: widget.models.length,
      onPageChanged: (index) {
        if (index != widget.selectedIndex &&
            index < widget.models.length) {
          widget.onSelect(widget.models[index]);
        }
      },
      itemBuilder: (context, index) {
        final model = widget.models[index];
        return Padding(
          key: ValueKey(model.id),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => widget.onOpen(model),
            child: LocationCampingCard(model: model),
          ),
        );
      },
    );
  }
}
