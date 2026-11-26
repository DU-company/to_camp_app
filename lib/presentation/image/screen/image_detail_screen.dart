import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_camp/core/theme/service/theme_service.dart';
import 'package:to_camp/presentation/common/layout/default_layout.dart';
import 'package:to_camp/presentation/common/widgets/error_message_widget.dart';
import 'package:to_camp/presentation/image/screen/image_grid_screen.dart';

class ImageDetailScreen extends ConsumerStatefulWidget {
  static String get routeName => 'image-detail';
  final List<String> imgUrls;
  const ImageDetailScreen({super.key, required this.imgUrls});

  @override
  ConsumerState<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends ConsumerState<ImageDetailScreen> {
  late final pages = PageController(
    initialPage: ref.read(imageDetailIndexProvider),
  );
  bool showAppBar = true;

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeServiceProvider);
    final currentIndex = ref.watch(imageDetailIndexProvider);
    return DefaultLayout(
      child: Stack(
        children: [
          ZoomableGallery(
            controller: pages,
            itemCount: widget.imgUrls.length,
            onPageChanged: (index) =>
                ref.read(imageDetailIndexProvider.notifier).state = index,
            onTap: () => setState(() => showAppBar = !showAppBar),
            itemBuilder: (context, index) =>
                _DetailPhoto(url: widget.imgUrls[index]),
          ),
          if (showAppBar)
            Positioned(
              top: 0,
              right: 0,
              left: 0,
              child: AppBar(
                backgroundColor: theme.color.surface.withValues(alpha: 0.9),
                title: Text('${currentIndex + 1}/${widget.imgUrls.length}'),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailPhoto extends StatefulWidget {
  const _DetailPhoto({required this.url});
  final String url;
  @override
  State<_DetailPhoto> createState() => _DetailPhotoState();
}

class _DetailPhotoState extends State<_DetailPhoto> {
  int attempt = 0;
  @override
  Widget build(BuildContext context) => CachedNetworkImage(
    key: ValueKey((widget.url, attempt)),
    imageUrl: widget.url,
    fit: BoxFit.contain,
    placeholder: (_, _) => const Center(
      child: SizedBox.square(
        dimension: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          semanticsLabel: '사진 불러오는 중',
        ),
      ),
    ),
    errorWidget: (_, _, _) => Center(
      child: ErrorMessageWidget(
        message: '사진을 불러오지 못했어요',
        onTap: () => setState(() => attempt++),
      ),
    ),
  );
}

/// One scale recognizer owns the touch sequence. At fit scale its horizontal
/// drags go to the pager, which retains its usual fling and snap physics.
class ZoomableGallery extends StatefulWidget {
  const ZoomableGallery({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.onPageChanged,
    required this.onTap,
    required this.itemBuilder,
  });
  final PageController controller;
  final int itemCount;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onTap;
  final IndexedWidgetBuilder itemBuilder;
  @override
  State<ZoomableGallery> createState() => _ZoomableGalleryState();
}

class _ZoomableGalleryState extends State<ZoomableGallery>
    with SingleTickerProviderStateMixin {
  final transform = TransformationController();
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 230),
  )..addListener(_animate);
  Matrix4Tween? tween;
  Drag? pageDrag;
  int fingers = 0;
  bool pinching = false;
  Offset tapPosition = Offset.zero;
  double get scale => transform.value.getMaxScaleOnAxis();

  void _animate() {
    transform.value = tween!.transform(
      Curves.easeOutCubic.transform(animation.value),
    );
  }

  void _toggleZoom() {
    final target = Matrix4.identity();
    if (scale <= 1.001) {
      const zoom = 2.5;
      target.setEntry(0, 0, zoom);
      target.setEntry(1, 1, zoom);
      target.setTranslationRaw(
        tapPosition.dx * (1 - zoom),
        tapPosition.dy * (1 - zoom),
        0,
      );
    }
    tween = Matrix4Tween(begin: transform.value.clone(), end: target);
    animation.forward(from: 0);
  }

  void _down(PointerDownEvent event) {
    animation.stop();
    fingers++;
    if (fingers == 1) pinching = false;
    if (fingers == 2) {
      pinching = true;
      pageDrag?.cancel();
      pageDrag = null;
      widget.controller.jumpToPage(widget.controller.page!.round());
    }
  }

  void _update(ScaleUpdateDetails details) {
    if (pinching || scale > 1.001 || details.pointerCount != 1) return;
    final dx = details.focalPointDelta.dx;
    if (dx == 0) return;
    pageDrag ??= widget.controller.position.drag(
      DragStartDetails(globalPosition: details.focalPoint),
      () => pageDrag = null,
    );
    pageDrag!.update(
      DragUpdateDetails(
        globalPosition: details.focalPoint,
        delta: Offset(dx, 0),
        primaryDelta: dx,
      ),
    );
  }

  void _end(ScaleEndDetails details) {
    final vx = details.velocity.pixelsPerSecond.dx;
    pageDrag?.end(
      DragEndDetails(
        velocity: Velocity(pixelsPerSecond: Offset(vx, 0)),
        primaryVelocity: vx,
      ),
    );
    pageDrag = null;
    if (scale <= 1.001 && !transform.value.isIdentity()) {
      transform.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    pageDrag?.cancel();
    animation.dispose();
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _down,
    onPointerUp: (_) => fingers--,
    onPointerCancel: (_) => fingers--,
    child: GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: (details) => tapPosition = details.localPosition,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: transform,
        minScale: 1,
        maxScale: 3,
        onInteractionUpdate: _update,
        onInteractionEnd: _end,
        child: PageView.builder(
          controller: widget.controller,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: widget.onPageChanged,
          itemCount: widget.itemCount,
          itemBuilder: widget.itemBuilder,
        ),
      ),
    ),
  );
}
