import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../mock/mock_data.dart';
import 'auth_service.dart';

class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Poblar Firestore con datos iniciales (ejecutar UNA SOLA VEZ)
  Future<void> seedTodo() async {
    try {
      // 1. Crear admin en Firebase Auth. Si ya existe, el seed ya corrió → abortar.
      final adminUid = await _crearAdminEnAuth();
      if (adminUid == null) {
        print('Seed ya fue ejecutado anteriormente - abortando');
        return;
      }

      // 2. Iniciar sesión como admin (la regla de Firestore permite que un usuario
      //    autenticado cree su propio documento, rompiendo el ciclo circular).
      await _firebaseAuth.signInWithEmailAndPassword(
        email: 'admin@renova.gt',
        password: 'renova2024',
      );
      print('  ✓ Sesión de seed iniciada como admin');

      // 3. Escribir el documento del admin en Firestore (ahora sí autenticado)
      await _escribirDocAdmin(adminUid);

      // 4. Con el documento admin en Firestore, las demás escrituras están permitidas
      await _seedUsuarios();
      await _seedSalas();
      await _seedTerapeutas();
      await _seedPacientes();
      await _seedCitas();
      await _seedPlanes();

      // 5. Cerrar sesión para dejar la app en estado limpio
      await _firebaseAuth.signOut();

      print('✅ Seed completado exitosamente');
    } catch (e) {
      print('❌ Error durante seed: $e');
      await _firebaseAuth.signOut();
    }
  }

  /// Crea el admin en Firebase Auth (sin Firestore todavía).
  /// Retorna el UID si se creó, null si ya existía.
  Future<String?> _crearAdminEnAuth() async {
    const adminEmail = 'admin@renova.gt';
    const adminPassword = 'renova2024';

    final secondaryApp = await Firebase.initializeApp(
      name: 'seedApp_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      return credential.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return null;
      rethrow;
    } finally {
      await secondaryApp.delete();
    }
  }

  /// Escribe el documento del admin en Firestore (requiere sesión activa como admin).
  Future<void> _escribirDocAdmin(String uid) async {
    final usuario = Usuario(
      id: uid,
      nombre: 'Dra. Vania López',
      email: 'admin@renova.gt',
      password: '',
      rol: RolUsuario.administradora,
      activo: true,
      avatarIniciales: 'VL',
    );
    await _db.collection('usuarios').doc(uid).set(usuario.toMap());
    print('  ✓ Documento admin creado en Firestore');
  }

  Future<void> _seedUsuarios() async {
    print('Sembrando usuarios...');
    final authService = AuthService();
    final usuarios = [
      ('Enf. Carmen Soto', 'carmen@renova.gt', 'renova2024', RolUsuario.enfermera),
      ('Enf. Rosa Ajú', 'rosa@renova.gt', 'renova2024', RolUsuario.enfermera),
      ('Terapeuta Luis Choc', 'luis@renova.gt', 'renova2024', RolUsuario.terapeuta),
      ('Terapeuta Ana Pac', 'ana@renova.gt', 'renova2024', RolUsuario.terapeuta),
    ];

    for (final (nombre, email, password, rol) in usuarios) {
      try {
        final usuario = await authService.crearUsuario(
          nombre: nombre,
          email: email,
          password: password,
          rol: rol,
        );
        if (usuario != null) {
          print('  ✓ Usuario creado: $email');
        }
      } catch (e) {
        print('  ⚠ Error creando usuario $email: $e');
      }
    }
  }

  Future<void> _seedSalas() async {
    print('Sembrando salas...');
    final salas = [
      ('Sala de Masajes 1', TipoSala.sala_masajes),
      ('Sala de Masajes 2', TipoSala.sala_masajes),
      ('Jacuzzi Premium', TipoSala.jacuzzi),
      ('Sala de Terapia Avanzada', TipoSala.sala_terapia),
      ('Sala Estética', TipoSala.sala_estetica),
      ('Sala de Sueroterapia', TipoSala.sala_suero),
    ];

    for (final (nombre, tipo) in salas) {
      final sala = Sala(
        id: '',
        nombre: nombre,
        tipo: tipo,
        disponible: true,
      );
      await _db.collection('salas').add(sala.toMap());
      print('  ✓ Sala creada: $nombre');
    }
  }

  Future<void> _seedTerapeutas() async {
    print('Sembrando terapeutas...');
    final terapeutas = [
      ('Terapeuta Luis Choc', EspecialidadTerapeuta.masajista, 'luis@renova.gt'),
      ('Terapeuta Ana Pac', EspecialidadTerapeuta.sueroterapista, 'ana@renova.gt'),
    ];

    for (final (nombre, especialidad, usuarioId) in terapeutas) {
      final terapeuta = Terapeuta(
        id: '',
        nombre: nombre,
        especialidad: especialidad,
        disponible: true,
        usuarioId: usuarioId,
      );
      await _db.collection('terapeutas').add(terapeuta.toMap());
      print('  ✓ Terapeuta creado: $nombre');
    }
  }

  Future<void> _seedPacientes() async {
    print('Sembrando pacientes...');
    final pacientes = [
      Patient(
        id: '',
        nombre: 'María José Pérez Xol',
        expediente: 'EXP-2024-001',
        dpi: '1234567890123',
        telefono: '+502 7123-4567',
        fechaNacimiento: '1979-03-15',
        edad: 45,
        tipoSangre: 'O+',
        alergias: ['Penicilina', 'Asparténo'],
        condicionesBase: ['Hipertensión', 'Diabetes tipo 2'],
        medicamentosActuales: ['Losartán 50mg', 'Metformina 850mg'],
        registradoPor: 'admin@renova.gt',
      ),
      Patient(
        id: '',
        nombre: 'Carlos Enrique Ajú Toj',
        expediente: 'EXP-2024-002',
        dpi: '9876543210987',
        telefono: '+502 7234-5678',
        fechaNacimiento: '1962-07-22',
        edad: 62,
        tipoSangre: 'A+',
        alergias: [],
        condicionesBase: ['Hiperlipidemia'],
        medicamentosActuales: ['Atorvastatina 40mg'],
        registradoPor: 'carmen@renova.gt',
      ),
      Patient(
        id: '',
        nombre: 'Luisa Fernanda Caal Pop',
        expediente: 'EXP-2024-003',
        dpi: '5555555555555',
        telefono: '+502 7345-6789',
        fechaNacimiento: '1995-11-10',
        edad: 30,
        tipoSangre: 'AB+',
        alergias: ['Látex'],
        condicionesBase: [],
        medicamentosActuales: [],
        registradoPor: 'admin@renova.gt',
      ),
      Patient(
        id: '',
        nombre: 'Jorge Luis González Morales',
        expediente: 'EXP-2024-004',
        dpi: '4444444444444',
        telefono: '+502 7456-7890',
        fechaNacimiento: '1989-05-18',
        edad: 36,
        tipoSangre: 'B-',
        alergias: [],
        condicionesBase: ['Acné severo'],
        medicamentosActuales: ['Isotretinoína'],
        registradoPor: 'rosa@renova.gt',
      ),
      Patient(
        id: '',
        nombre: 'Patricia Elena Rivas López',
        expediente: 'EXP-2024-005',
        dpi: '3333333333333',
        telefono: '+502 7567-8901',
        fechaNacimiento: '1972-09-08',
        edad: 52,
        tipoSangre: 'O-',
        alergias: ['Sulfas'],
        condicionesBase: ['Fotoenvejecimiento'],
        medicamentosActuales: ['Protector solar SPF 50'],
        registradoPor: 'admin@renova.gt',
      ),
      Patient(
        id: '',
        nombre: 'Diana Margarita Cotzal Sic',
        expediente: 'EXP-2024-006',
        dpi: '2222222222222',
        telefono: '+502 7678-9012',
        fechaNacimiento: '1998-02-14',
        edad: 26,
        tipoSangre: 'AB-',
        alergias: ['Árnica'],
        condicionesBase: ['Celulitis'],
        medicamentosActuales: [],
        registradoPor: 'rosa@renova.gt',
      ),
    ];

    for (final paciente in pacientes) {
      await _db.collection('pacientes').add(paciente.toMap());
      print('  ✓ Paciente creado: ${paciente.nombre}');
    }
  }

  Future<void> _seedCitas() async {
    print('Sembrando citas...');
    final hoy = DateTime.now();
    
    final citas = [
      Appointment(
        id: '',
        pacienteId: 'PAC001',
        terapeutaId: 'TER001',
        salaId: 'SAL001',
        tipoServicio: TipoServicio.masaje,
        fecha: hoy,
        hora: '08:30',
        duracionMinutos: 60,
        precioBase: 350.00,
        estado: EstadoCita.confirmada,
        notas: 'Masaje relajante enfocado en cervical',
      ),
      Appointment(
        id: '',
        pacienteId: 'PAC002',
        terapeutaId: 'TER002',
        salaId: 'SAL006',
        tipoServicio: TipoServicio.sueroterapia,
        fecha: hoy,
        hora: '10:00',
        duracionMinutos: 45,
        precioBase: 450.00,
        estado: EstadoCita.confirmada,
        notas: 'Sueroterapia con ácido hialurónico',
      ),
      Appointment(
        id: '',
        pacienteId: 'PAC003',
        terapeutaId: 'TER001',
        salaId: 'SAL003',
        tipoServicio: TipoServicio.jacuzzi,
        fecha: hoy,
        hora: '14:30',
        duracionMinutos: 45,
        precioBase: 250.00,
        estado: EstadoCita.agendada,
      ),
      Appointment(
        id: '',
        pacienteId: 'PAC004',
        terapeutaId: 'TER002',
        salaId: 'SAL005',
        tipoServicio: TipoServicio.estetica,
        fecha: hoy,
        hora: '16:00',
        duracionMinutos: 60,
        precioBase: 550.00,
        estado: EstadoCita.confirmada,
        notas: 'Limpieza profunda + peeling químico',
      ),
      Appointment(
        id: '',
        pacienteId: 'PAC005',
        terapeutaId: 'TER001',
        salaId: 'SAL004',
        tipoServicio: TipoServicio.terapia_avanzada,
        fecha: hoy,
        hora: '17:30',
        duracionMinutos: 90,
        precioBase: 650.00,
        estado: EstadoCita.agendada,
      ),
    ];

    for (final cita in citas) {
      await _db.collection('citas').add(cita.toMap());
      print('  ✓ Cita creada: ${cita.hora}');
    }
  }

  Future<void> _seedPlanes() async {
    print('Sembrando planes de tratamiento...');
    final planes = [
      PlanTratamiento(
        id: '',
        pacienteId: 'PAC001',
        diagnostico: 'Contractura cervical crónica',
        totalSesiones: 10,
        sesionesCompletadas: 3,
        objetivo: 'Reducir tensión y mejorar movilidad cervical',
        fechaInicio: DateTime.now().toString().split(' ')[0],
        activo: true,
      ),
      PlanTratamiento(
        id: '',
        pacienteId: 'PAC002',
        diagnostico: 'Rejuvenecimiento facial integral',
        totalSesiones: 6,
        sesionesCompletadas: 1,
        objetivo: 'Mejorar apariencia y elasticidad facial',
        fechaInicio: DateTime.now().toString().split(' ')[0],
        activo: true,
      ),
      PlanTratamiento(
        id: '',
        pacienteId: 'PAC004',
        diagnostico: 'Tratamiento de acné severo',
        totalSesiones: 8,
        sesionesCompletadas: 2,
        objetivo: 'Controlar brote y mejorar textura de piel',
        fechaInicio: DateTime.now().toString().split(' ')[0],
        activo: true,
      ),
    ];

    for (final plan in planes) {
      await _db.collection('planes').add(plan.toMap());
      print('  ✓ Plan creado: ${plan.diagnostico}');
    }
  }
}
