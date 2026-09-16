import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/db/app_database.dart';
import '../../providers/accounts_providers.dart';
import 'form_cuenta.dart';

const _etiquetasTipo = {
  'efectivo': 'Efectivo',
  'debito': 'Débito',
  'credito': 'Crédito',
};

/// Lista de cuentas con su saldo actual. Tocar una la edita; el botón
/// flotante crea una nueva.
class DashCuentasPage extends ConsumerWidget {
  const DashCuentasPage({super.key});

  void _abrirFormulario(BuildContext context, {Account? cuenta}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormCuentaPage(cuentaExistente: cuenta),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentasAsync = ref.watch(accountsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas')),
      body: cuentasAsync.when(
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
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cuenta = cuentas[index];
              return Card(
                child: ListTile(
                  title: Text(cuenta.name),
                  subtitle: Text(_etiquetasTipo[cuenta.type.name]!),
                  trailing: Text(
                    Money.centavosAPesos(cuenta.currentBalance),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cuenta.currentBalance < 0
                          ? theme.colorScheme.error
                          : null,
                    ),
                  ),
                  onTap: () => _abrirFormulario(context, cuenta: cuenta),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Error al cargar cuentas: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(context),
        tooltip: 'Nueva cuenta',
        child: const Icon(Icons.add),
      ),
    );
  }
}
