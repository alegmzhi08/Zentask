import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? error;

  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      setState(() => error = 'Correo o contraseña incorrectos');
    }
  }

  Future<void> registrarse() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      setState(() => error = 'Error al registrarse. Intenta con otro correo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / ícono
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF8DC49A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              const Text('Zentask',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3A4A3E))),
              const SizedBox(height: 8),
              const Text('Organiza tus tareas fácilmente',
                  style: TextStyle(fontSize: 14, color: Color(0xFF7D9882))),
              const SizedBox(height: 40),

              // Campo correo
              TextField(
                controller: emailController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF3A4A3E)),
                decoration: InputDecoration(
                  labelText: 'Correo',
                  labelStyle: const TextStyle(color: Color(0xFF7D9882)),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF8DC49A)),
                  filled: true,
                  fillColor: const Color(0xFFEAF4EB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFD6E8D8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFD6E8D8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF8DC49A), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campo contraseña
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(fontSize: 14, color: Color(0xFF3A4A3E)),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: const TextStyle(color: Color(0xFF7D9882)),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8DC49A)),
                  filled: true,
                  fillColor: const Color(0xFFEAF4EB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFD6E8D8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFD6E8D8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF8DC49A), width: 2),
                  ),
                ),
              ),

              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 24),

              // Botón entrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8DC49A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Entrar',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),

              // Botón registrarse
              TextButton(
                onPressed: registrarse,
                child: const Text('¿No tienes cuenta? Regístrate',
                    style: TextStyle(color: Color(0xFF7D9882))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}