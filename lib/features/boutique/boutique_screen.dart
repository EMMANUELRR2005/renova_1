import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/permisos.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/widgets_comunes.dart';
import '../../data/mock/mock_data.dart';
import '../../data/mock/providers.dart';
import '../../data/services/boutique_service.dart';
import '../../features/auth/providers/auth_provider.dart';

const _categorias = [
  'Uniformes',
  'Accesorios',
  'Calzado',
  'Equipamiento',
  'Cuidado Personal',
  'Otro',
];

class BoutiqueScreen extends ConsumerStatefulWidget {
  const BoutiqueScreen({super.key});

  @override
  ConsumerState<BoutiqueScreen> createState() => _BoutiqueScreenState();
}

class _BoutiqueScreenState extends ConsumerState<BoutiqueScreen> {
  final _busquedaCtrl = TextEditingController();
  String _busqueda = '';
  String? _categoriaSeleccionada;
  String? _tallaFiltro;

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  int _sidebarIndex(RolUsuario? rol) =>
      rol == RolUsuario.administradora ? 6 : 0;

  List<ProductoBoutique> _filtrar(List<ProductoBoutique> ps) {
    var lista = ps;

    // Filtro por categoría
    if (_categoriaSeleccionada != null) {
      lista =
          lista.where((p) => p.categoria == _categoriaSeleccionada).toList();
    }

    // Filtro por talla
    if (_tallaFiltro != null) {
      lista = lista
          .where((p) => p.talla.toLowerCase() == _tallaFiltro!.toLowerCase())
          .toList();
    }

    // Filtro por búsqueda de texto
    if (_busqueda.isNotEmpty) {
      final q = _busqueda.toLowerCase();
      lista = lista.where((p) {
        return p.nombre.toLowerCase().contains(q) ||
            p.codigoBarras.toLowerCase().contains(q) ||
            p.codigoInterno.toLowerCase().contains(q) ||
            p.talla.toLowerCase().contains(q) ||
            p.categoria.toLowerCase().contains(q) ||
            p.estante.toLowerCase().contains(q);
      }).toList();
    }

    return lista;
  }

  /// Agrupa todos los productos por nombre para mostrar, en cada tarjeta, las
  /// demás tallas disponibles del mismo producto (con o sin stock).
  Map<String, List<ProductoBoutique>> _agruparPorNombre(
      List<ProductoBoutique> ps) {
    final map = <String, List<ProductoBoutique>>{};
    for (final p in ps) {
      map.putIfAbsent(p.nombre.toLowerCase().trim(), () => []).add(p);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final rol = ref.watch(usuarioActivoProvider)?.rol;
    final productosAsync = ref.watch(productosBoutiqueStreamProvider);

    return AppShell(
      selectedIndex: _sidebarIndex(rol),
      onNavigate: (_) {},
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Boutique Médica',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => context.go('/boutique/movimientos'),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Movimientos'),
                ),
                const SizedBox(width: 12),
                if (Permisos.puedeGestionarBoutique(rol))
                  ElevatedButton.icon(
                    onPressed: () => _abrirFormulario(null),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar Producto'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Buscador + filtro de talla
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _busquedaCtrl,
                    decoration: const InputDecoration(
                      hintText:
                          'Buscar por nombre, código, talla o estante...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _busqueda = v),
                  ),
                ),
                const SizedBox(width: 12),
                _buildFiltroTalla(),
              ],
            ),
            const SizedBox(height: 12),
            // Chips de categorías
            _buildChipsCategorias(),
            const SizedBox(height: 16),
            // Grid
            Expanded(
              child: productosAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e',
                    style: const TextStyle(color: AppColors.danger)),
                data: (productos) {
                  final filtrados = _filtrar(productos);
                  if (productos.isEmpty) {
                    return _vacio('No hay productos registrados');
                  }
                  if (filtrados.isEmpty) {
                    return _vacio('Sin resultados con los filtros aplicados');
                  }
                  // Todas las variantes (tallas) por nombre de producto.
                  final variantes = _agruparPorNombre(productos);
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 240,
                      mainAxisExtent: 384,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filtrados.length,
                    itemBuilder: (_, i) => _ProductoCard(
                      producto: filtrados[i],
                      tallasProducto:
                          variantes[filtrados[i].nombre.toLowerCase().trim()] ??
                              [filtrados[i]],
                      puedeEditar: Permisos.puedeGestionarBoutique(rol),
                      puedeEliminar: Permisos.puedeEliminarBoutique(rol),
                      onEditar: () => _abrirFormulario(filtrados[i]),
                      onEliminar: () => _confirmarEliminar(filtrados[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vacio(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: kSombraSuave,
        ),
        child: Center(
            child: Text(msg,
                style: const TextStyle(color: AppColors.textSecondary))),
      );

  Widget _buildChipsCategorias() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Todas'),
              selected: _categoriaSeleccionada == null,
              onSelected: (_) =>
                  setState(() => _categoriaSeleccionada = null),
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: _categoriaSeleccionada == null
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
            ),
          ),
          for (final cat in _categorias)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(cat),
                selected: _categoriaSeleccionada == cat,
                onSelected: (_) => setState(() => _categoriaSeleccionada =
                    _categoriaSeleccionada == cat ? null : cat),
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: _categoriaSeleccionada == cat
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltroTalla() {
    const tallas = ['S', 'M', 'L', 'XL', 'XXL', 'N/A'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String?>(
        value: _tallaFiltro,
        hint: const Text('Talla'),
        underline: const SizedBox.shrink(),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Todas las tallas'),
          ),
          ...tallas.map((t) => DropdownMenuItem<String?>(
                value: t,
                child: Text(t),
              )),
        ],
        onChanged: (val) => setState(() => _tallaFiltro = val),
      ),
    );
  }

  void _abrirFormulario(ProductoBoutique? producto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormularioProductoDialog(producto: producto),
    );
  }

  Future<void> _confirmarEliminar(ProductoBoutique p) async {
    final ok = await confirmarDialog(
      context,
      titulo: 'Eliminar producto',
      mensaje:
          '¿Eliminar "${p.nombre}"? Esta acción no se puede deshacer (el historial de movimientos se conserva).',
      icono: Icons.warning_amber_rounded,
      confirmLabel: 'Eliminar',
      peligroso: true,
    );
    if (ok) {
      try {
        await ref.read(boutiqueServiceProvider).eliminarProducto(p.id);
        if (mounted) {
          mostrarSnackbar(context, 'Producto eliminado',
              tipo: TipoMensaje.exito);
        }
      } catch (e) {
        if (mounted) {
          mostrarSnackbar(context, 'Error: $e', tipo: TipoMensaje.error);
        }
      }
    }
  }
}

// ── Tarjeta de producto (grid) ───────────────────────────────────────────────

class _ProductoCard extends StatelessWidget {
  final ProductoBoutique producto;
  final List<ProductoBoutique> tallasProducto;
  final bool puedeEditar;
  final bool puedeEliminar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _ProductoCard({
    required this.producto,
    required this.tallasProducto,
    required this.puedeEditar,
    required this.puedeEliminar,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final stockBajo = producto.stockBajo;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: stockBajo
                ? AppColors.warning.withValues(alpha: 0.4)
                : AppColors.border),
        boxShadow: kSombraSuave,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.4,
                child: producto.fotoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: producto.fotoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              if (puedeEditar || puedeEliminar)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Row(
                    children: [
                      if (puedeEditar)
                        _miniBtn(Icons.edit, AppColors.primary, onEditar),
                      if (puedeEliminar) ...[
                        const SizedBox(width: 4),
                        _miniBtn(Icons.delete, AppColors.danger, onEliminar),
                      ],
                    ],
                  ),
                ),
            ],
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (producto.talla != 'N/A')
                        _tag('T: ${producto.talla}'),
                      if (producto.talla != 'N/A' && producto.color != 'N/A')
                        const SizedBox(width: 4),
                      if (producto.color != 'N/A') _tag(producto.color),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        stockBajo
                            ? Icons.warning_amber
                            : Icons.inventory_2_outlined,
                        size: 14,
                        color: stockBajo
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${producto.cantidad}',
                        style: TextStyle(
                          fontSize: 12,
                          color: stockBajo
                              ? AppColors.warning
                              : AppColors.textSecondary,
                          fontWeight: stockBajo
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      Text('Estante: ${producto.estante.isEmpty ? '—' : producto.estante}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Q ${producto.precioVenta.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                  _buildTallasDisponibles(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra las tallas disponibles del mismo producto. Las que no tienen stock
  /// aparecen tachadas y en gris.
  Widget _buildTallasDisponibles() {
    // Solo tiene sentido si hay variantes con talla real.
    final variantes = tallasProducto
        .where((v) => v.talla.trim().isNotEmpty && v.talla != 'N/A')
        .toList();
    if (variantes.length < 2) return const SizedBox.shrink();

    // Ordenar y deduplicar por talla (sumando stock de la misma talla).
    final porTalla = <String, int>{};
    for (final v in variantes) {
      porTalla[v.talla] = (porTalla[v.talla] ?? 0) + v.cantidad;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: porTalla.entries.map((e) {
          final hayStock = e.value > 0;
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hayStock
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: hayStock ? AppColors.primary : Colors.grey,
              ),
            ),
            child: Text(
              e.key,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: hayStock ? AppColors.primary : Colors.grey,
                decoration:
                    hayStock ? null : TextDecoration.lineThrough,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey[100],
        child: const Center(
          child: Icon(Icons.checkroom_outlined, color: Colors.grey, size: 44),
        ),
      );

  Widget _miniBtn(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _tag(String texto) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(texto,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.w600)),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// DIALOG: Formulario agregar/editar producto
// ════════════════════════════════════════════════════════════════════════════

class _FormularioProductoDialog extends ConsumerStatefulWidget {
  final ProductoBoutique? producto;
  const _FormularioProductoDialog({this.producto});

  @override
  ConsumerState<_FormularioProductoDialog> createState() =>
      _FormularioProductoDialogState();
}

class _FormularioProductoDialogState
    extends ConsumerState<_FormularioProductoDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _codigoBarrasCtrl = TextEditingController();
  final _codigoInternoCtrl = TextEditingController();
  final _tallaCtrl = TextEditingController(text: 'N/A');
  final _colorCtrl = TextEditingController(text: 'N/A');
  final _estanteCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _cantidadAgregarCtrl = TextEditingController();
  final _cantidadMinCtrl = TextEditingController();
  final _precioCompraCtrl = TextEditingController();
  final _precioVentaCtrl = TextEditingController();

  String _categoria = 'Uniformes';
  bool _guardando = false;

  Uint8List? _fotoBytes;
  String? _fotoUrl;

  bool _esAdmin = false;
  bool _esBoutique = false;
  int _cantidadActual = 0;

  bool get _esEdicion => widget.producto != null;
  // La boutique al EDITAR solo puede agregar unidades (no reemplazar).
  bool get _modoAgregar => _esBoutique && _esEdicion;

  @override
  void initState() {
    super.initState();
    final rol = ref.read(usuarioActivoProvider)?.rol;
    _esAdmin = rol == RolUsuario.administradora;
    _esBoutique = rol == RolUsuario.boutique;
    final p = widget.producto;
    _cantidadActual = p?.cantidad ?? 0;
    if (p != null) {
      _nombreCtrl.text = p.nombre;
      _descCtrl.text = p.descripcion;
      _marcaCtrl.text = p.marca;
      _codigoBarrasCtrl.text = p.codigoBarras;
      _codigoInternoCtrl.text = p.codigoInterno;
      _tallaCtrl.text = p.talla;
      _colorCtrl.text = p.color;
      _estanteCtrl.text = p.estante;
      _cantidadCtrl.text = p.cantidad.toString();
      _cantidadMinCtrl.text = p.cantidadMinima.toString();
      _precioCompraCtrl.text = p.precioCompra.toStringAsFixed(2);
      _precioVentaCtrl.text = p.precioVenta.toStringAsFixed(2);
      _categoria = _categorias.contains(p.categoria) ? p.categoria : 'Otro';
      _fotoUrl = p.fotoUrl.isEmpty ? null : p.fotoUrl;
    } else {
      _generarCodigoInterno();
    }
  }

  Future<void> _generarCodigoInterno() async {
    final codigo =
        await ref.read(boutiqueServiceProvider).generarCodigoInterno();
    if (mounted) _codigoInternoCtrl.text = codigo;
  }

  @override
  void dispose() {
    for (final c in [
      _nombreCtrl, _descCtrl, _marcaCtrl, _codigoBarrasCtrl, _codigoInternoCtrl,
      _tallaCtrl, _colorCtrl, _estanteCtrl, _cantidadCtrl, _cantidadAgregarCtrl,
      _cantidadMinCtrl, _precioCompraCtrl, _precioVentaCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
          source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (mounted) setState(() => _fotoBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        mostrarSnackbar(context, 'Error al acceder: $e',
            tipo: TipoMensaje.error);
      }
    }
  }

  Future<String?> _subirFoto(String id) async {
    if (_fotoBytes == null) return _fotoUrl;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('fotos_boutique')
          .child('$id.jpg');
      final task = await ref.putData(
          _fotoBytes!, SettableMetadata(contentType: 'image/jpeg'));
      return await task.ref.getDownloadURL();
    } catch (e) {
      debugPrint('⚠️ Error subiendo foto boutique: $e');
      return _fotoUrl;
    }
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
                  _esEdicion ? 'Editar Producto' : 'Nuevo Producto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
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
                      _buildSeccionFoto(),
                      const SizedBox(height: 16),
                      _seccion('Identificación'),
                      _row2(
                        _campo('Nombre *', _nombreCtrl, validator: _requerido),
                        _campo('Marca', _marcaCtrl),
                      ),
                      _campo('Descripción', _descCtrl, maxLines: 2),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _codigoBarrasCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Código de barras',
                          helperText: 'Escanee o escriba manualmente',
                          suffixIcon: Icon(Icons.barcode_reader),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _row2(
                        _dropdown('Categoría', _categoria, _categorias,
                            (v) => setState(() => _categoria = v!)),
                        _campo('Código interno', _codigoInternoCtrl,
                            enabled: false),
                      ),
                      const SizedBox(height: 8),
                      _seccion('Variantes'),
                      _row2(
                        _campo('Talla', _tallaCtrl, hint: 'S, M, L, 37, N/A'),
                        _campo('Color', _colorCtrl, hint: 'Azul, Blanco...'),
                      ),
                      const SizedBox(height: 8),
                      _seccion('Ubicación'),
                      _campo('Estante *', _estanteCtrl,
                          hint: 'B-1', validator: _requerido),
                      const SizedBox(height: 16),
                      _seccion('Inventario'),
                      _buildCampoCantidad(),
                      const SizedBox(height: 12),
                      _campo('Cantidad mínima', _cantidadMinCtrl,
                          keyboard: TextInputType.number,
                          formatters: [FilteringTextInputFormatter.digitsOnly]),
                      const SizedBox(height: 16),
                      _seccion('Precios'),
                      _row2(
                        _campo('Precio de compra (Q)', _precioCompraCtrl,
                            keyboard: const TextInputType.numberWithOptions(
                                decimal: true),
                            formatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'))
                            ]),
                        _campo('Precio de venta (Q) *', _precioVentaCtrl,
                            validator: _requerido,
                            keyboard: const TextInputType.numberWithOptions(
                                decimal: true),
                            formatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'))
                            ]),
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
                  onPressed:
                      _guardando ? null : () => Navigator.of(context).pop(),
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
                              strokeWidth: 2, color: Colors.white))
                      : Text(_esEdicion ? 'Guardar cambios' : 'Agregar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionFoto() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _seleccionarFoto(ImageSource.camera),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: _fotoBytes != null
                  ? Image.memory(_fotoBytes!, fit: BoxFit.cover)
                  : (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: _fotoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.checkroom_outlined,
                              size: 44,
                              color: Colors.grey))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.checkroom_outlined,
                                size: 40, color: Colors.grey),
                            SizedBox(height: 6),
                            Text('Foto del producto',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _seleccionarFoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Cámara'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _seleccionarFoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Galería'),
              ),
              if (_fotoBytes != null ||
                  (_fotoUrl != null && _fotoUrl!.isNotEmpty)) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _fotoBytes = null;
                    _fotoUrl = null;
                  }),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Quitar'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

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
              Text('Stock actual: $_cantidadActual',
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
            helperText: 'Se sumará al stock actual',
            prefixIcon: Icon(Icons.add_circle, color: AppColors.success),
            isDense: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (agregar > 0) ...[
          const SizedBox(height: 8),
          Text('Nuevo stock: $_cantidadActual + $agregar = $nuevoTotal',
              style: const TextStyle(
                  color: AppColors.success, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }

  Widget _seccion(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
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

  Widget _campo(String label, TextEditingController ctrl,
      {String? hint,
      bool enabled = true,
      int maxLines = 1,
      TextInputType? keyboard,
      List<TextInputFormatter>? formatters,
      String? Function(String?)? validator}) {
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
            labelText: label, hintText: hint, isDense: true),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: onChanged,
    );
  }

  String? _requerido(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      final usuario = ref.read(usuarioActivoProvider);
      final service = ref.read(boutiqueServiceProvider);

      final int cantidadFinal;
      if (_modoAgregar) {
        final agregar = int.tryParse(_cantidadAgregarCtrl.text.trim()) ?? 0;
        cantidadFinal = _cantidadActual + agregar;
      } else {
        cantidadFinal = int.tryParse(_cantidadCtrl.text.trim()) ?? 0;
      }

      if (_modoAgregar && cantidadFinal < _cantidadActual) {
        setState(() => _guardando = false);
        mostrarSnackbar(context,
            'No tienes permiso para reducir el stock. Solo puedes agregar unidades.',
            tipo: TipoMensaje.error);
        return;
      }

      // Resolver foto (en edición conocemos el id).
      String fotoUrl = _fotoUrl ?? '';
      if (_esEdicion) {
        fotoUrl = await _subirFoto(widget.producto!.id) ?? '';
      }

      final producto = ProductoBoutique(
        id: widget.producto?.id ?? '',
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descCtrl.text.trim(),
        marca: _marcaCtrl.text.trim(),
        codigoBarras: _codigoBarrasCtrl.text.trim(),
        codigoInterno: _codigoInternoCtrl.text.trim(),
        categoria: _categoria,
        fotoUrl: fotoUrl,
        talla: _tallaCtrl.text.trim().isEmpty ? 'N/A' : _tallaCtrl.text.trim(),
        color: _colorCtrl.text.trim().isEmpty ? 'N/A' : _colorCtrl.text.trim(),
        estante: _estanteCtrl.text.trim(),
        cantidad: cantidadFinal,
        cantidadMinima: int.tryParse(_cantidadMinCtrl.text.trim()) ?? 0,
        unidad: 'unidades',
        precioCompra: double.tryParse(_precioCompraCtrl.text.trim()) ?? 0,
        precioVenta: double.tryParse(_precioVentaCtrl.text.trim()) ?? 0,
      );

      if (_esEdicion) {
        await service.actualizarProducto(producto.id, producto,
            uid: usuario?.id ?? '');
        if (cantidadFinal != _cantidadActual) {
          final aumento = cantidadFinal > _cantidadActual;
          await service.registrarMovimiento(
            tipo: aumento ? 'entrada' : 'ajuste',
            productoId: producto.id,
            nombreProducto: producto.nombre,
            cantidadAnterior: _cantidadActual,
            cantidadNueva: cantidadFinal,
            motivo: aumento ? 'Ingreso de stock' : 'Ajuste de inventario',
            uid: usuario?.id ?? '',
            nombreResponsable: usuario?.nombre ?? '',
          );
        }
      } else {
        final nuevoId = await service.crearProducto(producto,
            uid: usuario?.id ?? '', nombreCreador: usuario?.nombre ?? '');
        if (_fotoBytes != null) {
          final url = await _subirFoto(nuevoId) ?? '';
          if (url.isNotEmpty) await service.actualizarFoto(nuevoId, url);
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        mostrarSnackbar(
            context, _esEdicion ? 'Producto actualizado' : 'Producto agregado',
            tipo: TipoMensaje.exito);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        mostrarSnackbar(context, 'Error: $e', tipo: TipoMensaje.error);
      }
    }
  }
}
