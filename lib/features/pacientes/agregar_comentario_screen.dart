import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../data/mock/mock_data.dart';
import '../../data/mock/providers.dart';
import '../../features/auth/providers/auth_provider.dart';

class AgregarComentarioScreen extends ConsumerStatefulWidget {
  const AgregarComentarioScreen({super.key});

  @override
  ConsumerState<AgregarComentarioScreen> createState() =>
      _AgregarComentarioScreenState();
}

class _AgregarComentarioScreenState
    extends ConsumerState<AgregarComentarioScreen> {
  final _comentarioCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final texto = _comentarioCtrl.text.trim();
    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un comentario antes de guardar'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final usuario = ref.read(usuarioActivoProvider);
      final service = ref.read(pacienteServiceProvider);
      final pacienteId = ref.read(selectedPacienteIdProvider)!;

      final entrada = HistorialConsulta(
        id: '',
        tipo: 'comentario',
        comentarios: texto,
        creadoPor: usuario?.id ?? '',
        rolCreador: 'secretaria_recepcion',
      );

      await service.agregarEntradaHistorial(pacienteId, entrada);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comentario agregado'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/pacientes/detalle');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedIndex: 0,
      onNavigate: (_) {},
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/pacientes/detalle'),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Agregar Nota / Comentario',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: GoogleFonts.dmSans().fontFamily,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comentario u Observación',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: GoogleFonts.dmSans().fontFamily,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _comentarioCtrl,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          hintText:
                              'Escribe aquí la nota u observación del paciente...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _guardando ? null : _guardar,
                          child: _guardando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Guardar Comentario'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
