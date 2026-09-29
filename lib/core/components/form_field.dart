import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Ícono pequeño + etiqueta en una fila, usado arriba de [AppFormTextField]
/// y [AppFormDropdownField]. Público para poder encabezar del mismo modo
/// una sección de formulario que no es un campo de texto/dropdown (ej. el
/// selector de color de categorías).
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Relleno/borde del campo, compartidos por [AppFormTextField] y
/// [AppFormDropdownField]. Usa tokens de [ColorScheme] (no colores fijos)
/// para adoptar la paleta final de la app en cuanto se defina — ver el
/// comentario sobre la paleta provisional en `main.dart`.
InputDecoration _decoracionCampo(
  ColorScheme colorScheme, {
  String? hintText,
  String? prefixText,
}) {
  OutlineInputBorder borde(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hintText,
    prefixText: prefixText,
    filled: true,
    fillColor: colorScheme.primaryContainer.withValues(alpha: 0.25),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: borde(colorScheme.primary.withValues(alpha: 0.35)),
    enabledBorder: borde(colorScheme.primary.withValues(alpha: 0.35)),
    focusedBorder: borde(colorScheme.primary, width: 1.5),
    errorBorder: borde(colorScheme.error),
    focusedErrorBorder: borde(colorScheme.error, width: 1.5),
  );
}

/// Campo de texto de un formulario: ícono + etiqueta arriba, campo con
/// relleno suave y borde redondeado abajo. Pensado para los formularios que
/// viven dentro de una hoja inferior (ver `FormCuentaSheet`), un campo por
/// cada dato a capturar.
class AppFormTextField extends StatelessWidget {
  const AppFormTextField({
    super.key,
    required this.icon,
    required this.label,
    this.controller,
    this.hintText,
    this.prefixText,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLength,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final String? prefixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final bool autofocus;

  /// Para campos que se llenan con un selector en vez de escribiéndose (ej.
  /// una fecha vía `showDatePicker`): `readOnly: true` + [onTap] abre el
  /// selector y el texto se actualiza a mano en el controller.
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFieldLabel(icon: icon, label: label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          autofocus: autofocus,
          maxLength: maxLength,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          textCapitalization: textCapitalization,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: _decoracionCampo(
            colorScheme,
            hintText: hintText,
            prefixText: prefixText,
          ),
        ),
      ],
    );
  }
}

/// Selector desplegable con la misma presentación que [AppFormTextField]
/// (ícono + etiqueta arriba, campo abajo), para los datos de un formulario
/// que se eligen de una lista en vez de escribirse (ej. tipo de cuenta,
/// categoría, frecuencia).
class AppFormDropdownField<T> extends StatelessWidget {
  const AppFormDropdownField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
  });

  final IconData icon;
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;

  /// `null` deshabilita el dropdown (se ve el valor actual pero no se puede
  /// cambiar), ej. el tipo de una categoría/cuenta ya existente.
  final ValueChanged<T?>? onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFieldLabel(icon: icon, label: label),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: _decoracionCampo(colorScheme, hintText: hintText),
        ),
      ],
    );
  }
}
