import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/widgets_comunes.dart';
import '../../data/mock/mock_data.dart';
import '../../data/mock/providers.dart';
import '../../features/auth/providers/auth_provider.dart';

class NuevoPacienteScreen extends ConsumerStatefulWidget {
  const NuevoPacienteScreen({super.key});

  @override
  ConsumerState<NuevoPacienteScreen> createState() =>
      _NuevoPacienteScreenState();
}

class _NuevoPacienteScreenState extends ConsumerState<NuevoPacienteScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _guardando = false;
  bool _subiendoFoto = false;

  // Foto del paciente (cross-platform)
  Uint8List? _fotoBytes;

  // Datos personales
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _numIdCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  String _genero = 'Femenino';
  String _tipoId = 'DPI';
  DateTime? _fechaNac;
  int _edad = 0;

  // Datos médicos
  final _alergiasCtrl = TextEditingController();
  final _condicionesCtrl = TextEditingController();

  // Contacto emergencia
  final _contactoNombreCtrl = TextEditingController();
  final _contactoTelCtrl = TextEditingController();
  String _contactoRelacion = 'familiar';

  // Servicio y Clínica (nuevos campos obligatorios)
  String? _servicioId;
  String? _servicioNombre;
  String? _clinicaId;
  String? _clinicaNombre;

  @override
  void dispose() {
    for (final c in [
      _nombreCtrl, _apellidoCtrl, _emailCtrl, _telefonoCtrl, _numIdCtrl,
      _direccionCtrl, _ciudadCtrl, _alergiasCtrl, _condicionesCtrl,
      _contactoNombreCtrl, _contactoTelCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(hoy.year - 30),
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
        (hoy.month == nac.month && hoy.day < nac.day)) {
      edad--;
    }
    return edad;
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
          onTap: () => _tomarFoto(ImageSource.camera),
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
            child: _fotoBytes != null
                ? ClipOval(
                    child: Image.memory(
                      _fotoBytes!,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey,
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
            // Solo cámara: la foto del paciente se toma en el momento.
            OutlinedButton.icon(
              onPressed: () => _tomarFoto(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined, size: 20),
              label: const Text('Tomar Foto'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
            if (_fotoBytes != null) ...[
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

  String _formatFecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _guardar() async {
    debugPrint('🔵 Iniciando guardar paciente...');
    debugPrint('🔵 ¿Tiene foto? ${_fotoBytes != null}');
    debugPrint('🔵 Tamaño bytes: ${_fotoBytes?.length}');

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Formulario inválido');
      return;
    }
    if (_fechaNac == null) {
      _showError('Selecciona la fecha de nacimiento');
      return;
    }
    if (_servicioId == null || _servicioNombre == null) {
      _showError('Selecciona un servicio');
      return;
    }
    if (_clinicaId == null || _clinicaNombre == null) {
      _showError('Selecciona una clínica');
      return;
    }

    setState(() => _guardando = true);

    try {
      final usuario = ref.read(usuarioActivoProvider);
      final service = ref.read(pacienteServiceProvider);

      final yaExiste = await service.existeNumeroIdentificacion(_numIdCtrl.text.trim());
      if (yaExiste) {
        _showError('Ya existe un paciente con ese número de identificación');
        setState(() => _guardando = false);
        return;
      }

      // PASO 1: Subir foto PRIMERO si existe (no bloquea si falla)
      String? fotoUrl;
      if (_fotoBytes != null) {
        debugPrint('🔵 Subiendo foto antes de crear paciente...');
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        try {
          fotoUrl = await _subirFoto(tempId);
          debugPrint('🔵 URL de foto obtenida: $fotoUrl');
        } catch (e) {
          debugPrint('⚠️ Error subiendo foto, continuando sin foto: $e');
          fotoUrl = null;
        }
      }

      // PASO 2: Crear paciente con la URL de la foto
      debugPrint('🔵 Creando paciente en Firestore...');
      debugPrint('🔵 Servicio: $_servicioNombre (ID: $_servicioId)');
      debugPrint('🔵 Clínica: $_clinicaNombre (ID: $_clinicaId)');
      final paciente = Paciente(
        id: '',
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        fechaNacimiento: _formatFecha(_fechaNac!),
        edad: _edad,
        genero: _genero,
        direccion: _direccionCtrl.text.trim(),
        ciudad: _ciudadCtrl.text.trim(),
        numeroIdentificacion: _numIdCtrl.text.trim(),
        tipoIdentificacion: _tipoId,
        alergias: _alergiasCtrl.text.trim(),
        condicionesPreexistentes: _condicionesCtrl.text.trim(),
        contactoEmergencia: ContactoEmergencia(
          nombre: _contactoNombreCtrl.text.trim(),
          telefono: _contactoTelCtrl.text.trim(),
          relacion: _contactoRelacion,
        ),
        estado: 'activo',
        registradoPor: usuario?.id ?? '',
        servicio: _servicioNombre,
        servicioId: _servicioId,
        clinica: _clinicaNombre,
        clinicaId: _clinicaId,
        fotoUrl: fotoUrl,
      );

      final nuevoId = await service.crearPaciente(paciente);
      debugPrint('✅ Paciente creado con ID: $nuevoId');
      debugPrint('✅ fotoUrl guardada: $fotoUrl');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paciente registrado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(selectedPacienteIdProvider.notifier).state = nuevoId;
        context.go('/pacientes/detalle');
      }
    } catch (e) {
      debugPrint('❌ Error guardando paciente: $e');
      _showError('Error al guardar. Intente de nuevo.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedIndex: 0,
      onNavigate: (_) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/pacientes'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Registrar Nuevo Paciente',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // ── Foto del Paciente ───────────────────────────────────────
              _SectionCard(
                title: 'Foto del Paciente',
                children: [
                  _buildSeccionFoto(),
                ],
              ),
              const SizedBox(height: 16),
              // ── Datos Personales ────────────────────────────────────────
              _SectionCard(
                title: 'Datos Personales',
                children: [
                  _Row2(
                    left: _Field(
                      label: 'Nombre *',
                      controller: _nombreCtrl,
                      validator: _requerido,
                    ),
                    right: _Field(
                      label: 'Apellido *',
                      controller: _apellidoCtrl,
                      validator: _requerido,
                    ),
                  ),
                  _Row2(
                    left: _Field(
                      label: 'Teléfono *',
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (!RegExp(r'^[\d\s\+\-\(\)]+$').hasMatch(v)) {
                          return 'Formato inválido';
                        }
                        return null;
                      },
                    ),
                    right: _Field(
                      label: 'Email',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$').hasMatch(v)) {
                          return 'Email inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  _Row2(
                    left: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fecha de Nacimiento *',
                            style: _labelStyle()),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _seleccionarFecha,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
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
                                  _fechaNac == null
                                      ? 'Seleccionar fecha'
                                      : '${_formatFecha(_fechaNac!)}  (${_edad} años)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _fechaNac == null
                                        ? AppColors.textDisabled
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    right: _Dropdown(
                      label: 'Género *',
                      value: _genero,
                      items: const ['Femenino', 'Masculino', 'Otro'],
                      onChanged: (v) => setState(() => _genero = v!),
                    ),
                  ),
                  _Row2(
                    left: _Field(
                      label: 'Número de DPI *',
                      controller: _numIdCtrl,
                      validator: _requerido,
                    ),
                    right: _Dropdown(
                      label: 'Tipo de Identificación *',
                      value: _tipoId,
                      items: const ['DPI', 'pasaporte', 'otro'],
                      onChanged: (v) => setState(() => _tipoId = v!),
                    ),
                  ),
                  _Row2(
                    left: _Field(
                      label: 'Dirección *',
                      controller: _direccionCtrl,
                      validator: _requerido,
                    ),
                    right: _Field(
                      label: 'Ciudad *',
                      controller: _ciudadCtrl,
                      validator: _requerido,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Datos Médicos ───────────────────────────────────────────
              _SectionCard(
                title: 'Datos Médicos',
                children: [
                  _Field(
                    label: 'Alergias (separadas por comas)',
                    controller: _alergiasCtrl,
                    hint: 'Ej: Penicilina, Látex, Aspirina',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    label: 'Condiciones Preexistentes',
                    controller: _condicionesCtrl,
                    hint: 'Ej: Diabetes tipo 2, Hipertensión',
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Contacto de Emergencia ──────────────────────────────────
              _SectionCard(
                title: 'Contacto de Emergencia',
                children: [
                  _Row2(
                    left: _Field(
                      label: 'Nombre del contacto',
                      controller: _contactoNombreCtrl,
                    ),
                    right: _Field(
                      label: 'Teléfono del contacto',
                      controller: _contactoTelCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  _Dropdown(
                    label: 'Relación',
                    value: _contactoRelacion,
                    items: const [
                      'familiar',
                      'padre',
                      'madre',
                      'esposo/a',
                      'hermano/a',
                      'amigo/a',
                      'otro',
                    ],
                    onChanged: (v) => setState(() => _contactoRelacion = v!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Servicio y Clínica (Obligatorios) ───────────────────────
              _SectionCard(
                title: 'Asignación de Servicio y Clínica *',
                children: [
                  _Row2(
                    left: _buildServicioDropdown(),
                    right: _buildClinicaDropdown(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // ── Botones de Acción ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Botón Cancelar
                  OutlinedButton(
                    onPressed: _guardando ? null : () => context.go('/pacientes'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Botón Guardar Paciente
                  ElevatedButton(
                    onPressed: (_guardando || _subiendoFoto) ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: _subiendoFoto
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Guardando...'),
                                ],
                              )
                            : const Text('Guardar Paciente'),
                  ),
                ],
              ),
              // Padding inferior para que el botón no quede pegado al borde
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String? _requerido(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null;

  TextStyle _labelStyle() => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        fontFamily: GoogleFonts.dmSans().fontFamily,
      );

  Widget _buildServicioDropdown() {
    final serviciosAsync = ref.watch(serviciosStreamProvider);
    return serviciosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (servicios) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Servicio *', style: _labelStyle()),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _servicioId,
              decoration: const InputDecoration(
                hintText: 'Selecciona un servicio',
              ),
              validator: (v) => v == null ? 'Campo requerido' : null,
              items: servicios
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.nombre),
                      ))
                  .toList(),
              onChanged: (v) {
                final servicio = servicios.firstWhere((s) => s.id == v);
                setState(() {
                  _servicioId = v;
                  _servicioNombre = servicio.nombre;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildClinicaDropdown() {
    final clinicasAsync = ref.watch(clinicasStreamProvider);
    return clinicasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (clinicas) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clínica *', style: _labelStyle()),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _clinicaId,
              decoration: const InputDecoration(
                hintText: 'Selecciona una clínica',
              ),
              validator: (v) => v == null ? 'Campo requerido' : null,
              items: clinicas
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.nombre),
                      ))
                  .toList(),
              onChanged: (v) {
                final clinica = clinicas.firstWhere((c) => c.id == v);
                setState(() {
                  _clinicaId = v;
                  _clinicaNombre = clinica.nombre;
                });
              },
            ),
          ],
        );
      },
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

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
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: GoogleFonts.dmSans().fontFamily,
            ),
          ),
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
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    this.hint,
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
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
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
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
