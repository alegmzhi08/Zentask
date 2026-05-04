// lib/screens/calendario.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tarea.dart';
import '../services/db_service.dart';

enum CalendarView { mes, semana, dia }

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarView _currentView = CalendarView.mes;
  List<Tarea> _tareasDelDia = [];
  final _db = DbService();

  CalendarFormat get _tableCalendarFormat => switch (_currentView) {
        CalendarView.semana => CalendarFormat.week,
        _ => CalendarFormat.month,
      };

  @override
  void initState() {
    super.initState();
    _cargarTareas(DateTime.now());
  }

  Future<void> _cargarTareas(DateTime fecha) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final tareas = await _db.obtenerTareasPorFecha(uid, fecha);
    setState(() {
      _selectedDay = fecha;
      _tareasDelDia = tareas;
    });
  }

  Future<void> _completarTarea(Tarea tarea) async {
    await _db.completarTarea(tarea.id);
    await _cargarTareas(_selectedDay);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Tarea completada! 🎉'),
          backgroundColor: Color(0xFF8DC49A),
        ),
      );
    }
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
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF3A4A3E)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF7D9882)),
            onPressed: () => _cargarTareas(_selectedDay),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildViewSelector(),
          if (_currentView == CalendarView.dia)
            Expanded(child: _buildDailyTimeline(_tareasDelDia))
          else ...[
            // ── Calendario ────────────────────────────────────────────────
            Flexible(
              flex: 2,
              child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(day, _selectedDay),
              calendarFormat: _tableCalendarFormat,
              onDaySelected: (selected, focused) {
                setState(() => _focusedDay = focused);
                _cargarTareas(selected);
              },
              onPageChanged: (focused) =>
                  setState(() => _focusedDay = focused),
              onFormatChanged: _handleCalendarFormatChanged,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mes',
                CalendarFormat.week: 'Semana',
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Color(0xFF8DC49A),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF5A9267),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                markerDecoration: BoxDecoration(
                  color: Color(0xFFFF8F00),
                  shape: BoxShape.circle,
                ),
                markerSize: 5.0,
                markersMaxCount: 3,
                weekendTextStyle: TextStyle(color: Color(0xFFFF8F00)),
                outsideDaysVisible: false,
                defaultTextStyle:
                    TextStyle(color: Color(0xFF3A4A3E)),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7D9882),
                ),
                weekendStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF8F00),
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3A4A3E),
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Color(0xFF7D9882),
                  size: 22,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Color(0xFF7D9882),
                  size: 22,
                ),
                headerPadding:
                    EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            ),

            const Divider(height: 1, color: Color(0xFFD6E8D8)),

            // ── Lista de tareas del día ────────────────────────────────
            Expanded(child: _buildTaskList(_tareasDelDia)),
          ],
        ],
      ),
    );
  }

  void _handleCalendarFormatChanged(CalendarFormat format) {
    final nextView = switch (format) {
      CalendarFormat.week => CalendarView.semana,
      _ => CalendarView.mes,
    };
    if (_currentView == nextView) return;
    setState(() => _currentView = nextView);
  }

  Widget _buildViewSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<CalendarView>(
          selected: {_currentView},
          showSelectedIcon: false,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF8DC49A);
              }
              return const Color(0xFFEAF4EB);
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return const Color(0xFF5A9267);
            }),
            side: WidgetStateProperty.resolveWith((states) {
              final color = states.contains(WidgetState.selected)
                  ? const Color(0xFF8DC49A)
                  : const Color(0xFFD6E8D8);
              return BorderSide(color: color, width: 1.2);
            }),
          ),
          segments: const [
            ButtonSegment(
              value: CalendarView.mes,
              icon: Icon(Icons.calendar_month_outlined, size: 18),
              label: Text('Mes'),
            ),
            ButtonSegment(
              value: CalendarView.semana,
              icon: Icon(Icons.view_week_outlined, size: 18),
              label: Text('Semana'),
            ),
            ButtonSegment(
              value: CalendarView.dia,
              icon: Icon(Icons.schedule_outlined, size: 18),
              label: Text('Día'),
            ),
          ],
          onSelectionChanged: (selection) {
            setState(() => _currentView = selection.first);
          },
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Tarea> tasks) {
    if (tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌿', style: TextStyle(fontSize: 36)),
            SizedBox(height: 12),
            Text(
              'Sin tareas para este día',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A4A3E),
              ),
            ),
            Text(
              'Selecciona otro día o crea una tarea',
              style:
                  TextStyle(color: Color(0xFF7D9882), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final tarea = tasks[index];
        return _CalTaskTile(
          tarea: tarea,
          completada: tarea.completada,
          onComplete: () => _completarTarea(tarea),
        );
      },
    );
  }

  Widget _buildDailyTimeline(List<Tarea> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 16, 24),
      itemCount: 24,
      itemBuilder: (context, hour) {
        final tasksForHour =
            tasks.where((t) => hour >= 8 && hour < 20).toList();
        return SizedBox(
          height: 60,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 58,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: const TextStyle(
                      color: Color(0xFF7D9882),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(
                        height: 1, color: Color(0xFFD6E8D8)),
                    if (tasksForHour.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: tasksForHour.length,
                          itemBuilder: (context, i) {
                            final t = tasksForHour[i];
                            return Container(
                              margin: const EdgeInsets.only(
                                  right: 8, top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8DC49A),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: Text(
                                t.nombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Tile de tarea ─────────────────────────────────────────────────────────────

class _CalTaskTile extends StatelessWidget {
  const _CalTaskTile({
    required this.tarea,
    required this.completada,
    this.onComplete,
  });

  final Tarea tarea;
  final bool completada;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color:
            completada ? const Color(0xFFEAF4EB) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completada
              ? const Color(0xFF8DC49A)
              : const Color(0xFFE8E8E8),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Checkbox circular
          GestureDetector(
            onTap: onComplete,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completada
                    ? const Color(0xFF8DC49A)
                    : Colors.transparent,
                border: Border.all(
                  color: completada
                      ? const Color(0xFF8DC49A)
                      : const Color(0xFFD6E8D8),
                  width: 2,
                ),
              ),
              child: completada
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Nombre y materia
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: completada
                        ? const Color(0xFF7D9882)
                        : const Color(0xFF3A4A3E),
                    decoration: completada
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: const Color(0xFF7D9882),
                  ),
                  child: Text(tarea.nombre),
                ),
                const SizedBox(height: 3),
                Text(
                  tarea.materia,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7D9882),
                  ),
                ),
              ],
            ),
          ),

          // Duración
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${tarea.tiempoSesion} min',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A9267),
              ),
            ),
          ),
        ],
      ),
    );
  }
}