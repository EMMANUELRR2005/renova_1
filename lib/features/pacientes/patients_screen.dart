import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/auth/permisos.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/widgets_comunes.dart';
import '../../data/mock/mock_data.dart';
import '../../data/mock/providers.dart';
import '../../features/auth/providers/auth_provider.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(usuarioActivoProvider);
    final rol = usuario?.rol;
    final filtroEstado = ref.watch(filtroPacientesEstadoProvider);

    // Doctora: solo ve sus pacientes con cita asignada.
    // Los demás roles: ven todos (con filtro de estado del provider).
    final AsyncValue<List<Paciente>> pacientesAsync = (rol == RolUsuario.doctora)
        ? ref.watch(pacientesDoctoraProvider)
        : ref.watch(pacientesV2StreamProvider);

    return AppShell(
      selectedIndex: _getSidebarIndex(rol),
      onNavigate: (_) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pacientes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                if (Permisos.puedeCrearPacientes(rol))
                  ElevatedButton.icon(
                    onPressed: () => context.go('/pacientes/nuevo'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo Paciente'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Buscador + Filtros ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre o teléfono...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _FiltroChip(
                  label: 'Todos',
                  activo: filtroEstado == 'todos',
                  onTap: () => ref
                      .read(filtroPacientesEstadoProvider.notifier)
                      .state = 'todos',
                ),
                const SizedBox(width: 6),
                _FiltroChip(
                  label: 'Activos',
                  activo: filtroEstado == 'activo',
                  color: AppColors.success,
                  onTap: () => ref
                      .read(filtroPacientesEstadoProvider.notifier)
                      .state = 'activo',
                ),
                const SizedBox(width: 6),
                _FiltroChip(
                  label: 'Inactivos',
                  activo: filtroEstado == 'inactivo',
                  color: AppColors.danger,
                  onTap: () => ref
                      .read(filtroPacientesEstadoProvider.notifier)
                      .state = 'inactivo',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Tabla ─────────────────────────────────────────────────────
            pacientesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: AppColors.danger)),
              data: (pacientes) {
                // Para doctora el proveedor no filtra por estado; aplicar aquí.
                final base = (rol == RolUsuario.doctora && filtroEstado != 'todos')
                    ? pacientes.where((p) => p.estado == filtroEstado).toList()
                    : pacientes;
                final filtrados = base.where((p) {
                  if (_searchQuery.isEmpty) return true;
                  return p.nombreCompleto.toLowerCase().contains(_searchQuery) ||
                      p.telefono.contains(_searchQuery);
                }).toList();

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: kSombraSuave,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Encabezado tabla
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: AppColors.bgGeneral,
                        ),
                        child: Row(
                          children: [
                            _HeaderCell('Nombre', flex: 3),
                            _HeaderCell('Edad', flex: 1),
                            _HeaderCell('Teléfono', flex: 2),
                            _HeaderCell('Estado', flex: 1),
                            _HeaderCell('Acciones', flex: 2),
                          ],
                        ),
                      ),
                      if (filtrados.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No hay pacientes registrados',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontFamily: GoogleFonts.dmSans().fontFamily,
                            ),
                          ),
                        )
                      else
                        ...filtrados.asMap().entries.map((entry) {
                          final i = entry.key;
                          final p = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: i.isEven ? Colors.white : AppColors.bgGeneral.withValues(alpha: 0.4),
                              border: const Border(
                                bottom: BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Foto del paciente
                                Container(
                                  width: 40,
                                  height: 40,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[200],
                                    border: Border.all(
                                      color: AppColors.accent.withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: (p.fotoUrl != null && p.fotoUrl!.isNotEmpty)
                                        ? CachedNetworkImage(
                                            imageUrl: p.fotoUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const Icon(Icons.person, size: 20, color: Colors.grey),
                                            errorWidget: (context, url, error) =>
                                                const Icon(Icons.person, size: 20, color: Colors.grey),
                                          )
                                        : const Icon(Icons.person, size: 20, color: Colors.grey),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.nombreCompleto,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        p.numeroIdentificacion,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '${p.edad} años',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    p.telefono,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: buildBadgeEstado(p.estado),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          ref
                                              .read(selectedPacienteIdProvider
                                                  .notifier)
                                              .state = p.id;
                                          context.go('/pacientes/detalle');
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                        ),
                                        child: const Text('Ver',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                      if (Permisos.puedeEditarPacientes(rol))
                                        TextButton(
                                          onPressed: () {
                                            ref
                                                .read(selectedPacienteIdProvider
                                                    .notifier)
                                                .state = p.id;
                                            context.go('/pacientes/editar');
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.warning,
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8),
                                          ),
                                          child: const Text('Editar',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  int _getSidebarIndex(RolUsuario? rol) {
    switch (rol) {
      case RolUsuario.administradora:
        return 1;
      case RolUsuario.enfermera:
      case RolUsuario.secretaria_recepcion:
      case RolUsuario.doctora:
        return 0;
      default:
        return 0;
    }
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  const _HeaderCell(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: GoogleFonts.dmSans().fontFamily,
        ),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool activo;
  final Color color;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.activo,
    required this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? color.withValues(alpha: 0.12) : AppColors.bgGeneral,
          border: Border.all(
              color: activo ? color : AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: activo ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
