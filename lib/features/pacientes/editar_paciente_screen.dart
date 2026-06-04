import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/widgets_comunes.dart';
import '../../data/mock/mock_data.dart';
import '../../data/mock/providers.dart';
import '../../features/auth/providers/auth_provider.dart';

class EditarPacienteScreen extends ConsumerStatefulWidget {
  const EditarPacienteScreen({super.key});

  @override
  ConsumerState<EditarPacienteScreen> createState() =>
      _EditarPacienteScreenState();
}

class _EditarPacienteScreenState extends ConsumerState<EditarPacienteScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _cargado = false;
  bool _guardando = false;
  bool _subiendoFoto = false;

  // Foto del paciente (cross-platform)
  Uint8List? _fotoBytes;
  String? _fotoUrlExistente;

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  String _genero = 'Femenino';
  String _tipoId = 'DPI';
  String _estado = 'activo';
  DateTime? _fechaNac;
  int _edad = 0;

  final _alergiasCtrl = TextEditingController();
  final _condicionesCtrl = TextEditingController();

  final _contactoNombreCtrl = TextEditingController();
  final _contactoTelCtrl = TextEditingController();
  String _contactoRelacion = 'familiar';

  late Paciente _pacienteOriginal;

  /// Normaliza el tipo guardado a un valor presente en el dropdown
  /// (['DPI','pasaporte','otro']) para evitar el assertion de DropdownButton.
  String _normalizarTipoId(String? t) {
    if (t == null || t.trim().isEmpty) return 'DPI';
    final low = t.toLowerCase();
    if (low == 'cedula' || low == 'cédula' || low == 'dpi') return 'DPI';
    if (low == 'pasaporte') return 'pasaporte';
    if (low == 'otro') return 'otro';
    return 'DPI';
  }

  void _cargarDatos(Paciente p) {
    if (_cargado) return;
    _pacienteOriginal = p;
    _nombreCtrl.text = p.nombre;
    _apellidoCtrl.text = p.apellido;
    _emailCtrl.text = p.email;
    _telefonoCtrl.text = p.telefono;
    _direccionCtrl.text = p.direccion;
    _ciudadCtrl.text = p.ciudad;
    _genero = p.genero.isEmpty ? 'Femenino' : p.genero;
    _tipoId = _normalizarTipoId(p.tipoIdentificacion);
    _estado = p.estado;
    _alergiasCtrl.text = p.alergias;
    _condicionesCtrl.text = p.condicionesPreexistentes;
    _contactoNombreCtrl.text = p.contactoEmergencia.nombre;
    _contactoTelCtrl.text = p.contactoEmergencia.telefono;
    _contactoRelacion = p.contactoEmergencia.relacion.isEmpty
        ? 'familiar'
        : p.contactoEmergencia.relacion;
    _fotoUrlExistente = p.fotoUrl;
    if (p.fechaNacimiento.isNotEmpty) {
      final parts = p.fechaNacimiento.split('-');
      if (parts.length == 3) {
        _fechaNac = DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        _edad = p.edad;
      }
    }
    _cargado = true;
  }

  Future<void> _tomarFoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _fotoBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al acceder: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _quitarFoto() {
    setState(() {
      _fotoBytes = null;
      _fotoUrlExistente = null;
    });
  }

  Future<String?> _subirFoto(String pacienteId) async {
    if (_fotoBytes == null || _fotoBytes!.isEmpty) {
      debugPrint('⚠️ No hay bytes de foto para subir');
      return null;
    }

    try {
      setState(() => _subiendoFoto = true);
      debugPrint('🔵 Iniciando subida a Storage...');
      debugPrint('🔵 Tamaño: ${_fotoBytes!.length} bytes');

      final storage = FirebaseStorage.instance;
      debugPrint('🔵 Storage bucket: ${storage.bucket}');

      final ref = storage.ref().child('fotos_pacientes').child('$pacienteId.jpg');
      debugPrint('🔵 Path completo: ${ref.fullPath}');

      debugPrint('🔵 Ejecutando putData...');
      final UploadTask uploadTask = ref.putData(
        _fotoBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      debugPrint('🔵 Esperando que termine la subida...');
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() {
        debugPrint('🔵 whenComplete ejecutado');
      });

      debugPrint('🔵 Estado: ${snapshot.state}');
      debugPrint('🔵 Bytes transferidos: ${snapshot.bytesTransferred}');
      debugPrint('🔵 Total bytes: ${snapshot.totalBytes}');

      if (snapshot.state == TaskState.success) {
        debugPrint('✅ Subida exitosa, obteniendo URL...');
        final url = await snapshot.ref.getDownloadURL();
        debugPrint('✅ URL obtenida: $url');
        return url;
      } else {
        debugPrint('❌ Estado final: ${snapshot.state}');
        return null;
      }
    } on FirebaseException catch (e) {
      debugPrint('❌ FirebaseException: ${e.code} - ${e.message}');
      debugPrint('❌ Stack: ${e.stackTrace}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error Storage: ${e.code}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return null;
    } catch (e, stack) {
      debugPrint('❌ Error desconocido: $e');
      debugPrint('❌ Stack: $stack');
      return null;
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Widget _buildSeccionFoto() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _tomarFoto(ImageSource.gallery),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _fotoBytes != null
                  ? Image.memory(
                      _fotoBytes!,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    )
                  : (_fotoUrlExistente != null && _fotoUrlExistente!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: _fotoUrlExistente!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person, size: 60, color: Colors.grey),
                        )
                      : const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey,
                        ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Foto del Paciente (Opcional)',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontFamily: GoogleFonts.dmSans().fontFamily,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!kIsWeb) ...[
              OutlinedButton.icon(
                onPressed: () => _tomarFoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Cámara'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
            ],
            OutlinedButton.icon(
              onPressed: () => _tomarFoto(ImageSource.gallery),
              icon: Icon(
                kIsWeb ? Icons.upload_file_outlined : Icons.photo_library_outlined,
                size: 18,
              ),
              label: Text(kIsWeb ? 'Subir Foto' : 'Galería'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
            if (_fotoBytes != null || (_fotoUrlExistente != null && _fotoUrlExistente!.isNotEmpty)) ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _quitarFoto,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Quitar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final c in [
      _nombreCtrl, _apellidoCtrl, _emailCtrl, _telefonoCtrl,
      _direccionCtrl, _ciudadCtrl, _alergiasCtrl, _condicionesCtrl,
      _contactoNombreCtrl, _contactoTelCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNac ?? DateTime(hoy.year - 30),
      firstDate: DateTime(1900),
      lastDate: hoy,
    );
    if (picked != null) {
      setState(() {
        _fechaNac = picked;
        _edad = _calcularEdad(picked);
      });
    }
  }

  int _calcularEdad(DateTime nac) {
    final hoy = DateTime.now();
    int edad = hoy.year - nac.year;
    if (hoy.month < nac.month ||
        (hoy.month == nac.month && hoy.day < nac.day)) edad--;
    return edad;
  }

  String _formatFecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaNac == null) {
      _showMsg('Selecciona la fecha de nacimiento', error: true);
      return;
    }
    setState(() => _guardando = true);

    try {
      final usuario = ref.read(usuarioActivoProvider);
      final service = ref.read(pacienteServiceProvider);
      final id = ref.read(selectedPacienteIdProvider)!;

      final actualizado = Paciente(
        id: id,
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        fechaNacimiento: _formatFecha(_fechaNac!),
        edad: _edad,
        genero: _genero,
        direccion: _direccionCtrl.text.trim(),
        ciudad: _ciudadCtrl.text.trim(),
        numeroIdentificacion: _pacienteOriginal.numeroIdentificacion,
        tipoIdentificacion: _tipoId,
        alergias: _alergiasCtrl.text.trim(),
        condicionesPreexistentes: _condicionesCtrl.text.trim(),
        contactoEmergencia: ContactoEmergencia(
          nombre: _contactoNombreCtrl.text.trim(),
          telefono: _contactoTelCtrl.text.trim(),
          relacion: _contactoRelacion,
        ),
        estado: _estado,
        registradoPor: _pacienteOriginal.registradoPor,
      );

      await service.actualizarPaciente(id, actualizado, usuario?.id ?? '');

      // Subir nueva foto si se seleccionó una
      if (_fotoBytes != null) {
        final fotoUrl = await _subirFoto(id);
        if (fotoUrl != null) {
          await service.actualizarFotoPaciente(id, fotoUrl);
        }
      } else if (_fotoUrlExistente == null && _pacienteOriginal.fotoUrl != null) {
        // Se quitó la foto
        await service.actualizarFotoPaciente(id, '');
      }

      if (mounted) {
        _showMsg('Datos actualizados correctamente');
        context.go('/pacientes/detalle');
      }
    } catch (e) {
      _showMsg('Error al guardar. Intente de nuevo.', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _showMsg(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pacienteId = ref.watch(selectedPacienteIdProvider);

    if (pacienteId == null) {
      return AppShell(
        selectedIndex: 0,
        onNavigate: (_) {},
        child: const Center(child: Text('No se seleccionó ningún paciente')),
      );
    }

    final pacienteAsync = ref.watch(pacienteByIdProvider(pacienteId));

    return AppShell(
      selectedIndex: 0,
      onNavigate: (_) {},
      child: pacienteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (paciente) {
          if (paciente == null) {
            return const Center(child: Text('Paciente no encontrado'));
          }
          _cargarDatos(paciente);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
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
                        'Editar Paciente',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontFamily: GoogleFonts.dmSans().fontFamily,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: Text(
                      'El número de identificación no se puede modificar',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: GoogleFonts.dmSans().fontFamily,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Foto del Paciente ───────────────────────────────────────
                  _SectionCard(
                    title: 'Foto del Paciente',
                    children: [
                      _buildSeccionFoto(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Datos Personales',
                    children: [
                      _Row2(
                        left: _Field(label: 'Nombre *', controller: _nombreCtrl, validator: _req),
                        right: _Field(label: 'Apellido *', controller: _apellidoCtrl, validator: _req),
                      ),
                      _Row2(
                        left: _Field(
                          label: 'Teléfono *',
                          controller: _telefonoCtrl,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            if (!RegExp(r'^[\d\s\+\-\(\)]+$').hasMatch(v)) return 'Inválido';
                            return null;
                          },
                        ),
                        right: _Field(
                          label: 'Email',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$').hasMatch(v)) return 'Email inválido';
                            return null;
                          },
                        ),
                      ),
                      _Row2(
                        left: _DateField(
                          fecha: _fechaNac,
                          edad: _edad,
                          onTap: _seleccionarFecha,
                          formatFecha: _formatFecha,
                        ),
                        right: _DropdownField(
                          label: 'Género',
                          value: _genero,
                          items: const ['Femenino', 'Masculino', 'Otro'],
                          onChanged: (v) => setState(() => _genero = v!),
                        ),
                      ),
                      _Row2(
                        left: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.bgGeneral,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('N° Identificación (inmutable)',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: GoogleFonts.dmSans().fontFamily)),
                              const SizedBox(height: 4),
                              Text(paciente.numeroIdentificacion,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        right: _DropdownField(
                          label: 'Tipo Identificación',
                          value: _tipoId,
                          items: const ['DPI', 'pasaporte', 'otro'],
                          onChanged: (v) => setState(() => _tipoId = v!),
                        ),
                      ),
                      _Row2(
                        left: _Field(label: 'Dirección *', controller: _direccionCtrl, validator: _req),
                        right: _Field(label: 'Ciudad *', controller: _ciudadCtrl, validator: _req),
                      ),
                      _DropdownField(
                        label: 'Estado',
                        value: _estado,
                        items: const ['activo', 'inactivo'],
                        onChanged: (v) => setState(() => _estado = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Datos Médicos',
                    children: [
                      _Field(
                        label: 'Alergias (separadas por comas)',
                        controller: _alergiasCtrl,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        label: 'Condiciones Preexistentes',
                        controller: _condicionesCtrl,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Contacto de Emergencia',
                    children: [
                      _Row2(
                        left: _Field(label: 'Nombre', controller: _contactoNombreCtrl),
                        right: _Field(
                          label: 'Teléfono',
                          controller: _contactoTelCtrl,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      _DropdownField(
                        label: 'Relación',
                        value: _contactoRelacion,
                        items: const ['familiar', 'padre', 'madre', 'esposo/a', 'hermano/a', 'amigo/a', 'otro'],
                        onChanged: (v) => setState(() => _contactoRelacion = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_guardando || _subiendoFoto) ? null : _guardar,
                      child: _subiendoFoto
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                SizedBox(width: 8),
                                Text('Subiendo foto...'),
                              ],
                            )
                          : _guardando
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Guardando...'),
                                  ],
                                )
                              : const Text('Guardar Cambios'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null;
}

// ── Widgets reutilizables ──────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: kSombraSuave,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: GoogleFonts.dmSans().fontFamily)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _Row2 extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _Row2({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime? fecha;
  final int edad;
  final VoidCallback onTap;
  final String Function(DateTime) formatFecha;

  const _DateField({
    required this.fecha,
    required this.edad,
    required this.onTap,
    required this.formatFecha,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fecha de Nacimiento',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                fontFamily: GoogleFonts.dmSans().fontFamily)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  fecha == null
                      ? 'Seleccionar fecha'
                      : '${formatFecha(fecha!)}  ($edad años)',
                  style: TextStyle(
                      fontSize: 14,
                      color: fecha == null
                          ? AppColors.textDisabled
                          : AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
