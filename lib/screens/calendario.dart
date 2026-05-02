import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  MODELO TEMPORAL (reemplazar con tu Tarea real)
// ─────────────────────────────────────────────
class _TareaPreview {
  final String nombre;
  final String materia;
  final DateTime fechaEntrega;
  final int diasRestantes;

  const _TareaPreview({
    required this.nombre,
    required this.materia,
    required this.fechaEntrega,
    required this.diasRestantes,
  });
}

// ─────────────────────────────────────────────
//  PANTALLA PRINCIPAL
// ─────────────────────────────────────────────
class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _mesActual = DateTime(DateTime.now().year, DateTime.now().month);
  int? _diaSeleccionado;

  // ── Datos de prueba (luego vendrán de la base de datos)
  final List<_TareaPreview> _tareas = [
    _TareaPreview(
      nombre: 'Parcial de Estadística',
      materia: 'Estadística II',
      fechaEntrega: DateTime(2026, 5, 8),
      diasRestantes: 3,
    ),
    _TareaPreview(
      nombre: 'Taller de Derivadas',
      materia: 'Cálculo III',
      fechaEntrega: DateTime(2026, 5, 14),
      diasRestantes: 6,
    ),
    _TareaPreview(
      nombre: 'Ensayo Reforma de Salud',
      materia: 'Política Pública',
      fechaEntrega: DateTime(2026, 5, 20),
      diasRestantes: 2,
    ),
    _TareaPreview(
      nombre: 'Quiz de Redes',
      materia: 'Redes de Computadores',
      fechaEntrega: DateTime(2026, 5, 28),
      diasRestantes: 8,
    ),
  ];

  // ── Días que tienen tarea en el mes actual
  Set<int> get _diasConTarea {
    return _tareas
        .where((t) =>
            t.fechaEntrega.year == _mesActual.year &&
            t.fechaEntrega.month == _mesActual.month)
        .map((t) => t.fechaEntrega.day)
        .toSet();
  }

  // ── Tareas del día seleccionado (o todas si no hay día seleccionado)
  List<_TareaPreview> get _tareasVisibles {
    if (_diaSeleccionado == null) return _tareas;
    return _tareas
        .where((t) =>
            t.fechaEntrega.year == _mesActual.year &&
            t.fechaEntrega.month == _mesActual.month &&
            t.fechaEntrega.day == _diaSeleccionado)
        .toList();
  }

  void _mesAnterior() {
    setState(() {
      _mesActual = DateTime(_mesActual.year, _mesActual.month - 1);
      _diaSeleccionado = null;
    });
  }

  void _mesSiguiente() {
    setState(() {
      _mesActual = DateTime(_mesActual.year, _mesActual.month + 1);
      _diaSeleccionado = null;
    });
  }

  void _seleccionarDia(int dia) {
    setState(() {
      _diaSeleccionado = _diaSeleccionado == dia ? null : dia;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4FBF5),
        elevation: 0,
        title: const Text(
          'Calendario',
          style: TextStyle(
            color: Color(0xFF3A4A3E),
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF3A4A3E)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera del mes
            _CabeceraMes(
              mesActual: _mesActual,
              onAnterior: _mesAnterior,
              onSiguiente: _mesSiguiente,
            ),
            const SizedBox(height: 12),

            // ── Grid del calendario
            _GridCalendario(
              mesActual: _mesActual,
              diasConTarea: _diasConTarea,
              diaSeleccionado: _diaSeleccionado,
              onDiaTap: _seleccionarDia,
            ),
            const SizedBox(height: 20),

            // ── Etiqueta de sección
            _label(
              _diaSeleccionado != null
                  ? 'TAREAS DEL DÍA $_diaSeleccionado'
                  : 'TAREAS DEL MES',
            ),
            const SizedBox(height: 10),

            // ── Lista de tareas
            if (_tareasVisibles.isEmpty)
              _SinTareas()
            else
              ..._tareasVisibles
                  .map((t) => _TarjetaTarea(
                        tarea: t,
                        onTap: () {
                          // TODO: navegar al detalle de la tarea
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Abriendo "${t.nombre}"…'),
                              backgroundColor: const Color(0xFF8DC49A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ))
                  .toList(),

            const SizedBox(height: 20),

            // ── Banner "hoy debes estudiar"
            _BannerHoy(
              onTap: () {
                // TODO: navegar al temporizador / sesión de hoy
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Iniciando sesión de estudio…'),
                    backgroundColor: Color(0xFF8DC49A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _label(String texto) => Text(
        texto,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: Color(0xFF7D9882),
        ),
      );
}

// ─────────────────────────────────────────────
//  CABECERA DEL MES
// ─────────────────────────────────────────────
class _CabeceraMes extends StatelessWidget {
  final DateTime mesActual;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  const _CabeceraMes({
    required this.mesActual,
    required this.onAnterior,
    required this.onSiguiente,
  });

  static const _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_meses[mesActual.month - 1]} ${mesActual.year}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3A4A3E),
          ),
        ),
        Row(
          children: [
            _BotonNavMes(
              icono: Icons.chevron_left,
              onTap: onAnterior,
            ),
            const SizedBox(width: 8),
            _BotonNavMes(
              icono: Icons.chevron_right,
              onTap: onSiguiente,
            ),
          ],
        ),
      ],
    );
  }
}

class _BotonNavMes extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;

  const _BotonNavMes({required this.icono, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFEAF4EB),
          border: Border.all(color: const Color(0xFFD6E8D8), width: 1.5),
        ),
        child: Icon(icono, size: 18, color: const Color(0xFF7D9882)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  GRID DEL CALENDARIO
// ─────────────────────────────────────────────
class _GridCalendario extends StatelessWidget {
  final DateTime mesActual;
  final Set<int> diasConTarea;
  final int? diaSeleccionado;
  final ValueChanged<int> onDiaTap;

  const _GridCalendario({
    required this.mesActual,
    required this.diasConTarea,
    required this.diaSeleccionado,
    required this.onDiaTap,
  });

  static const _diasSemana = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];

  int get _primerDiaSemana {
    // 1=lunes … 7=domingo  →  0-indexed para el grid
    final d = DateTime(mesActual.year, mesActual.month, 1).weekday;
    return d - 1; // lunes=0
  }

  int get _diasEnMes =>
      DateTime(mesActual.year, mesActual.month + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final esEsteMes = hoy.year == mesActual.year && hoy.month == mesActual.month;

    return Column(
      children: [
        // Encabezados
        Row(
          children: _diasSemana
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: (d == 'Sa' || d == 'Do')
                              ? const Color(0xFFFFAB40)
                              : const Color(0xFF7D9882),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        // Celdas
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 38,
          ),
          itemCount: _primerDiaSemana + _diasEnMes,
          itemBuilder: (_, index) {
            if (index < _primerDiaSemana) return const SizedBox();
            final dia = index - _primerDiaSemana + 1;
            final esHoy = esEsteMes && dia == hoy.day;
            final esSel = dia == diaSeleccionado;
            final tieneTarea = diasConTarea.contains(dia);

            return GestureDetector(
              onTap: () => onDiaTap(dia),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: esHoy
                          ? const Color(0xFF8DC49A)
                          : esSel
                              ? const Color(0xFFD6E8D8)
                              : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        '$dia',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: esHoy || esSel
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: esHoy
                              ? Colors.white
                              : const Color(0xFF3A4A3E),
                        ),
                      ),
                    ),
                  ),
                  if (tieneTarea && !esHoy)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF8DC49A),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  TARJETA DE TAREA
// ─────────────────────────────────────────────
class _TarjetaTarea extends StatelessWidget {
  final _TareaPreview tarea;
  final VoidCallback onTap;

  const _TarjetaTarea({required this.tarea, required this.onTap});

  Color get _colorFecha {
    if (tarea.diasRestantes <= 2) return const Color(0xFFFCECEA);
    if (tarea.diasRestantes <= 5) return const Color(0xFFFFF8E1);
    return const Color(0xFFEAF4EB);
  }

  Color get _colorBadge {
    if (tarea.diasRestantes <= 2) return const Color(0xFFE53935);
    if (tarea.diasRestantes <= 5) return const Color(0xFFFF8F00);
    return const Color(0xFF4CAF50);
  }

  Color get _colorBadgeFondo {
    if (tarea.diasRestantes <= 2) return const Color(0xFFFCECEA);
    if (tarea.diasRestantes <= 5) return const Color(0xFFFFF8E1);
    return const Color(0xFFE8F5E9);
  }

  static const _meses = [
    'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
    'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD6E8D8), width: 1.5),
        ),
        child: Row(
          children: [
            // Fecha
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _colorFecha,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${tarea.fechaEntrega.day}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3A4A3E),
                      height: 1,
                    ),
                  ),
                  Text(
                    _meses[tarea.fechaEntrega.month - 1],
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7D9882),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Nombre y materia
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tarea.nombre,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3A4A3E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tarea.materia,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7D9882),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Badge días restantes
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _colorBadgeFondo,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${tarea.diasRestantes} días',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _colorBadge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ESTADO VACÍO
// ─────────────────────────────────────────────
class _SinTareas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF8DC49A), size: 36),
          SizedBox(height: 8),
          Text(
            'Sin tareas para este día',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF7D9882),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BANNER DE HOY
// ─────────────────────────────────────────────
class _BannerHoy extends StatelessWidget {
  final VoidCallback onTap;

  const _BannerHoy({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF8DC49A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'HOY DEBES ESTUDIAR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEAF4EB),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Estadística · 25 min × 2',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.25),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}