import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/permisos.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../data/mock/mock_data.dart' hide Medicamento;
import '../../data/mock/providers.dart';
import '../../data/services/farmacia_service.dart';
import '../../features/auth/providers/auth_provider.dart';

const _categorias = [
  'Analgésico',
  'Antibiótico',
  'Antiinflamatorio',
  'Vitamina',
  'Otro',
];

const _unidades = [
  'tabletas',
  'capsulas',
  'ml',
  'mg',
  'frascos',
  'cajas',
];

class FarmaciaScreen extends ConsumerStatefulWidget {
  const FarmaciaScreen({super.key});

  @override
  ConsumerState<FarmaciaScreen> createState() => _FarmaciaScreenState();
}

class _FarmaciaScreenState extends ConsumerState<FarmaciaScreen> {
  final _busquedaCtrl = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  int _sidebarIndex(RolUsuario? rol) =>
      rol == RolUsuario.administradora ? 3 : 0;

  List<Medicamento> _filtrar(List<Medicamento> meds) {
    if (_busqueda.isEmpty) return meds;
    final q = _busqueda.toLowerCase();
    return meds.where((m) {
      return m.nombre.toLowerCase().contains(q) ||
          m.nombreGenerico.toLowerCase().contains(q) ||
          m.codigoBarras.toLowerCase().contains(q) ||
          m.codigoInterno.toLowerCase().contains(q) ||
          m.estante.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(usuarioActivoProvider);
    final rol = usuario?.rol;
    final medsAsync = ref.watch(medicamentosStreamProvider);
    final alertas = ref.watch(alertasFarmaciaProvider);

    return AppShell(
      selectedIndex: _sidebarIndex(rol),
      onNavigate: (_) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Inventario Farmacia',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                const Spacer(),
                _BotonAlertas(
                  count: alertas.total,
                  onTap: () => context.go('/farmacia/alertas'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go('/farmacia/movimientos'),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Movimientos'),
                ),
                const SizedBox(width: 12),
                if (Permisos.puedeGestionarMedicamentos(rol))
                  ElevatedButton.icon(
                    onPressed: () => _abrirFormulario(context, null),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar Medicamento'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Buscador ──────────────────────────────────────────────────
            TextField(
              controller: _busquedaCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código o estante...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _busqueda = '');
                          _busquedaCtrl.clear();
                        },
                      )
                    : const Icon(Icons.qr_code_scanner),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              onChanged: (v) => setState(() => _busqueda = v),
            ),
            const SizedBox(height: 16),
            // ── Lista ─────────────────────────────────────────────────────
            medsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: AppColors.danger)),
              data: (meds) {
                final filtrados = _filtrar(meds);
                if (meds.isEmpty) {
                  return _vacio('No hay medicamentos registrados');
                }
                if (filtrados.isEmpty) {
                  return _vacio('Sin resultados para "$_busqueda"');
                }
                return Column(
                  children: [
                    _Resumen(meds: meds),
                    const SizedBox(height: 12),
                    ...filtrados.map((m) => _MedicamentoCard(
                          med: m,
                          puedeEditar:
                              Permisos.puedeGestionarMedicamentos(rol),
                          puedeEliminar:
                              Permisos.puedeEliminarMedicamentos(rol),
                          onEditar: () => _abrirFormulario(context, m),
                          onEliminar: () => _confirmarEliminar(m),
                        )),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _vacio(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(msg,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );

  void _abrirFormulario(BuildContext context, Medicamento? med) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormularioMedicamentoDialog(medicamento: med),
    );
  }

  Future<void> _confirmarEliminar(Medicamento med) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar medicamento?'),
        content: Text(
            'Esta acción no se puede deshacer. El historial de movimientos de "${med.nombre}" se conservará.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await ref.read(farmaciaServiceProvider).eliminarMedicamento(med.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medicamento eliminado'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }
}

// ── Resumen rápido (totales / alertas) ──────────────────────────────────────

class _Resumen extends StatelessWidget {
  final List<Medicamento> meds;
  const _Resumen({required this.meds});

  @override
  Widget build(BuildContext context) {
    final bajos = meds.where((m) => m.stockBajo).length;
    return Row(
      children: [
        _chip('${meds.length} medicamentos', AppColors.primary, Icons.inventory_2),
        const SizedBox(width: 12),
        if (bajos > 0)
          _chip('$bajos con stock bajo', AppColors.danger, Icons.warning_amber),
      ],
    );
  }

  Widget _chip(String label, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      );
}

// ── Tarjeta de medicamento ──────────────────────────────────────────────────

class _MedicamentoCard extends StatelessWidget {
  final Medicamento med;
  final bool puedeEditar;
  final bool puedeEliminar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _MedicamentoCard({
    required this.med,
    required this.puedeEditar,
    required this.puedeEliminar,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Códigos
          SizedBox(
            width: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.codigoInterno,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                if (med.codigoBarras.isNotEmpty)
                  Text(med.codigoBarras,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Nombre + detalle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(med.nombre,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    if (med.requiereReceta) ...[
                      const SizedBox(width: 8),
                      _miniBadge('Receta', AppColors.warning),
                    ],
                  ],
                ),
                if (med.nombreGenerico.isNotEmpty)
                  Text(med.nombreGenerico,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  '${med.presentacion.isNotEmpty ? '${med.presentacion} · ' : ''}${med.categoria}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                if (med.fechaVencimiento.isNotEmpty)
                  Text('Vence: ${med.fechaVencimiento}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Estante
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estante',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
                Text(med.estante.isEmpty ? '—' : med.estante,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // Stock + precio
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _stockBadge(),
                const SizedBox(height: 4),
                Text('Q ${med.precioVenta.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          // Acciones
          if (puedeEditar || puedeEliminar)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (puedeEditar)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.primary),
                    tooltip: 'Editar',
                    onPressed: onEditar,
                  ),
                if (puedeEliminar)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.danger),
                    tooltip: 'Eliminar',
                    onPressed: onEliminar,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _stockBadge() {
    Color color;
    String label;
    if (med.sinStock) {
      color = AppColors.danger;
      label = 'SIN STOCK';
    } else if (med.stockBajo) {
      color = AppColors.warning;
      label = 'STOCK BAJO';
    } else {
      color = AppColors.success;
      label = 'En stock';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label · ${med.cantidad} ${med.unidad}',
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _miniBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700, color: color)),
      );
}

// ── Botón de alertas con badge ──────────────────────────────────────────────

class _BotonAlertas extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _BotonAlertas({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hay = count > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton.icon(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: hay ? AppColors.danger : AppColors.textSecondary,
            side: BorderSide(
                color: hay ? AppColors.danger : AppColors.border),
          ),
          icon: Icon(hay ? Icons.warning_amber : Icons.notifications_none,
              size: 18),
          label: const Text('Alertas'),
        ),
        if (hay)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 20),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DIALOG: Formulario agregar/editar medicamento
// ════════════════════════════════════════════════════════════════════════════

class _FormularioMedicamentoDialog extends ConsumerStatefulWidget {
  final Medicamento? medicamento;
  const _FormularioMedicamentoDialog({this.medicamento});

  @override
  ConsumerState<_FormularioMedicamentoDialog> createState() =>
      _FormularioMedicamentoDialogState();
}

class _FormularioMedicamentoDialogState
    extends ConsumerState<_FormularioMedicamentoDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _genericoCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _codigoBarrasCtrl = TextEditingController();
  final _codigoInternoCtrl = TextEditingController();
  final _presentacionCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _estanteCtrl = TextEditingController();
  final _descEstanteCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _cantidadAgregarCtrl = TextEditingController();
  final _cantidadMinCtrl = TextEditingController();
  final _precioCompraCtrl = TextEditingController();
  final _precioVentaCtrl = TextEditingController();
  final _vencimientoCtrl = TextEditingController();

  String _categoria = 'Otro';
  String _unidad = 'tabletas';
  bool _requiereReceta = false;
  bool _guardando = false;

  bool _esAdmin = false;
  bool _esFarmaceutica = false;
  int _cantidadActual = 0;

  bool get _esEdicion => widget.medicamento != null;

  /// La farmacéutica, al EDITAR, solo puede agregar unidades (no reemplazar).
  bool get _modoAgregar => _esFarmaceutica && _esEdicion;

  @override
  void initState() {
    super.initState();
    final rol = ref.read(usuarioActivoProvider)?.rol;
    _esAdmin = rol == RolUsuario.administradora;
    _esFarmaceutica = rol == RolUsuario.farmaceutica;
    _cantidadActual = widget.medicamento?.cantidad ?? 0;
    final m = widget.medicamento;
    if (m != null) {
      _nombreCtrl.text = m.nombre;
      _genericoCtrl.text = m.nombreGenerico;
      _marcaCtrl.text = m.marca;
      _codigoBarrasCtrl.text = m.codigoBarras;
      _codigoInternoCtrl.text = m.codigoInterno;
      _presentacionCtrl.text = m.presentacion;
      _descripcionCtrl.text = m.descripcion;
      _estanteCtrl.text = m.estante;
      _descEstanteCtrl.text = m.descripcionEstante;
      _cantidadCtrl.text = m.cantidad.toString();
      _cantidadMinCtrl.text = m.cantidadMinima.toString();
      _precioCompraCtrl.text = m.precioCompra.toStringAsFixed(2);
      _precioVentaCtrl.text = m.precioVenta.toStringAsFixed(2);
      _vencimientoCtrl.text = m.fechaVencimiento;
      _categoria = _categorias.contains(m.categoria) ? m.categoria : 'Otro';
      _unidad = _unidades.contains(m.unidad) ? m.unidad : 'tabletas';
      _requiereReceta = m.requiereReceta;
    } else {
      _generarCodigoInterno();
    }
  }

  Future<void> _generarCodigoInterno() async {
    final codigo =
        await ref.read(farmaciaServiceProvider).generarCodigoInterno();
    if (mounted) _codigoInternoCtrl.text = codigo;
  }

  @override
  void dispose() {
    for (final c in [
      _nombreCtrl, _genericoCtrl, _marcaCtrl, _codigoBarrasCtrl,
      _codigoInternoCtrl, _presentacionCtrl, _descripcionCtrl, _estanteCtrl,
      _descEstanteCtrl, _cantidadCtrl, _cantidadAgregarCtrl, _cantidadMinCtrl,
      _precioCompraCtrl, _precioVentaCtrl, _vencimientoCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 640,
        constraints: const BoxConstraints(maxHeight: 720),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _esEdicion ? 'Editar Medicamento' : 'Nuevo Medicamento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _seccion('Identificación'),
                      _row2(
                        _campo('Nombre *', _nombreCtrl,
                            validator: _requerido),
                        _campo('Nombre genérico', _genericoCtrl),
                      ),
                      _row2(
                        _campo('Marca / Laboratorio', _marcaCtrl),
                        _campo('Código interno', _codigoInternoCtrl,
                            enabled: false),
                      ),
                      // Código de barras (soporte lector)
                      TextFormField(
                        controller: _codigoBarrasCtrl,
                        autofocus: !_esEdicion,
                        decoration: const InputDecoration(
                          labelText: 'Código de barras',
                          helperText:
                              'Escanee con el lector o escriba manualmente',
                          suffixIcon: Icon(Icons.barcode_reader),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _row2(
                        _dropdown('Categoría', _categoria, _categorias,
                            (v) => setState(() => _categoria = v!)),
                        _campo('Presentación', _presentacionCtrl,
                            hint: 'Caja x 10 tabletas'),
                      ),
                      _campo('Descripción', _descripcionCtrl, maxLines: 2),
                      const SizedBox(height: 8),
                      _seccion('Ubicación'),
                      _row2(
                        _campo('Estante *', _estanteCtrl,
                            hint: 'A-1', validator: _requerido),
                        _campo('Descripción del estante', _descEstanteCtrl),
                      ),
                      const SizedBox(height: 8),
                      _seccion('Inventario'),
                      _buildCampoCantidad(),
                      const SizedBox(height: 12),
                      _row2(
                        _campo('Cantidad mínima', _cantidadMinCtrl,
                            keyboard: TextInputType.number,
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ]),
                        _dropdown('Unidad de medida', _unidad, _unidades,
                            (v) => setState(() => _unidad = v!)),
                      ),
                      const SizedBox(height: 16),
                      _seccion('Precios y fechas'),
                      _row2(
                        _campo('Precio de compra (Q)', _precioCompraCtrl,
                            keyboard: const TextInputType.numberWithOptions(
                                decimal: true),
                            formatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'))
                            ]),
                        _campo('Precio de venta (Q)', _precioVentaCtrl,
                            keyboard: const TextInputType.numberWithOptions(
                                decimal: true),
                            formatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'))
                            ]),
                      ),
                      _campo('Fecha de vencimiento', _vencimientoCtrl,
                          hint: 'AAAA-MM-DD'),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Requiere receta',
                            style: TextStyle(fontSize: 14)),
                        value: _requiereReceta,
                        activeColor: AppColors.primary,
                        onChanged: (v) =>
                            setState(() => _requiereReceta = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _guardando
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_esEdicion ? 'Guardar cambios' : 'Agregar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers de UI ─────────────────────────────────────────────────────────

  Widget _seccion(String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(titulo,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontFamily: GoogleFonts.dmSans().fontFamily)),
      );

  Widget _row2(Widget a, Widget b) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 12),
            Expanded(child: b),
          ],
        ),
      );

  Widget _campo(
    String label,
    TextEditingController ctrl, {
    String? hint,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextFormField(
        controller: ctrl,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboard,
        inputFormatters: formatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: onChanged,
    );
  }

  /// Campo de cantidad: editable para admin / alta nueva; modo "agregar" para
  /// la farmacéutica al editar (solo puede sumar unidades).
  Widget _buildCampoCantidad() {
    if (!_modoAgregar) {
      return _campo('Cantidad en stock *', _cantidadCtrl,
          hint: _esAdmin ? 'Puedes aumentar o reducir' : null,
          validator: _requerido,
          keyboard: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly]);
    }

    final agregar = int.tryParse(_cantidadAgregarCtrl.text.trim()) ?? 0;
    final nuevoTotal = _cantidadActual + agregar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stock actual (referencia, no editable)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Stock actual: $_cantidadActual ${_unidad}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cantidadAgregarCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Agregar unidades al stock',
            hintText: 'Ej: 50',
            helperText: 'Se sumará al stock actual',
            prefixIcon: Icon(Icons.add_circle, color: AppColors.success),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final n = int.tryParse(value) ?? 0;
              if (n <= 0) return 'Ingresa una cantidad positiva';
            }
            return null;
          },
        ),
        if (agregar > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nuevo stock: $_cantidadActual + $agregar = $nuevoTotal ${_unidad}',
                    style: const TextStyle(
                        color: AppColors.success, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String? _requerido(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      final usuario = ref.read(usuarioActivoProvider);
      final service = ref.read(farmaciaServiceProvider);

      // Cantidad final según el rol/modo.
      final int cantidadFinal;
      if (_modoAgregar) {
        final agregar = int.tryParse(_cantidadAgregarCtrl.text.trim()) ?? 0;
        cantidadFinal = _cantidadActual + agregar;
      } else {
        cantidadFinal = int.tryParse(_cantidadCtrl.text.trim()) ?? 0;
      }

      // Salvaguarda: la farmacéutica nunca puede reducir stock.
      if (_modoAgregar && cantidadFinal < _cantidadActual) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No tienes permiso para reducir el stock. Solo puedes agregar unidades.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      final med = Medicamento(
        id: widget.medicamento?.id ?? '',
        nombre: _nombreCtrl.text.trim(),
        nombreGenerico: _genericoCtrl.text.trim(),
        marca: _marcaCtrl.text.trim(),
        codigoBarras: _codigoBarrasCtrl.text.trim(),
        codigoInterno: _codigoInternoCtrl.text.trim(),
        estante: _estanteCtrl.text.trim(),
        descripcionEstante: _descEstanteCtrl.text.trim(),
        cantidad: cantidadFinal,
        cantidadMinima: int.tryParse(_cantidadMinCtrl.text.trim()) ?? 0,
        unidad: _unidad,
        categoria: _categoria,
        descripcion: _descripcionCtrl.text.trim(),
        presentacion: _presentacionCtrl.text.trim(),
        precioCompra: double.tryParse(_precioCompraCtrl.text.trim()) ?? 0,
        precioVenta: double.tryParse(_precioVentaCtrl.text.trim()) ?? 0,
        requiereReceta: _requiereReceta,
        fechaVencimiento: _vencimientoCtrl.text.trim(),
      );

      if (_esEdicion) {
        await service.actualizarMedicamento(med.id, med,
            uid: usuario?.id ?? '');
        // Registrar movimiento si cambió la cantidad.
        if (cantidadFinal != _cantidadActual) {
          final aumento = cantidadFinal > _cantidadActual;
          await service.registrarMovimiento(
            tipo: aumento ? 'entrada' : 'ajuste',
            medicamentoId: med.id,
            nombreMedicamento: med.nombre,
            cantidadAnterior: _cantidadActual,
            cantidadNueva: cantidadFinal,
            motivo: aumento
                ? 'Ingreso de stock'
                : 'Ajuste de inventario (Admin)',
            uid: usuario?.id ?? '',
            nombreResponsable: usuario?.nombre ?? '',
          );
        }
      } else {
        await service.crearMedicamento(med,
            uid: usuario?.id ?? '', nombreCreador: usuario?.nombre ?? '');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_esEdicion
                ? 'Medicamento actualizado'
                : 'Medicamento agregado'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }
}
