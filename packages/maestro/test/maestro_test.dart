import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maestro/maestro.dart';

class DefaultPerfomer implements Performer {
  @override
  void attach(Score score) {}

  @override
  void detach() {}

  @override
  FutureOr<void> play() {}
}

void main() {
  group('Maestro', () {
    testWidgets('descendants can read an ancestor', (tester) async {
      int buildCount = 0;
      BuildContext ctx;
      final Widget child = Builder(
        builder: (context) {
          ctx = context;
          buildCount++;
          Maestro.read<int>(context);
          return const SizedBox();
        },
      );

      await tester.pumpWidget(Maestro(42, child: child));
      expect(buildCount, equals(1));

      Maestro.write(ctx, 84);
      await tester.pump();
      expect(buildCount, equals(1));
    });

    testWidgets('descendants can listen an ancestor', (tester) async {
      int buildCount = 0;
      BuildContext ctx;

      final Widget child = Builder(
        builder: (context) {
          ctx = context;
          buildCount++;
          Maestro.listen<int>(context);
          return const SizedBox();
        },
      );

      await tester.pumpWidget(Maestro(42, child: child));
      expect(buildCount, equals(1));

      Maestro.write(ctx, 84);
      expect(buildCount, equals(1));
      await tester.pump();
      expect(buildCount, equals(2));
    });

    testWidgets('descendants can select an ancestor', (tester) async {
      int buildCount = 0;
      int value;
      BuildContext ctx;

      final Widget child = Builder(
        builder: (context) {
          ctx = context;
          buildCount++;
          value = Maestro.select<int, int>(context, (x) => x * 2);
          return const SizedBox();
        },
      );

      await tester.pumpWidget(Maestro(42, child: child));
      expect(buildCount, equals(1));
      expect(value, equals(84));

      ctx.write(84);
      await tester.pump();
      expect(buildCount, equals(2));
      expect(value, equals(168));
    });

    testWidgets('descendants cannot write a read-only Maestro', (tester) async {
      int buildCount = 0;
      int onWriteValue = 0;
      BuildContext ctx;
      final Widget child = Builder(
        builder: (context) {
          ctx = context;
          buildCount++;
          Maestro.read<int>(context);
          return const SizedBox();
        },
      );

      await tester.pumpWidget(
        Maestro<int>.readOnly(
          42,
          onWrite: (request) => onWriteValue = request.value,
          child: child,
        ),
      );
      expect(buildCount, equals(1));
      ctx.write(84);

      await tester.pump();

      expect(ctx.read<int>(), 42);
      expect(onWriteValue, 84);
    });

    testWidgets('does not rebuilt if value changed and writeable',
        (tester) async {
      int buildCount = 0;

      final Widget child = Builder(
        builder: (context) {
          buildCount++;
          Maestro.listen<int>(context);
          return const SizedBox();
        },
      );

      await tester.pumpWidget(Maestro(42, child: child));
      expect(buildCount, equals(1));

      await tester.pumpWidget(Maestro(84, child: child));
      expect(buildCount, equals(1));

      await tester.pumpWidget(Maestro(84, key: UniqueKey(), child: child));
      expect(buildCount, equals(2));
    });

    testWidgets('does rebuilt if value changed and read-only', (tester) async {
      int value = 0;
      int buildCount = 0;

      final Widget child = Builder(
        builder: (context) {
          buildCount++;
          value = Maestro.listen<int>(context);
          return const SizedBox();
        },
      );

      expect(value, equals(0));

      await tester.pumpWidget(Maestro.readOnly(42, child: child));
      expect(buildCount, equals(1));
      expect(value, equals(42));

      await tester.pumpWidget(Maestro.readOnly(84, child: child));
      expect(buildCount, equals(2));
      expect(value, equals(84));
    });
  });
}
