import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../core/components/amount_text.dart';
import '../../core/components/app_card.dart';
import '../../core/components/app_showcase.dart';
import '../../core/showcase/showcase_keys.dart';
import '../../core/credit_card_schedule.dart';
import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../data/db/enums.dart';
import '../../providers/accounts_providers.dart';
import '../../providers/database_provider.dart';
import 'form_cuenta.dart';

/// Contenido del tab "Cuentas" de Organización: lista de cuentas con su
/// saldo actual. El lápiz abre la edición; el bote de basura borra
/// directamente (con confirmación). Crear una cuenta nueva y transferir
/// entre cuentas se disparan desde [OrganizacionPage].
class CuentasTabContent extends ConsumerWidget {
  const CuentasTabContent({super.key});

  void _abrirFormulario(BuildContext context, {Account? cuenta}) {
    mostrarFormularioCuenta(context, cuentaExistente: cuenta);
  }

  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    Account cuenta,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar cuenta?'),
        content: Text(
          'Se eliminará "${cuenta.name}". Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    try {
      await ref.read(accountsRepositoryProvider).eliminar(cuenta.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentasAsync = ref.watch(accountsStreamProvider);
    final theme = Theme.of(context);

    return cuentasAsync.when(
      data: (cuentas) {
        if (cuentas.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No hay cuentas registradas todavía.'),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: cuentas.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final cuenta = cuentas[index];
            final tarjeta = AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cuenta.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _abrirFormulario(context, cuenta: cuenta),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar cuenta',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(left: 12),
                      ),
                      IconButton(
                        onPressed: () => _eliminar(context, ref, cuenta),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Eliminar cuenta',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(left: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (cuenta.type == AccountType.credito &&
                      cuenta.creditLimit != null)
                    _ResumenCredito(cuenta: cuenta)
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(MdiIcons.cash, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        AppAmountText(
                          cuenta.currentBalance,
                          colorBySign: true,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
            // Solo la primera cuenta es un paso del showcase.
            if (index != 0) return tarjeta;
            return AppShowcase(
              showcaseKey: ShowcaseKeys.cuentasPrimera,
              title: 'Tus cuentas',
              description:
                  'Cada tarjeta es una cuenta con su saldo actual. Usa el lápiz para editarla y el bote de basura para eliminarla.',
              borderRadius: 16,
              child: tarjeta,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Error al cargar cuentas: $error')),
    );
  }
}

/// Resumen de una cuenta de crédito: crédito disponible, barra de uso, deuda
/// (o saldo a favor) y próximas fechas de corte y pago. En crédito el saldo
/// negativo es deuda, así que disponible = límite + saldo; un saldo positivo
/// es saldo a favor y deja el disponible por encima del límite.
class _ResumenCredito extends StatelessWidget {
  const _ResumenCredito({required this.cuenta});

  final Account cuenta;

  String _textoFecha(String etiqueta, int dia, DateTime hoy) {
    final fecha = CreditCardSchedule.proximaFecha(dia, hoy);
    final dias = CreditCardSchedule.diasHasta(fecha, hoy);
    final cuando = switch (dias) {
      0 => 'hoy',
      1 => 'mañana',
      _ => 'en $dias días',
    };
    return '$etiqueta: ${fecha.day}/${fecha.month} ($cuando)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limite = cuenta.creditLimit!;
    final saldo = cuenta.currentBalance;
    final deuda = saldo < 0 ? -saldo : 0;
    final disponible = limite + saldo;
    final uso = limite > 0 ? (deuda / limite).clamp(0.0, 1.0) : 0.0;
    final colorUso = uso >= 0.9
        ? AppAmountText.negative(context)
        : theme.colorScheme.primary;
    final etiqueta = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final hoy = DateTime.now();
    final corte = cuenta.statementDay;
    final pago = cuenta.paymentDueDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(MdiIcons.creditCardOutline, color: colorUso),
            const SizedBox(width: 8),
            Expanded(
              child: AppAmountText(
                disponible < 0 ? 0 : disponible,
                color: colorUso,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text('disponible', style: etiqueta),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: uso,
            minHeight: 6,
            color: colorUso,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          saldo > 0
              ? 'Saldo a favor ${Money.centavosAPesos(saldo)} · '
                    'Límite ${Money.centavosAPesos(limite)}'
              : 'Deuda ${Money.centavosAPesos(deuda)} de '
                    '${Money.centavosAPesos(limite)}',
          style: etiqueta,
        ),
        if (corte != null)
          Text(_textoFecha('Corte', corte, hoy), style: etiqueta),
        if (pago != null) Text(_textoFecha('Pago', pago, hoy), style: etiqueta),
      ],
    );
  }
}
