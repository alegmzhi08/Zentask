import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const _timeout = Duration(seconds: 15);

  /// Lanza [FirebaseAuthException] si falla. Lanza [TimeoutException] si la
  /// red no responde en [_timeout] segundos (frecuente en web con CORS / dominio
  /// no autorizado en Firebase Console).
  Future<void> registrar(
      String correo, String contrasena, String username) async {
    final credencial = await _auth
        .createUserWithEmailAndPassword(email: correo, password: contrasena)
        .timeout(_timeout);
    await credencial.user?.updateDisplayName(username);
    await _guardarSesion(true);
  }

  Future<void> iniciarSesion(String correo, String contrasena) async {
    await _auth
        .signInWithEmailAndPassword(email: correo, password: contrasena)
        .timeout(_timeout);
    await _guardarSesion(true);
  }

  Future<void> cerrarSesion() async {
    await _auth.signOut();
    await _guardarSesion(false);
  }

  Future<bool> haySession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sesion_activa') ?? false;
  }

  User? get usuarioActual => _auth.currentUser;

  Future<void> _guardarSesion(bool activa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sesion_activa', activa);
  }
}
