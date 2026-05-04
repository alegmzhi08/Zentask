import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  final _authService = AuthService();

  bool _esRegistro = true; // true = registro, false = login
  bool _cargando = false;
  String? _error;
  bool _verContrasena = false;

  void _submit() async {
    setState(() { _cargando = true; _error = null; });

    try {
      if (_esRegistro) {
        await _authService.registrar(
          _correoCtrl.text.trim(),
          _contrasenaCtrl.text.trim(),
          _usuarioCtrl.text.trim(),
        );
      } else {
        await _authService.iniciarSesion(
          _correoCtrl.text.trim(),
          _contrasenaCtrl.text.trim(),
        );
      }
      // Éxito: el StreamBuilder de PantallaInicial detecta el usuario
      // y navega a MainScreen automáticamente.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = e.message ?? 'Error de autenticación (${e.code})';
      setState(() => _error = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFFD9899A)),
      );
    } catch (e) {
      // Cubre TimeoutException (dominio no autorizado / red) y otros errores.
      if (!mounted) return;
      final msg = 'Error: $e';
      setState(() => _error = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFFD9899A)),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Logo
              const Center(
                child: Column(
                  children: [
                    SizedBox(height: 32),
                    Text('Zentask',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF3A4A3E),
                          fontStyle: FontStyle.italic,
                        )),
                    SizedBox(height: 4),
                    Text('Esfuerzo sin estrés',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7D9882),
                          letterSpacing: 2,
                        )),
                    SizedBox(height: 48),
                  ],
                ),
              ),

              // Título
              Text(
                _esRegistro ? 'Crear cuenta' : 'Bienvenido de nuevo',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3A4A3E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _esRegistro
                    ? 'Ingresa tus datos para comenzar'
                    : 'Inicia sesión para continuar',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7D9882),
                ),
              ),
              const SizedBox(height: 32),

              // Campo correo
              _label('Correo electrónico'),
              _campo(_correoCtrl, 'tu@correo.com',
                  tipo: TextInputType.emailAddress),
              const SizedBox(height: 16),

              // Campo usuario (solo en registro)
              if (_esRegistro) ...[
                _label('Nombre de usuario'),
                _campo(_usuarioCtrl, 'Ej. marco_rivera'),
                const SizedBox(height: 16),
              ],

              // Campo contraseña
              _label('Contraseña'),
              TextField(
                controller: _contrasenaCtrl,
                obscureText: !_verContrasena,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF3A4A3E)),
                decoration: InputDecoration(
                  hintText: 'Mínimo 6 caracteres',
                  hintStyle:
                      const TextStyle(color: Color(0xFF7D9882)),
                  filled: true,
                  fillColor: const Color(0xFFEAF4EB),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _verContrasena
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF7D9882),
                    ),
                    onPressed: () => setState(
                        () => _verContrasena = !_verContrasena),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFFD6E8D8), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFFD6E8D8), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFF8DC49A), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Mensaje de error
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFD9899A), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFD9899A))),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Botón principal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8DC49A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _cargando
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                      : Text(
                          _esRegistro ? 'Crear cuenta' : 'Iniciar sesión',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),

              // Cambiar entre login y registro
              Center(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _esRegistro = !_esRegistro;
                    _error = null;
                  }),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF7D9882)),
                      children: [
                        TextSpan(
                          text: _esRegistro
                              ? '¿Ya tienes cuenta? '
                              : '¿No tienes cuenta? ',
                        ),
                        TextSpan(
                          text: _esRegistro
                              ? 'Inicia sesión'
                              : 'Regístrate',
                          style: const TextStyle(
                            color: Color(0xFF8DC49A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(texto,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: Color(0xFF7D9882))),
      );

  Widget _campo(TextEditingController ctrl, String hint,
      {TextInputType tipo = TextInputType.text}) =>
      TextField(
        controller: ctrl,
        keyboardType: tipo,
        style:
            const TextStyle(fontSize: 14, color: Color(0xFF3A4A3E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF7D9882)),
          filled: true,
          fillColor: const Color(0xFFEAF4EB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFFD6E8D8), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFFD6E8D8), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFF8DC49A), width: 1.5),
          ),
        ),
      );
}