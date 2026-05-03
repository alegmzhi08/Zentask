// lib/screens/inicio_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  static const int _trabajoSeg = 25 * 60;
  static const int _descansoCortaSeg = 5 * 60;
  static const int _descansoLargoSeg = 15 * 60;

  static const Color _colorTrabajo = Color(0xFF8DC49A);

  Timer? _timer;
  int _segundosRestantes = _trabajoSeg;
  bool _corriendo = false;
  bool _esTrabajo = true;
  int _pomodorosEnCiclo = 0; // 0–3; al llegar a 4 se da descanso largo

  int get _duracionTotal =>
      _esTrabajo ? _trabajoSeg : (_pomodorosEnCiclo == 0 ? _descansoLargoSeg : _descansoCortaSeg);

  void _iniciarPausar() {
    if (_corriendo) {
      _timer?.cancel();
      setState(() => _corriendo = false);
      return;
    }
    setState(() => _corriendo = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_segundosRestantes <= 1) {
        _alTerminar();
      } else {
        setState(() => _segundosRestantes--);
      }
    });
  }

  void _reiniciar() {
    _timer?.cancel();
    setState(() {
      _corriendo = false;
      _segundosRestantes = _duracionTotal;
    });
  }

  void _alTerminar() {
    _timer?.cancel();
    setState(() {
      _corriendo = false;
      if (_esTrabajo) {
        _pomodorosEnCiclo = (_pomodorosEnCiclo + 1) % 4;
        _esTrabajo = false;
      } else {
        _esTrabajo = true;
      }
      _segundosRestantes = _duracionTotal;
    });

    final mensaje = _esTrabajo ? '¡A trabajar! 💪' : '¡Tómate un descanso! ☕';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 3)),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _tiempoFormateado {
    final min = _segundosRestantes ~/ 60;
    final seg = _segundosRestantes % 60;
    return '${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }

  Color get _colorModo => _esTrabajo ? _colorTrabajo : Colors.amber.shade600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.sync), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ── Perfil
            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFF8DC49A),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 12),
            FutureBuilder<void>(
  future: FirebaseAuth.instance.currentUser?.reload(),
  builder: (context, snapshot) {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      children: [
        Text(
          user?.displayName ?? user?.email?.split('@')[0] ?? 'Usuario',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          user?.email ?? '',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  },
),
            const SizedBox(height: 28),

            // ── Timer Pomodoro
            _buildTimerSection(),
            const SizedBox(height: 28),

            // ── Estadísticas
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard('Tareas Pendientes', '0', 'Ultimos 7 días', Colors.amber.shade700),
                _buildStatCard('Tareas Vencidas', '0', 'Total', Colors.red.shade400),
                _buildStatCard('Tareas Completadas', '0', 'Ultimos 7 días', Colors.green.shade600),
                _buildStatCard('Tu Racha', '0', 'Racha Total', Colors.orange.shade600),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD6E8D8), width: 1.5),
      ),
      child: Column(
        children: [
          // Chip de modo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _colorModo.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _esTrabajo ? 'Trabajo' : (_pomodorosEnCiclo == 0 ? 'Descanso largo' : 'Descanso'),
              style: TextStyle(
                color: _colorModo,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Círculo del timer
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: _segundosRestantes / _duracionTotal,
                    strokeWidth: 9,
                    backgroundColor: const Color(0xFFD6E8D8),
                    valueColor: AlwaysStoppedAnimation<Color>(_colorModo),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  _tiempoFormateado,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3A4A3E),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Controles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _reiniciar,
                icon: const Icon(Icons.refresh_rounded),
                iconSize: 28,
                color: const Color(0xFF7D9882),
                tooltip: 'Reiniciar',
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _iniciarPausar,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _colorModo,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _colorModo.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _corriendo ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const SizedBox(width: 28), // espaciador para centrar el play
            ],
          ),
          const SizedBox(height: 20),

          // Dots del ciclo (4 pomodoros = 1 ciclo)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final completado = i < _pomodorosEnCiclo;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: completado ? 10 : 8,
                  height: completado ? 10 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completado ? _colorTrabajo : const Color(0xFFD6E8D8),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, String subtitle, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(count, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
