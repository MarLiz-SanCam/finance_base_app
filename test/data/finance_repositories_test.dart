import 'package:drift/native.dart';
import 'package:finance_base_app/core/money.dart';
import 'package:finance_base_app/data/db/app_database.dart';
import 'package:finance_base_app/data/db/enums.dart';
import 'package:finance_base_app/data/repositories/accounts_repository.dart';
import 'package:finance_base_app/data/repositories/categories_repository.dart';
import 'package:finance_base_app/data/repositories/local_identity_repository.dart';
import 'package:finance_base_app/data/repositories/obligations_repository.dart';
import 'package:finance_base_app/data/repositories/repository_exceptions.dart';
import 'package:finance_base_app/data/repositories/transactions_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test(
      'pesosACentavos convierte texto a centavos sin errores de redondeo',
      () {
        expect(Money.pesosACentavos('150.50'), 15050);
        expect(Money.pesosACentavos('150'), 15000);
        expect(Money.pesosACentavos('1,234.56'), 123456);
        expect(Money.pesosACentavos('-99.99'), -9999);
        expect(Money.pesosACentavos('0.1'), 10);
      },
    );

    test('centavosAPesos formatea como moneda', () {
      expect(Money.centavosAPesos(15050), r'$150.50');
      expect(Money.centavosAPesos(123456), r'$1,234.56');
    });
  });

  group('Repositorios (BD en memoria)', () {
    late AppDatabase db;
    late LocalIdentityRepository identity;
    late AccountsRepository accounts;
    late CategoriesRepository categories;
    late ObligationsRepository obligations;
    late TransactionsRepository transactions;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      identity = LocalIdentityRepository(db);
      accounts = AccountsRepository(db, identity);
      categories = CategoriesRepository(db, identity);
      obligations = ObligationsRepository(db, identity);
      transactions = TransactionsRepository(
        db,
        accounts,
        obligations,
        identity,
      );
    });

    tearDown(() => db.close());

    test(
      'cada registro creado tiene un UUID único, no autoincrement',
      () async {
        final id1 = await accounts.crear(
          name: 'Cuenta 1',
          type: AccountType.efectivo,
        );
        final id2 = await accounts.crear(
          name: 'Cuenta 2',
          type: AccountType.efectivo,
        );
        expect(id1, isNot(equals(id2)));
        expect(id1.length, greaterThan(20));
      },
    );

    group('cuentas de crédito', () {
      Future<String> crearTarjeta({int deuda = 0}) => accounts.crear(
        name: 'Tarjeta',
        type: AccountType.credito,
        saldoInicialCentavos: -deuda,
        limiteCreditoCentavos: Money.pesosACentavos('1000.00'),
      );

      test(
        'exige un límite mayor a cero y lo descarta en otros tipos',
        () async {
          expect(
            () => accounts.crear(name: 'T', type: AccountType.credito),
            throwsArgumentError,
          );
          final id = await accounts.crear(
            name: 'Débito',
            type: AccountType.debito,
            limiteCreditoCentavos: 5000,
          );
          expect((await accounts.obtener(id)).creditLimit, isNull);
        },
      );

      test('un gasto dentro del disponible se registra', () async {
        final tarjeta = await crearTarjeta(deuda: 30000);
        final categoria = await categories.crear(
          name: 'Comida',
          type: CategoryType.gasto,
        );

        await transactions.registrar(
          concept: 'Super',
          amountCentavos: 70000,
          fecha: DateTime(2026, 9, 15),
          type: TransactionType.gasto,
          accountId: tarjeta,
          categoryId: categoria,
        );

        expect((await accounts.obtener(tarjeta)).currentBalance, -100000);
      });

      test('un gasto que excede el disponible se rechaza', () async {
        final tarjeta = await crearTarjeta(deuda: 30000);
        final categoria = await categories.crear(
          name: 'Comida',
          type: CategoryType.gasto,
        );

        await expectLater(
          transactions.registrar(
            concept: 'Tele',
            amountCentavos: 70001,
            fecha: DateTime(2026, 9, 15),
            type: TransactionType.gasto,
            accountId: tarjeta,
            categoryId: categoria,
          ),
          throwsA(isA<CreditoInsuficienteException>()),
        );
        expect((await accounts.obtener(tarjeta)).currentBalance, -30000);
      });

      test('pagar la tarjeta por transferencia libera crédito', () async {
        final tarjeta = await crearTarjeta(deuda: 100000);
        final debito = await accounts.crear(
          name: 'Débito',
          type: AccountType.debito,
          saldoInicialCentavos: 50000,
        );

        await transactions.transferir(
          concept: 'Pago tarjeta',
          amountCentavos: 40000,
          fecha: DateTime(2026, 9, 15),
          cuentaOrigenId: debito,
          cuentaDestinoId: tarjeta,
        );

        final cuenta = await accounts.obtener(tarjeta);
        expect(cuenta.currentBalance, -60000);
        await accounts.validarCapacidad(tarjeta, 40000);
      });

      test('se puede pagar de más y queda saldo a favor', () async {
        final tarjeta = await crearTarjeta(deuda: 10000);
        final debito = await accounts.crear(
          name: 'Débito',
          type: AccountType.debito,
          saldoInicialCentavos: 50000,
        );

        await transactions.transferir(
          concept: 'Pago tarjeta',
          amountCentavos: 30000,
          fecha: DateTime(2026, 9, 15),
          cuentaOrigenId: debito,
          cuentaDestinoId: tarjeta,
        );

        expect((await accounts.obtener(tarjeta)).currentBalance, 20000);
        // Con saldo a favor el disponible supera el límite ($1,000).
        await accounts.validarCapacidad(tarjeta, 120000);
        await expectLater(
          accounts.validarCapacidad(tarjeta, 120001),
          throwsA(isA<CreditoInsuficienteException>()),
        );
      });

      test(
        'guarda días de corte/pago y los descarta fuera de crédito',
        () async {
          final id = await accounts.crear(
            name: 'Tarjeta',
            type: AccountType.credito,
            limiteCreditoCentavos: 100000,
            diaCorte: 10,
            diaPago: 28,
          );
          var cuenta = await accounts.obtener(id);
          expect(cuenta.statementDay, 10);
          expect(cuenta.paymentDueDay, 28);

          expect(
            () => accounts.actualizar(
              id: id,
              name: 'Tarjeta',
              type: AccountType.credito,
              limiteCreditoCentavos: 100000,
              diaCorte: 32,
              diaPago: 28,
            ),
            throwsArgumentError,
          );

          await accounts.actualizar(
            id: id,
            name: 'Tarjeta',
            type: AccountType.debito,
          );
          cuenta = await accounts.obtener(id);
          expect(cuenta.statementDay, isNull);
          expect(cuenta.paymentDueDay, isNull);
        },
      );

      test('transferir desde la tarjeta también respeta el límite', () async {
        final tarjeta = await crearTarjeta(deuda: 90000);
        final debito = await accounts.crear(
          name: 'Débito',
          type: AccountType.debito,
        );

        await expectLater(
          transactions.transferir(
            concept: 'Disposición',
            amountCentavos: 20000,
            fecha: DateTime(2026, 9, 15),
            cuentaOrigenId: tarjeta,
            cuentaDestinoId: debito,
          ),
          throwsA(isA<CreditoInsuficienteException>()),
        );
      });
    });

    test('registrar una transacción ajusta el saldo de la cuenta', () async {
      final cuentaId = await accounts.crear(
        name: 'Efectivo',
        type: AccountType.efectivo,
      );
      final categoriaId = await categories.crear(
        name: 'Salario',
        type: CategoryType.ingreso,
      );

      await transactions.registrar(
        concept: 'Pago quincenal',
        amountCentavos: Money.pesosACentavos('5000.00'),
        fecha: DateTime(2026, 9, 15),
        type: TransactionType.ingreso,
        accountId: cuentaId,
        categoryId: categoriaId,
      );

      final cuenta = await accounts.obtener(cuentaId);
      expect(cuenta.currentBalance, 500000);
    });

    test(
      'un movimiento directo nace pagado con due_date == payment_date',
      () async {
        final cuentaId = await accounts.crear(
          name: 'Efectivo',
          type: AccountType.efectivo,
        );
        final categoriaId = await categories.crear(
          name: 'Salario',
          type: CategoryType.ingreso,
        );
        final fecha = DateTime(2026, 9, 15);

        await transactions.registrar(
          concept: 'Pago',
          amountCentavos: 100000,
          fecha: fecha,
          type: TransactionType.ingreso,
          accountId: cuentaId,
          categoryId: categoriaId,
        );

        final fila =
            (await transactions.watchByType(TransactionType.ingreso).first)
                .single;
        expect(fila.status, TransactionStatus.pagado);
        expect(fila.dueDate, fecha);
        expect(fila.paymentDate, fecha);
      },
    );

    test(
      'gasto resta del saldo y editar la transacción recalcula bien',
      () async {
        final cuentaId = await accounts.crear(
          name: 'Débito',
          type: AccountType.debito,
          saldoInicialCentavos: 100000,
        );
        final categoriaGasto = await categories.crear(
          name: 'Comida',
          type: CategoryType.gasto,
        );

        final txId = await transactions.registrar(
          concept: 'Supermercado',
          amountCentavos: 20000,
          fecha: DateTime(2026, 9, 10),
          type: TransactionType.gasto,
          accountId: cuentaId,
          categoryId: categoriaGasto,
        );

        var cuenta = await accounts.obtener(cuentaId);
        expect(cuenta.currentBalance, 80000);

        // Editar el monto de 200.00 a 300.00: el saldo debe reflejar el delta.
        await transactions.actualizar(
          id: txId,
          concept: 'Supermercado (corregido)',
          amountCentavos: 30000,
          fecha: DateTime(2026, 9, 10),
          type: TransactionType.gasto,
          accountId: cuentaId,
          categoryId: categoriaGasto,
        );

        cuenta = await accounts.obtener(cuentaId);
        expect(cuenta.currentBalance, 70000);

        await transactions.eliminar(txId);
        cuenta = await accounts.obtener(cuentaId);
        expect(cuenta.currentBalance, 100000);
      },
    );

    test('mover una transacción de cuenta corrige el saldo de ambas', () async {
      final cuentaA = await accounts.crear(
        name: 'Cuenta A',
        type: AccountType.efectivo,
        saldoInicialCentavos: 50000,
      );
      final cuentaB = await accounts.crear(
        name: 'Cuenta B',
        type: AccountType.debito,
        saldoInicialCentavos: 50000,
      );
      final categoriaGasto = await categories.crear(
        name: 'Transporte',
        type: CategoryType.gasto,
      );

      final txId = await transactions.registrar(
        concept: 'Gasolina',
        amountCentavos: 10000,
        fecha: DateTime(2026, 9, 1),
        type: TransactionType.gasto,
        accountId: cuentaA,
        categoryId: categoriaGasto,
      );

      await transactions.actualizar(
        id: txId,
        concept: 'Gasolina',
        amountCentavos: 10000,
        fecha: DateTime(2026, 9, 1),
        type: TransactionType.gasto,
        accountId: cuentaB,
        categoryId: categoriaGasto,
      );

      expect((await accounts.obtener(cuentaA)).currentBalance, 50000);
      expect((await accounts.obtener(cuentaB)).currentBalance, 40000);
    });

    test('rechaza registrar si el tipo de categoría no coincide', () async {
      final cuentaId = await accounts.crear(
        name: 'Efectivo',
        type: AccountType.efectivo,
      );
      final categoriaIngreso = await categories.crear(
        name: 'Salario',
        type: CategoryType.ingreso,
      );

      expect(
        () => transactions.registrar(
          concept: 'Gasto mal clasificado',
          amountCentavos: 1000,
          fecha: DateTime(2026, 9, 1),
          type: TransactionType.gasto,
          accountId: cuentaId,
          categoryId: categoriaIngreso,
        ),
        throwsArgumentError,
      );
    });

    test('no permite eliminar una cuenta con transacciones', () async {
      final cuentaId = await accounts.crear(
        name: 'Efectivo',
        type: AccountType.efectivo,
      );
      final categoriaId = await categories.crear(
        name: 'Salario',
        type: CategoryType.ingreso,
      );
      await transactions.registrar(
        concept: 'Pago',
        amountCentavos: 1000,
        fecha: DateTime(2026, 9, 1),
        type: TransactionType.ingreso,
        accountId: cuentaId,
        categoryId: categoriaId,
      );

      expect(
        () => accounts.eliminar(cuentaId),
        throwsA(isA<RegistroEnUsoException>()),
      );
    });

    test(
      'eliminar una cuenta la oculta de watchAll sin borrarla de la BD',
      () async {
        final cuentaId = await accounts.crear(
          name: 'Efectivo',
          type: AccountType.efectivo,
        );
        await accounts.eliminar(cuentaId);

        final visibles = await accounts.watchAll().first;
        expect(visibles, isEmpty);
      },
    );

    test(
      'recalcularSaldo reconstruye el saldo desde las transacciones pagadas',
      () async {
        final cuentaId = await accounts.crear(
          name: 'Efectivo',
          type: AccountType.efectivo,
        );
        final ingreso = await categories.crear(
          name: 'Salario',
          type: CategoryType.ingreso,
        );
        final gasto = await categories.crear(
          name: 'Comida',
          type: CategoryType.gasto,
        );
        await transactions.registrar(
          concept: 'Pago',
          amountCentavos: 100000,
          fecha: DateTime(2026, 9, 1),
          type: TransactionType.ingreso,
          accountId: cuentaId,
          categoryId: ingreso,
        );
        await transactions.registrar(
          concept: 'Super',
          amountCentavos: 30000,
          fecha: DateTime(2026, 9, 2),
          type: TransactionType.gasto,
          accountId: cuentaId,
          categoryId: gasto,
        );

        // Se desincroniza el saldo a propósito para probar la reparación.
        await accounts.applyDelta(cuentaId, 999999);
        await accounts.recalcularSaldo(cuentaId);

        expect((await accounts.obtener(cuentaId)).currentBalance, 70000);
      },
    );

    test(
      'el motor genera ocurrencias pendientes hacia el horizonte, sin duplicar',
      () async {
        final cuentaId = await accounts.crear(
          name: 'Débito',
          type: AccountType.debito,
        );
        final categoriaId = await categories.crear(
          name: 'Suscripciones',
          type: CategoryType.gasto,
        );
        await obligations.crear(
          concept: 'Netflix',
          categoryId: categoriaId,
          accountId: cuentaId,
          type: ObligationType.gastoFijo,
          frequency: ObligationFrequency.mensual,
          amountPerPeriodCentavos: 20000,
          paymentDay: 15,
          startDate: DateTime(2026, 1, 1),
        );

        final horizonte = DateTime(2026, 3, 1);
        await obligations.generarPagosPendientes(horizonte: horizonte);
        // Repetir no debe duplicar: la marca de agua ya avanzó al horizonte.
        await obligations.generarPagosPendientes(horizonte: horizonte);
        await obligations.generarPagosPendientes(horizonte: horizonte);

        final pendientes = await transactions.watchPendientes().first;
        expect(pendientes.length, 2); // 15-ene y 15-feb
        expect(
          pendientes.every((t) => t.status == TransactionStatus.pendiente),
          isTrue,
        );
        expect(pendientes.every((t) => t.paymentDate == null), isTrue);
      },
    );

    test(
      'generar pendientes no afecta el saldo hasta confirmar el pago',
      () async {
        final cuentaId = await accounts.crear(
          name: 'Débito',
          type: AccountType.debito,
          saldoInicialCentavos: 100000,
        );
        final categoriaId = await categories.crear(
          name: 'Servicios',
          type: CategoryType.gasto,
        );
        await obligations.crear(
          concept: 'Internet',
          categoryId: categoriaId,
          accountId: cuentaId,
          type: ObligationType.gastoFijo,
          frequency: ObligationFrequency.mensual,
          amountPerPeriodCentavos: 60000,
          paymentDay: 10,
          startDate: DateTime(2026, 9, 1),
        );

        await obligations.generarPagosPendientes(
          horizonte: DateTime(2026, 9, 16),
        );
        expect((await accounts.obtener(cuentaId)).currentBalance, 100000);

        final pendiente = (await transactions.watchPendientes().first).single;
        await transactions.confirmarPago(
          pendiente.id,
          fecha: DateTime(2026, 9, 10),
        );

        expect((await accounts.obtener(cuentaId)).currentBalance, 40000);
        final confirmada = await (db.select(
          db.transactions,
        )..where((t) => t.id.equals(pendiente.id))).getSingle();
        expect(confirmada.status, TransactionStatus.pagado);
        expect(confirmada.paymentDate, DateTime(2026, 9, 10));
      },
    );

    test('cancelarPago descarta una pendiente sin afectar el saldo', () async {
      final cuentaId = await accounts.crear(
        name: 'Débito',
        type: AccountType.debito,
        saldoInicialCentavos: 100000,
      );
      final categoriaId = await categories.crear(
        name: 'Suscripciones',
        type: CategoryType.gasto,
      );
      await obligations.crear(
        concept: 'Spotify',
        categoryId: categoriaId,
        accountId: cuentaId,
        type: ObligationType.gastoFijo,
        frequency: ObligationFrequency.mensual,
        amountPerPeriodCentavos: 15000,
        paymentDay: 5,
        startDate: DateTime(2026, 1, 1),
      );
      await obligations.generarPagosPendientes(
        horizonte: DateTime(2026, 1, 10),
      );
      final pendiente = (await transactions.watchPendientes().first).single;

      await transactions.cancelarPago(pendiente.id);

      expect((await accounts.obtener(cuentaId)).currentBalance, 100000);
      expect(await transactions.watchPendientes().first, isEmpty);
    });

    test(
      'obligación progresiva: saldoRestante solo baja con pagos confirmados y se finaliza en 0',
      () async {
        final cuentaId = await accounts.crear(
          name: 'Débito',
          type: AccountType.debito,
        );
        final categoriaId = await categories.crear(
          name: 'Préstamos',
          type: CategoryType.gasto,
        );
        final obligationId = await obligations.crear(
          concept: 'Préstamo laptop',
          categoryId: categoriaId,
          accountId: cuentaId,
          type: ObligationType.progresivo,
          frequency: ObligationFrequency.mensual,
          amountPerPeriodCentavos: 50000,
          paymentDay: 5,
          totalAmountCentavos: 100000,
          startDate: DateTime(2026, 1, 1),
        );

        expect(await obligations.saldoRestante(obligationId), 100000);

        await obligations.generarPagosPendientes(
          horizonte: DateTime(2026, 2, 10),
        );
        final pendientes = await transactions.watchPendientes().first;
        expect(pendientes.length, 2); // 5-ene y 5-feb

        // Una pendiente sin confirmar no reduce la deuda todavía.
        expect(await obligations.saldoRestante(obligationId), 100000);

        await transactions.confirmarPago(
          pendientes[0].id,
          fecha: pendientes[0].dueDate,
        );
        expect(await obligations.saldoRestante(obligationId), 50000);
        expect(
          (await obligations.obtener(obligationId)).status,
          ObligationStatus.activo,
        );

        await transactions.confirmarPago(
          pendientes[1].id,
          fecha: pendientes[1].dueDate,
        );
        expect(await obligations.saldoRestante(obligationId), 0);
        expect(
          (await obligations.obtener(obligationId)).status,
          ObligationStatus.finalizado,
        );
      },
    );

    test(
      'eliminar una obligación cancela sus pendientes pero conserva el historial pagado',
      () async {
        final cuentaId = await accounts.crear(
          name: 'Débito',
          type: AccountType.debito,
        );
        final categoriaId = await categories.crear(
          name: 'Servicios',
          type: CategoryType.gasto,
        );
        final obligationId = await obligations.crear(
          concept: 'Internet',
          categoryId: categoriaId,
          accountId: cuentaId,
          type: ObligationType.gastoFijo,
          frequency: ObligationFrequency.mensual,
          amountPerPeriodCentavos: 60000,
          paymentDay: 10,
          startDate: DateTime(2026, 8, 1),
        );
        await obligations.generarPagosPendientes(
          horizonte: DateTime(2026, 9, 16),
        );
        final pendientes = await transactions.watchPendientes().first;
        await transactions.confirmarPago(
          pendientes.first.id,
          fecha: pendientes.first.dueDate,
        );

        await obligations.eliminar(obligationId);

        expect(await transactions.watchPendientes().first, isEmpty);
        final historial = await transactions
            .watchByObligation(obligationId)
            .first;
        expect(
          historial.where((t) => t.status == TransactionStatus.pagado).length,
          1,
        );
        expect(
          historial
              .where((t) => t.status == TransactionStatus.cancelado)
              .length,
          1,
        );
      },
    );

    test(
      'obligación sin monto fijo genera pendientes en 0 y exige monto al confirmar',
      () async {
        final cuentaId = await accounts.crear(
          name: 'Débito',
          type: AccountType.debito,
        );
        final categoriaId = await categories.crear(
          name: 'Servicios',
          type: CategoryType.gasto,
        );
        await obligations.crear(
          concept: 'CFE',
          categoryId: categoriaId,
          accountId: cuentaId,
          type: ObligationType.gastoFijo,
          frequency: ObligationFrequency.mensual,
          // Sin amountPerPeriodCentavos: varía cada recibo.
          paymentDay: 10,
          startDate: DateTime(2026, 9, 1),
        );

        await obligations.generarPagosPendientes(
          horizonte: DateTime(2026, 9, 16),
        );
        final pendiente = (await transactions.watchPendientes().first).single;
        expect(pendiente.amount, 0);

        // No se puede confirmar sin indicar el monto real.
        expect(
          () => transactions.confirmarPago(
            pendiente.id,
            fecha: DateTime(2026, 9, 10),
          ),
          throwsArgumentError,
        );

        await transactions.confirmarPago(
          pendiente.id,
          fecha: DateTime(2026, 9, 10),
          montoCentavos: 45000,
        );

        expect((await accounts.obtener(cuentaId)).currentBalance, -45000);
        final confirmada = await (db.select(
          db.transactions,
        )..where((t) => t.id.equals(pendiente.id))).getSingle();
        expect(confirmada.amount, 45000);
        expect(confirmada.status, TransactionStatus.pagado);
      },
    );

    test(
      'confirmarPago con monto fijo permite sobreescribirlo si varió un poco',
      () async {
        final cuentaId = await accounts.crear(
          name: 'Débito',
          type: AccountType.debito,
        );
        final categoriaId = await categories.crear(
          name: 'Servicios',
          type: CategoryType.gasto,
        );
        await obligations.crear(
          concept: 'Internet',
          categoryId: categoriaId,
          accountId: cuentaId,
          type: ObligationType.gastoFijo,
          frequency: ObligationFrequency.mensual,
          amountPerPeriodCentavos: 60000,
          paymentDay: 10,
          startDate: DateTime(2026, 9, 1),
        );
        await obligations.generarPagosPendientes(
          horizonte: DateTime(2026, 9, 16),
        );
        final pendiente = (await transactions.watchPendientes().first).single;

        // Sin monto explícito, confirma con el que ya traía la pendiente.
        await transactions.confirmarPago(
          pendiente.id,
          fecha: DateTime(2026, 9, 10),
        );
        expect((await accounts.obtener(cuentaId)).currentBalance, -60000);
      },
    );

    test('gastadoEnRango no cuenta transacciones todavía pendientes', () async {
      final cuentaId = await accounts.crear(
        name: 'Débito',
        type: AccountType.debito,
      );
      final categoriaId = await categories.crear(
        name: 'Servicios',
        type: CategoryType.gasto,
        presupuestoQuincenalCentavos: 100000,
      );
      await obligations.crear(
        concept: 'Internet',
        categoryId: categoriaId,
        accountId: cuentaId,
        type: ObligationType.gastoFijo,
        frequency: ObligationFrequency.mensual,
        amountPerPeriodCentavos: 60000,
        paymentDay: 10,
        startDate: DateTime(2026, 9, 1),
      );
      await obligations.generarPagosPendientes(
        horizonte: DateTime(2026, 9, 16),
      );

      final desde = DateTime(2026, 9, 1);
      final hasta = DateTime(2026, 9, 16);
      expect(
        await categories.gastadoEnRango(
          categoriaId,
          desde: desde,
          hasta: hasta,
        ),
        0,
      );

      final pendiente = (await transactions.watchPendientes().first).single;
      await transactions.confirmarPago(
        pendiente.id,
        fecha: DateTime(2026, 9, 10),
      );

      expect(
        await categories.gastadoEnRango(
          categoriaId,
          desde: desde,
          hasta: hasta,
        ),
        60000,
      );
    });

    test(
      'transferir mueve el saldo de una cuenta a otra sin categoría',
      () async {
        final tdd = await accounts.crear(
          name: 'TDD',
          type: AccountType.debito,
          saldoInicialCentavos: 100000,
        );
        final efectivo = await accounts.crear(
          name: 'Efectivo',
          type: AccountType.efectivo,
        );

        final id = await transactions.transferir(
          concept: 'Retiro cajero',
          amountCentavos: 30000,
          fecha: DateTime(2026, 9, 5),
          cuentaOrigenId: tdd,
          cuentaDestinoId: efectivo,
        );

        expect((await accounts.obtener(tdd)).currentBalance, 70000);
        expect((await accounts.obtener(efectivo)).currentBalance, 30000);

        final fila = await (db.select(
          db.transactions,
        )..where((t) => t.id.equals(id))).getSingle();
        expect(fila.type, TransactionType.transferencia);
        expect(fila.status, TransactionStatus.pagado);
        expect(fila.categoryId, isNull);
        expect(fila.destinationAccountId, efectivo);
      },
    );

    test('transferir rechaza origen y destino iguales', () async {
      final tdd = await accounts.crear(name: 'TDD', type: AccountType.debito);

      expect(
        () => transactions.transferir(
          concept: 'Transferencia inválida',
          amountCentavos: 1000,
          fecha: DateTime(2026, 9, 5),
          cuentaOrigenId: tdd,
          cuentaDestinoId: tdd,
        ),
        throwsArgumentError,
      );
    });

    test(
      'eliminar una transferencia revierte el saldo de ambas cuentas',
      () async {
        final tdd = await accounts.crear(
          name: 'TDD',
          type: AccountType.debito,
          saldoInicialCentavos: 100000,
        );
        final tdc = await accounts.crear(
          name: 'TDC',
          type: AccountType.credito,
          limiteCreditoCentavos: 1000000,
        );

        final id = await transactions.transferir(
          concept: 'Pago tarjeta de crédito',
          amountCentavos: 40000,
          fecha: DateTime(2026, 9, 5),
          cuentaOrigenId: tdd,
          cuentaDestinoId: tdc,
        );

        await transactions.eliminar(id);

        expect((await accounts.obtener(tdd)).currentBalance, 100000);
        expect((await accounts.obtener(tdc)).currentBalance, 0);
      },
    );

    test('una transferencia no cuenta como gasto ni ingreso', () async {
      final tdd = await accounts.crear(
        name: 'TDD',
        type: AccountType.debito,
        saldoInicialCentavos: 100000,
      );
      final efectivo = await accounts.crear(
        name: 'Efectivo',
        type: AccountType.efectivo,
      );

      await transactions.transferir(
        concept: 'Retiro cajero',
        amountCentavos: 20000,
        fecha: DateTime(2026, 9, 5),
        cuentaOrigenId: tdd,
        cuentaDestinoId: efectivo,
      );

      expect(
        await transactions.watchByType(TransactionType.gasto).first,
        isEmpty,
      );
      expect(
        await transactions.watchByType(TransactionType.ingreso).first,
        isEmpty,
      );
    });

    test(
      'no se puede eliminar una cuenta que es destino de una transferencia',
      () async {
        final tdd = await accounts.crear(
          name: 'TDD',
          type: AccountType.debito,
          saldoInicialCentavos: 100000,
        );
        final efectivo = await accounts.crear(
          name: 'Efectivo',
          type: AccountType.efectivo,
        );

        await transactions.transferir(
          concept: 'Retiro cajero',
          amountCentavos: 20000,
          fecha: DateTime(2026, 9, 5),
          cuentaOrigenId: tdd,
          cuentaDestinoId: efectivo,
        );

        expect(
          () => accounts.eliminar(efectivo),
          throwsA(isA<RegistroEnUsoException>()),
        );
      },
    );
  });
}
