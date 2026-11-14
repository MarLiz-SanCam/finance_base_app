import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/money.dart';
import '../../../core/periodo_quincenal.dart';
import '../../../data/db/app_database.dart';
import '../../../providers/accounts_providers.dart';
import '../../../providers/ingresos_dashboard_providers.dart';

/// Total ingresado en la quincena actual, y el saldo disponible en cada
/// cuenta. Registrar un ingreso nuevo se dispara desde el botón central de
/// la barra de navegación, no desde aquí.
class HeaderResumenIngresos extends ConsumerWidget {
  const HeaderResumenIngresos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(ingresoQuincenaActualProvider);
    final cuentasAsync = ref.watch(accountsStreamProvider);
    final periodo = PeriodoQuincenal.actual();
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresos del período ${periodo.etiqueta()}',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            totalAsync.when(
              data: (centavos) => Text(
                Money.centavosAPesos(centavos),
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade600,
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Text(
                'No se pudo calcular',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            cuentasAsync.when(
              data: (cuentas) {
                if (cuentas.isEmpty) {
                  return Text(
                    'No hay cuentas registradas todavía.',
                    style: theme.textTheme.bodySmall,
                  );
                }
                return SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cuentas.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 20),
                    itemBuilder: (context, index) =>
                        _CuentaDisponible(cuenta: cuentas[index]),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                'No se pudieron cargar las cuentas',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CuentaDisponible extends StatelessWidget {
  const _CuentaDisponible({required this.cuenta});

  final Account cuenta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.universal_currency_alt, size: 14, color: Colors.green.shade600),
            const SizedBox(width: 4),
            Text(
              cuenta.name,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          Money.centavosAPesos(cuenta.currentBalance),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
