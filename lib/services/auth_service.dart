import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Registrar usuario nuevo
  Future<String?> registrar(String correo, String contrasena, String username) async {
  try {
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: correo,
      password: contrasena,
    );
    // Guarda el nombre de usuario en Firebase
    await credencial.user?.updateDisplayName(username);
    await _guardarSesion(true);
    return null;
  } on FirebaseAuthException catch (e) {
    return _mensajeError(e.code);
  }
}

  // Iniciar sesión
  Future<String?> iniciarSesion(String correo, String contrasena) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: correo,
        password: contrasena,
      );
      await _guardarSesion(true);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mensajeError(e.code);
    }
  }

  // Cerrar sesión
  Future<void> cerrarSesion() async {
    await _auth.signOut();
    await _guardarSesion(false);
  }

  // Verifica si ya hay sesión guardada
  Future<bool> haySession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sesion_activa') ?? false;
  }

  // Obtener usuario actual
  User? get usuarioActual => _auth.currentUser;

  // Guarda en el dispositivo si hay sesión activa
  Future<void> _guardarSesion(bool activa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sesion_activa', activa);
  }

  // Traduce los errores de Firebase a español
  String _mensajeError(String codigo) {
    switch (codigo) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'invalid-email':
        return 'El correo no es válido';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'user-not-found':
        return 'No existe una cuenta con este correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      default:
        return 'Ocurrió un error, intenta de nuevo';
    }
  }
}