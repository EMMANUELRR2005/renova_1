import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Widgets reutilizables del sistema de diseño Renova.
/// Estos componentes encapsulan el lenguaje visual moderno (bordes redondeados,
/// sombras suaves, colores del tema) para usarse en cualquier pantalla.

/// Sombra suave estándar de las tarjetas.
const List<BoxShadow> kSombraSuave = [
  BoxShadow(
    color: Color(0x0F000000), // negro 6%
    blurRadius: 10,
    offset: Offset(0, 4),
  ),
];

/// Card de estadística (KPI) para dashboards.
Widget buildStatCard({
  required String titulo,
  required String valor,
  required String subtitulo,
  required IconData icono,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: kSombraSuave,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: color, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(valor,
            style: TextStyle(
                color: color, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitulo,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

/// Card de sección genérica con título, subtítulo opcional y contenido.
Widget buildSectionCard({
  required String titulo,
  String? subtitulo,
  required Widget child,
  Widget? trailing,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: kSombraSuave,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    if (subtitulo != null)
                      Text(subtitulo,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(padding: const EdgeInsets.all(20), child: child),
      ],
    ),
  );
}

/// Resuelve color + ícono para un estado dado.
({Color color, IconData icono}) estiloEstado(String estado) {
  switch (estado.toLowerCase()) {
    case 'activo':
    case 'confirmada':
    case 'completada':
    case 'pagado':
      return (color: AppColors.success, icono: Icons.check_circle_outline);
    case 'inactivo':
    case 'cancelada':
    case 'anulado':
      return (color: AppColors.danger, icono: Icons.cancel_outlined);
    case 'pendiente':
      return (color: AppColors.warning, icono: Icons.schedule_outlined);
    default:
      return (color: AppColors.neutral, icono: Icons.info_outline);
  }
}

/// Badge de estado moderno (pastilla con color e ícono).
Widget buildBadgeEstado(String estado, {String? label}) {
  final e = estiloEstado(estado);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: e.color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(e.icono, color: e.color, size: 12),
        const SizedBox(width: 4),
        Text(label ?? _cap(estado),
            style: TextStyle(
                color: e.color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Tipo de mensaje para los snackbars modernos.
enum TipoMensaje { exito, error, info, advertencia }

/// Muestra un SnackBar flotante moderno con ícono según el tipo.
void mostrarSnackbar(BuildContext context, String mensaje,
    {TipoMensaje tipo = TipoMensaje.info}) {
  Color color;
  IconData icono;
  switch (tipo) {
    case TipoMensaje.exito:
      color = AppColors.success;
      icono = Icons.check_circle_outline;
      break;
    case TipoMensaje.error:
      color = AppColors.danger;
      icono = Icons.error_outline;
      break;
    case TipoMensaje.advertencia:
      color = AppColors.warning;
      icono = Icons.warning_amber_outlined;
      break;
    case TipoMensaje.info:
      color = AppColors.primary;
      icono = Icons.info_outline;
      break;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      content: Row(
        children: [
          Icon(icono, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(mensaje)),
        ],
      ),
    ),
  );
}

/// Diálogo de confirmación moderno (radio 20, ícono en el título).
Future<bool> confirmarDialog(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  IconData icono = Icons.help_outline,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool peligroso = false,
}) async {
  final color = peligroso ? AppColors.danger : AppColors.primary;
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(titulo)),
        ],
      ),
      content: Text(mensaje),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: color),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return res ?? false;
}
