import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:to_camp/presentation/image/screen/image_detail_screen.dart';

void main() {
  testWidgets(
    'pinch takes over a swipe and double tap restores paging',
    (tester) async {
      final pages = PageController();
      int taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ZoomableGallery(
            controller: pages,
            itemCount: 3,
            onTap: () => taps++,
            onPageChanged: (_) {},
            itemBuilder: (_, i) =>
                ColoredBox(color: Colors.blue, child: Text('$i')),
          ),
        ),
      );
      final transform = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!;
      final first = await tester.startGesture(const Offset(350, 300));
      await first.moveBy(const Offset(-40, 0));
      await first.moveBy(const Offset(-40, 0));
      final second = await tester.startGesture(
        const Offset(500, 300),
      );
      for (var i = 0; i < 6; i++) {
        await first.moveBy(const Offset(-12, 0));
        await second.moveBy(const Offset(12, 0));
        await tester.pump();
      }
      await first.up();
      await second.up();
      await tester.pumpAndSettle();
      expect(transform.value.getMaxScaleOnAxis(), greaterThan(1.1));
      expect(pages.page, 0);
      const point = Offset(140, 220);
      Future<void> doubleTap() async {
        await tester.tapAt(point);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tapAt(point);
        await tester.pumpAndSettle();
      }

      await doubleTap();
      expect(transform.value.isIdentity(), isTrue);
      await doubleTap();
      expect(
        transform.value.getMaxScaleOnAxis(),
        closeTo(2.5, 0.001),
      );
      expect(
        (transform.toScene(point) - point).distance,
        lessThan(0.01),
      );
      await doubleTap();
      expect(taps, 0);
      await tester.flingFrom(
        const Offset(690, 310),
        const Offset(-540, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(pages.page, 1);
      await tester.pumpWidget(const SizedBox());
      pages.dispose();
    },
  );
}
