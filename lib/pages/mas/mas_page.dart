import 'package:flutter/material.dart';

import '../categorias/dash_categorias.dart';
import '../cuentas/dash_cuentas.dart';
import '../obligaciones/dash_obligaciones.dart';

/// Menú de acceso a los catálogos base (cuentas, categorías) y al motor de
/// obligaciones. Sin AppBar: el título vive en el body, igual que el resto
/// de dashboards.
class MasPage extends StatelessWidget {
  const MasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Más',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _ItemMenu(
              icono: Icons.account_balance_wallet_outlined,
              titulo: 'Cuentas',
              subtitulo: 'Efectivo, débito, crédito',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DashCuentasPage()),
              ),
            ),
            _ItemMenu(
              icono: Icons.category_outlined,
              titulo: 'Categorías',
              subtitulo: 'Clasificación de ingresos y gastos',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DashCategoriasPage()),
              ),
            ),
            _ItemMenu(
              icono: Icons.repeat,
              titulo: 'Obligaciones',
              subtitulo: 'Gastos fijos, créditos e ingresos fijos',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DashObligacionesPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icono),
        title: Text(titulo),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
