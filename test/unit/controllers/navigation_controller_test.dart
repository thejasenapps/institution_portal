import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:institution_portal/controllers/navigation_controller.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  // -------------------------------------------------------------------------
  // NavigationController.navigateTo()
  // -------------------------------------------------------------------------

  group('NavigationController.navigateTo()', () {
    test('initial activeIndex is 0', () {
      final controller = NavigationController();
      expect(controller.activeIndex.value, equals(0));
    });

    test('navigateTo(0) sets activeIndex to 0 (Dashboard)', () {
      final controller = NavigationController();
      controller.navigateTo(0);
      expect(controller.activeIndex.value, equals(0));
    });

    test('navigateTo(1) sets activeIndex to 1 (Mentors)', () {
      final controller = NavigationController();
      controller.navigateTo(1);
      expect(controller.activeIndex.value, equals(1));
    });

    test('navigateTo(2) sets activeIndex to 2 (Profile)', () {
      final controller = NavigationController();
      controller.navigateTo(2);
      expect(controller.activeIndex.value, equals(2));
    });

    test('navigateTo(3) sets activeIndex to 3 (Settings)', () {
      final controller = NavigationController();
      controller.navigateTo(3);
      expect(controller.activeIndex.value, equals(3));
    });

    test('navigateTo is idempotent: calling twice with same index leaves value unchanged',
        () {
      final controller = NavigationController();
      controller.navigateTo(2);
      expect(controller.activeIndex.value, equals(2));

      controller.navigateTo(2);
      expect(controller.activeIndex.value, equals(2));
    });

    test('navigateTo changes index from one value to another', () {
      final controller = NavigationController();
      controller.navigateTo(1);
      expect(controller.activeIndex.value, equals(1));

      controller.navigateTo(3);
      expect(controller.activeIndex.value, equals(3));
    });
  });
}
