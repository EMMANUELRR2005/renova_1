import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/permisos.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/widgets_comunes.dart';
import '../../data/mock/providers.dart';
import '../../data/services/expediente_service.dart';
import '../../features/auth/providers/auth_provider.dart';

class ExpedienteScreen extends ConsumerWidget {
  const ExpedienteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expedientesAsync = ref.watch(expedientesStreamProvider);
    final filtro = ref.watch(filtroExpedientesProvider);
    final usuario = ref.watch(usuarioActivoProvider);

    return AppShell(
      selectedIndex: 3,
      onNavigate: (index) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Expedientes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                const Spacer(),
                _buildFiltros(ref, filtro),
              ],
            ),
            const SizedBox(height: 20),
            _buildListaExpedientes(context, ref, expedientesAsync, usuario),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros(WidgetRef ref, String filtroActual) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFiltroChip(ref, 'Todos', 'todos', filtroActual),
          _buildFiltroChip(ref, 'Abiertos', 'abierto', filtroActual),
          _buildFiltroChip(ref, 'Cerrados', 'cerrado', filtroActual),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(WidgetRef ref, String label, String value, String actual) {
    final selected = value == actual;
    return InkWell(
      onTap: () => ref.read(filtroExpedientesProvider.notifier).state = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildListaExpedientes(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Expediente>> expedientesAsync,
    dynamic usuario,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: kSombraSuave,
      ),
      clipBehavior: Clip.antiAlias,
      child: expedientesAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e'),
        ),
        data: (expedientes) {
          if (expedientes.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No hay expedientes',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('N° Expediente')),
                DataColumn(label: Text('Paciente')),
                DataColumn(label: Text('Servicio')),
                DataColumn(label: Text('Doctora')),
                DataColumn(label: Text('Fecha Apertura')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: expedientes
                  .map((e) => _buildExpedienteRow(context, ref, e, usuario))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  DataRow _buildExpedienteRow(
    BuildContext context,
    WidgetRef ref,
    Expediente expediente,
    dynamic usuario,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(
          expediente.numeroExpediente,
          style: const TextStyle(fontWeight: FontWeight.w600),
        )),
        DataCell(Text(expediente.nombrePaciente)),
        DataCell(Text(expediente.servicio)),
        DataCell(Text(expediente.doctora)),
        DataCell(Text(
          '${expediente.fechaApertura.day.toString().padLeft(2, '0')}/${expediente.fechaApertura.month.toString().padLeft(2, '0')}/${expediente.fechaApertura.year}',
        )),
        DataCell(buildBadgeEstado(
          expediente.estado == 'abierto' ? 'activo' : 'inactivo',
          label: expediente.estado == 'abierto' ? 'Abierto' : 'Cerrado',
        )),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, size: 18),
              tooltip: 'Ver detalle',
              onPressed: () => _mostrarDetalleExpediente(
                context,
                ref,
                expediente,
                usuario,
              ),
            ),
          ],
        )),
      ],
    );
  }

  void _mostrarDetalleExpediente(
    BuildContext context,
    WidgetRef ref,
    Expediente expediente,
    dynamic usuario,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _DetalleExpedienteDialog(
        expediente: expediente,
        usuario: usuario,
      ),
    );
  }
}

class _DetalleExpedienteDialog extends ConsumerWidget {
  final Expediente expediente;
  final dynamic usuario;

  const _DetalleExpedienteDialog({
    required this.expediente,
    required this.usuario,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entradasAsync = ref.watch(entradasExpedienteProvider(expediente.id));
    final rol = usuario?.rol;

    return Dialog(
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Expediente ${expediente.numeroExpediente}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                const SizedBox(width: 12),
                buildBadgeEstado(
                  expediente.estado == 'abierto' ? 'activo' : 'inactivo',
                  label: expediente.estado == 'abierto' ? 'Abierto' : 'Cerrado',
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildInfoExpediente(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: _buildEntradas(context, ref, entradasAsync),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAcciones(context, ref, rol),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoExpediente() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información del Expediente',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow('Paciente', expediente.nombrePaciente),
          _InfoRow('Servicio', expediente.servicio),
          _InfoRow('Clínica', expediente.clinica),
          _InfoRow('Doctora', expediente.doctora),
          _InfoRow(
            'Apertura',
            '${expediente.fechaApertura.day.toString().padLeft(2, '0')}/${expediente.fechaApertura.month.toString().padLeft(2, '0')}/${expediente.fechaApertura.year}',
          ),
        ],
      ),
    );
  }

  Widget _buildEntradas(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<EntradaExpediente>> entradasAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Historial de Entradas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              if (Permisos.puedeCrearConsultas(usuario?.rol) &&
                  expediente.estado == 'abierto')
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Nueva Entrada'),
                  onPressed: () => _mostrarFormularioEntrada(context, ref),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: entradasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (entradas) {
                if (entradas.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay entradas registradas',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: entradas.length,
                  itemBuilder: (ctx, i) => _buildEntradaCard(entradas[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntradaCard(EntradaExpediente entrada) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTipoBadge(entrada.tipo),
              const SizedBox(width: 8),
              Text(
                '${entrada.fecha.day.toString().padLeft(2, '0')}/${entrada.fecha.month.toString().padLeft(2, '0')}/${entrada.fecha.year}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                entrada.nombreCreador,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entrada.titulo,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (entrada.descripcion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entrada.descripcion,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipoBadge(String tipo) {
    Color color;
    switch (tipo) {
      case 'consulta':
        color = AppColors.primary;
        break;
      case 'procedimiento':
        color = AppColors.warning;
        break;
      case 'medicamento':
        color = AppColors.clinicalGreen;
        break;
      case 'resultado':
        color = AppColors.success;
        break;
      default:
        color = AppColors.neutral;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tipo.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAcciones(BuildContext context, WidgetRef ref, dynamic rol) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (Permisos.puedeCrearConsultas(rol) && expediente.estado == 'abierto')
          OutlinedButton(
            onPressed: () => _cerrarExpediente(context, ref),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Cerrar Expediente'),
          ),
        if (expediente.estado == 'cerrado' && Permisos.puedeCrearConsultas(rol))
          OutlinedButton(
            onPressed: () => _reabrirExpediente(context, ref),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.success),
            child: const Text('Reabrir Expediente'),
          ),
      ],
    );
  }

  void _mostrarFormularioEntrada(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _NuevaEntradaDialog(
        expedienteId: expediente.id,
        usuario: usuario,
      ),
    );
  }

  Future<void> _cerrarExpediente(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Expediente'),
        content: const Text('¿Está seguro de cerrar este expediente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ExpedienteService().cerrarExpediente(expediente.id);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expediente cerrado'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
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

  Future<void> _reabrirExpediente(BuildContext context, WidgetRef ref) async {
    try {
      await ExpedienteService().reabrirExpediente(expediente.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expediente reabierto'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _NuevaEntradaDialog extends StatefulWidget {
  final String expedienteId;
  final dynamic usuario;

  const _NuevaEntradaDialog({
    required this.expedienteId,
    required this.usuario,
  });

  @override
  State<_NuevaEntradaDialog> createState() => _NuevaEntradaDialogState();
}

class _NuevaEntradaDialogState extends State<_NuevaEntradaDialog> {
  String _tipo = 'nota';
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  bool _guardando = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Entrada'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'consulta', child: Text('Consulta')),
                DropdownMenuItem(value: 'nota', child: Text('Nota')),
                DropdownMenuItem(value: 'procedimiento', child: Text('Procedimiento')),
                DropdownMenuItem(value: 'medicamento', child: Text('Medicamento')),
                DropdownMenuItem(value: 'resultado', child: Text('Resultado')),
              ],
              onChanged: (v) => setState(() => _tipo = v ?? 'nota'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    if (_tituloController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un título'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final entrada = EntradaExpediente(
        id: '',
        tipo: _tipo,
        fecha: DateTime.now(),
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        archivos: [],
        creadoPor: widget.usuario?.id ?? '',
        nombreCreador: widget.usuario?.nombre ?? '',
        rolCreador: widget.usuario?.rol.toString().split('.').last ?? '',
      );

      await ExpedienteService().agregarEntrada(widget.expedienteId, entrada);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrada agregada'),
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
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
