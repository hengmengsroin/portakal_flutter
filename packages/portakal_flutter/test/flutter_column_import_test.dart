import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

void main() {
  testWidgets(
    'Flutter Column and portakal_flutter co-exist without symbol conflict',
    (tester) async {
      // 1. Instantiate Flutter's Column widget without prefix
      final widget = Column(children: const [Text('Hello Flutter')]);
      expect(widget, isA<Column>());

      // 2. Instantiate Portakal's ReceiptColumn without prefix
      const receiptCol = ReceiptColumn(width: 10, align: 'right');
      expect(receiptCol, isA<ReceiptColumn>());
      expect(receiptCol.width, equals(10));
      expect(receiptCol.align, equals('right'));

      // 3. Pump widget in test environment
      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: widget),
      );
      expect(find.text('Hello Flutter'), findsOneWidget);
    },
  );
}
