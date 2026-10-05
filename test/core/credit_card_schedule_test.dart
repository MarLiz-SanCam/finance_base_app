import 'package:finance_base_app/core/credit_card_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreditCardSchedule.proximaFecha', () {
    test('si el día aún no llega, es este mes', () {
      expect(
        CreditCardSchedule.proximaFecha(20, DateTime(2026, 9, 10, 15, 30)),
        DateTime(2026, 9, 20),
      );
    });

    test('si el día es hoy, cuenta como hoy', () {
      expect(
        CreditCardSchedule.proximaFecha(10, DateTime(2026, 9, 10, 23)),
        DateTime(2026, 9, 10),
      );
    });

    test('si el día ya pasó, es el mes siguiente (cruza de año)', () {
      expect(
        CreditCardSchedule.proximaFecha(5, DateTime(2026, 12, 10)),
        DateTime(2027, 1, 5),
      );
    });

    test('recorta al último día del mes', () {
      expect(
        CreditCardSchedule.proximaFecha(31, DateTime(2026, 2, 10)),
        DateTime(2026, 2, 28),
      );
      expect(
        CreditCardSchedule.proximaFecha(30, DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28),
      );
    });

    test('diasHasta ignora la hora', () {
      expect(
        CreditCardSchedule.diasHasta(
          DateTime(2026, 9, 12),
          DateTime(2026, 9, 10, 22),
        ),
        2,
      );
    });
  });
}
