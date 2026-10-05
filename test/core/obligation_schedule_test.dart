import 'package:finance_base_app/core/obligation_schedule.dart';
import 'package:finance_base_app/data/db/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ObligationSchedule.ocurrenciasEnRango (quincenal)', () {
    test(
      'usa los dos días elegidos por el usuario, no día 15 y último día',
      () {
        final ocurrencias = ObligationSchedule.ocurrenciasEnRango(
          frequency: ObligationFrequency.quincenal,
          paymentDay: 5,
          paymentDay2: 20,
          desde: DateTime(2026, 9, 1),
          hasta: DateTime(2026, 9, 30),
        );

        expect(ocurrencias, [DateTime(2026, 9, 5), DateTime(2026, 9, 20)]);
      },
    );

    test('recorta al último día del mes si el día elegido no existe', () {
      final ocurrencias = ObligationSchedule.ocurrenciasEnRango(
        frequency: ObligationFrequency.quincenal,
        paymentDay: 1,
        paymentDay2: 31,
        desde: DateTime(2026, 2, 1),
        hasta: DateTime(2026, 2, 28),
      );

      expect(ocurrencias, [DateTime(2026, 2, 1), DateTime(2026, 2, 28)]);
    });

    test('no duplica la ocurrencia si ambos días caen en la misma fecha', () {
      final ocurrencias = ObligationSchedule.ocurrenciasEnRango(
        frequency: ObligationFrequency.quincenal,
        paymentDay: 30,
        paymentDay2: 31,
        desde: DateTime(2026, 2, 1),
        hasta: DateTime(2026, 2, 28),
      );

      expect(ocurrencias, [DateTime(2026, 2, 28)]);
    });
  });
}
