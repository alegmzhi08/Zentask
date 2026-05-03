// lib/screens/crear_tarea_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tarea.dart';
import '../services/task_service.dart';

class CrearTareaScreen extends StatefulWidget {
  const CrearTareaScreen({super.key});

  @override
  State<CrearTareaScreen> createState() => _CrearTareaScreenState();
}

class _CrearTareaScreenState extends State<CrearTareaScreen> {
  final _nombreCtrl = TextEditingController();
  final _materiaCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  int _tiempoSesion = 25;
  int _sesionesPorDia = 1;

  final List<String> _diasSemana = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];
  final List<bool> _diasSeleccionados = List.filled(7, false);

  void _guardarTarea() {
    if (_nombreCtrl.text.isEmpty ||
        _materiaCtrl.text.isEmpty ||
        _fechaEntrega == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    final diasElegidos = <String>[];
    for (int i = 0; i < _diasSemana.length; i++) {
      if (_diasSeleccionados[i]) diasElegidos.add(_diasSemana[i]);
    }

    final nuevaTarea = Tarea(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: _nombreCtrl.text,
      materia: _materiaCtrl.text,
      fechaEntrega: _fechaEntrega!,
      diasTrabajo: diasElegidos,
      tiempoSesion: _tiempoSesion,
      sesionesPorDia: _sesionesPorDia,
    );

    debugPrint('Tarea creada: ${nuevaTarea.nombre}');
    Navigator.pop(context, nuevaTarea);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4FBF5),
        elevation: 0,
        title: const Text('Nueva tarea',
            style: TextStyle(
                color: Color(0xFF3A4A3E), fontWeight: FontWeight.w500)),
        iconTheme: const IconThemeData(color: Color(0xFF3A4A3E)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF7D9882)),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Nombre ────────────────────────────────────────────────────
            _label('Nombre de la tarea'),
            _campo(_nombreCtrl, 'Ej. Parcial de Estadística'),
            const SizedBox(height: 16),

            // ── Materia ───────────────────────────────────────────────────
            _label('Materia'),
            _campo(_materiaCtrl, 'Ej. Cálculo III'),
            const SizedBox(height: 16),

            _label('Fecha de entrega'),
            GestureDetector(
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (fecha != null) setState(() => _fechaEntrega = fecha);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4EB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFD6E8D8), width: 1.5),
                ),
                child: Text(
                  _fechaEntrega == null
                      ? 'Seleccionar fecha'
                      : '${_fechaEntrega!.day}/${_fechaEntrega!.month}/${_fechaEntrega!.year}',
                  style: TextStyle(
                    color: _fechaEntrega == null
                        ? const Color(0xFF7D9882)
                        : const Color(0xFF3A4A3E),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Rango de fechas ───────────────────────────────────────────
            _label('Rango de fechas'),
            _DateTile(
              icon: Icons.date_range_outlined,
              label: _dateRangeLabel,
              filled: _startDate != null && _endDate != null,
              onTap: _pickDateRange,
            ),
            const SizedBox(height: 16),

            // ── Tiempo por sesión ─────────────────────────────────────────
            _label('Tiempo por sesión: $_tiempoSesion min'),
            Slider(
              value: _tiempoSesion.toDouble(),
              min: 15,
              max: 120,
              divisions: 7,
              activeColor: const Color(0xFF8DC49A),
              label: '$_tiempoSesion min',
              onChanged: (v) => setState(() => _tiempoSesion = v.round()),
            ),
            const SizedBox(height: 8),

            // ── Sesiones por día ──────────────────────────────────────────
            _label('Sesiones por día: $_sesionesPorDia'),
            Slider(
              value: _sesionesPorDia.toDouble(),
              min: 1,
              max: 4,
              divisions: 3,
              activeColor: const Color(0xFF8DC49A),
              label: '$_sesionesPorDia',
              onChanged: (v) => setState(() => _sesionesPorDia = v.round()),
            ),
            const SizedBox(height: 16),

            // ── Días a trabajar ───────────────────────────────────────────
            _label('Días a trabajar'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final sel = _diasSeleccionados[i];
                return GestureDetector(
                  onTap: () => setState(
                      () => _diasSeleccionados[i] = !seleccionado),
                  onTap: () => setState(() => _diasSeleccionados[i] = !sel),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sel
                          ? const Color(0xFF8DC49A)
                          : const Color(0xFFEAF4EB),
                      border: Border.all(
                        color: sel
                            ? const Color(0xFF8DC49A)
                            : const Color(0xFFD6E8D8),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _diasSemana[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : const Color(0xFF7D9882),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // ── Botón guardar ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardarTarea,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8DC49A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Crear tarea',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<int> get _workingDays => [
    for (int i = 0; i < _diasSeleccionados.length; i++)
      if (_diasSeleccionados[i]) i + 1,
  ];

  void _resetForm() {
    setState(() {
      _nombreCtrl.clear();
      _materiaCtrl.clear();
      _startDate = null;
      _endDate = null;
      _tiempoSesion = 25;
      _sesionesPorDia = 1;
      for (var i = 0; i < _diasSeleccionados.length; i++) {
        _diasSeleccionados[i] = false;
      }
    });
  }

  String get _dateRangeLabel {
    if (_startDate == null || _endDate == null) {
      return 'Seleccionar rango';
    }

    return '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  Widget _label(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      texto,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: Color(0xFF7D9882),
      ),
    ),
  );

  Widget _campo(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        style: const TextStyle(fontSize: 14, color: Color(0xFF3A4A3E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF7D9882)),
          filled: true,
          fillColor: const Color(0xFFEAF4EB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFD6E8D8), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFD6E8D8), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFF8DC49A), width: 1.5),
    controller: ctrl,
    style: const TextStyle(fontSize: 14, color: Color(0xFF3A4A3E)),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF7D9882)),
      filled: true,
      fillColor: const Color(0xFFEAF4EB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD6E8D8), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD6E8D8), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF8DC49A), width: 1.5),
      ),
    ),
  );
}

// ── Tile genérico para date/time pickers ─────────────────────────────────────

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF4EB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? const Color(0xFF8DC49A) : const Color(0xFFD6E8D8),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF7D9882)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: filled
                      ? const Color(0xFF3A4A3E)
                      : const Color(0xFF7D9882),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
