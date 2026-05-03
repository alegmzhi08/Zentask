// lib/screens/calendario.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/tarea.dart';
import '../services/task_service.dart';

enum CalendarView { mes, semana, dia }

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  late final ValueNotifier<DateTime> _selectedDay;
  DateTime _focusedDay = DateTime.now();
  CalendarView _currentView = CalendarView.mes;

  CalendarFormat get _tableCalendarFormat => switch (_currentView) {
    CalendarView.semana => CalendarFormat.week,
    _ => CalendarFormat.month,
  };

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDay = ValueNotifier(DateTime(today.year, today.month, today.day));
    TaskService.instance.init();
  }

  @override
  void dispose() {
    _selectedDay.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
      ),
      body: Column(
        children: [
          _buildViewSelector(),
          if (_currentView == CalendarView.dia)
            Expanded(
              child: ValueListenableBuilder<DateTime>(
                valueListenable: _selectedDay,
                builder: (context, selected, _) {
                  return ValueListenableBuilder<List<Tarea>>(
                    valueListenable: TaskService.instance.tareas,
                    builder: (context, tareas, _) {
                      final tasks = TaskService.instance.getTasksForDate(
                        selected,
                      );
                      return _buildDailyTimeline(tasks, selected);
                    },
                  );
                },
              ),
            )
          else ...[
            // ── Calendario ─────────────────────────────────────────────────
            // Outer builder: se reconstruye cuando la lista de tareas cambia
            // (actualiza puntos de eventos en el grid).
            ValueListenableBuilder<List<Tarea>>(
              valueListenable: TaskService.instance.tareas,
              builder: (context, tareas, child) {
                // Inner builder: se reconstruye cuando cambia el día seleccionado
                // (actualiza el resaltado sin depender de setState).
                return ValueListenableBuilder<DateTime>(
                  valueListenable: _selectedDay,
                  builder: (context, selected, _) {
                    return _CalendarioWidget(
                      selectedDay: selected,
                      focusedDay: _focusedDay,
                      calendarFormat: _tableCalendarFormat,
                      onDaySelected: (sel, foc) {
                        _selectedDay.value = DateTime(
                          sel.year,
                          sel.month,
                          sel.day,
                        );
                        setState(() => _focusedDay = foc);
                      },
                      onPageChanged: (foc) => setState(() => _focusedDay = foc),
                      onFormatChanged: _handleCalendarFormatChanged,
                    );
                  },
                );
              },
            ),

            const Divider(height: 1, color: Color(0xFFD6E8D8)),

            // ── Lista de tareas del día seleccionado ───────────────────────
            Expanded(
              child: ValueListenableBuilder<DateTime>(
                valueListenable: _selectedDay,
                builder: (context, selected, _) {
                  return ValueListenableBuilder<List<Tarea>>(
                    valueListenable: TaskService.instance.tareas,
                    builder: (context, tareas, _) {
                      final tasks = TaskService.instance.getTasksForDate(
                        selected,
                      );
                      return _buildTaskList(tasks, selected);
                    },
                  );
                },
              ),
            ),
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

  Widget _buildDailyTimeline(List<Tarea> tasks, DateTime day) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 16, 24),
      itemCount: 24,
      itemBuilder: (context, hour) {
        final tasksForHour = tasks
            .where((tarea) => _belongsToTimelineHour(tarea, day, hour))
            .toList();

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
                    const Divider(height: 1, color: Color(0xFFD6E8D8)),
                    if (tasksForHour.isNotEmpty)
                      Expanded(
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: tasksForHour.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final tarea = tasksForHour[index];
                            return _TimelineTaskChip(
                              tarea: tarea,
                              completada: tarea.isCompletedOn(day),
                            );
                          },
                        ),
                      )
                    else
                      const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _belongsToTimelineHour(Tarea tarea, DateTime day, int hour) {
    final scheduled = tarea.scheduledDate;
    final hasSpecificHour =
        scheduled != null &&
        isSameDay(scheduled, day) &&
        (scheduled.hour != 0 || scheduled.minute != 0);

    if (hasSpecificHour) return scheduled.hour == hour;
    return hour == 0;
  }

  // ── Lista de tareas ───────────────────────────────────────────────────────

  Widget _buildTaskList(List<Tarea> tasks, DateTime day) {
    if (tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Color(0xFF8DC49A),
              size: 40,
            ),
            SizedBox(height: 10),
            Text(
              'Sin tareas para este día',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7D9882),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: tasks.length,
      itemBuilder: (context, i) {
        final tarea = tasks[i];
        final completada = tarea.isCompletedOn(day);
        return _CalTaskTile(
          tarea: tarea,
          completada: completada,
          // Completar en la vista de calendario agrega la fecha a completedDates
          // sin romper la recurrencia de días futuros.
          onComplete: completada
              ? null
              : () => TaskService.instance.completarEnFecha(tarea.id, day),
        );
      },
    );
  }
}

class _TimelineTaskChip extends StatelessWidget {
  const _TimelineTaskChip({required this.tarea, required this.completada});

  final Tarea tarea;
  final bool completada;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: completada ? const Color(0xFFEAF4EB) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: completada ? const Color(0xFF8DC49A) : const Color(0xFFD6E8D8),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completada ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 14,
            color: completada
                ? const Color(0xFF8DC49A)
                : const Color(0xFF7D9882),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              tarea.nombre,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: completada
                    ? const Color(0xFF7D9882)
                    : const Color(0xFF3A4A3E),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                decoration: completada
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget del TableCalendar ──────────────────────────────────────────────────

class _CalendarioWidget extends StatelessWidget {
  const _CalendarioWidget({
    required this.selectedDay,
    required this.focusedDay,
    required this.calendarFormat,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onFormatChanged,
  });

  final DateTime selectedDay;
  final DateTime focusedDay;
  final CalendarFormat calendarFormat;
  final void Function(DateTime selected, DateTime focused) onDaySelected;
  final ValueChanged<DateTime> onPageChanged;
  final ValueChanged<CalendarFormat> onFormatChanged;

  @override
  Widget build(BuildContext context) {
    return TableCalendar<Tarea>(
      firstDay: DateTime(2020),
      lastDay: DateTime(2100),
      focusedDay: focusedDay,
      selectedDayPredicate: (day) => isSameDay(day, selectedDay),
      calendarFormat: calendarFormat,
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableGestures: AvailableGestures.all,
      eventLoader: TaskService.instance.getTasksForDate,
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      onFormatChanged: onFormatChanged,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Mes',
        CalendarFormat.week: 'Semana',
      },
      calendarStyle: const CalendarStyle(
        // Hoy
        todayDecoration: BoxDecoration(
          color: Color(0xFF8DC49A),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        // Día seleccionado
        selectedDecoration: BoxDecoration(
          color: Color(0xFF5A9267),
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        // Puntos de eventos
        markerDecoration: BoxDecoration(
          color: Color(0xFFFF8F00),
          shape: BoxShape.circle,
        ),
        markerSize: 5.0,
        markersMaxCount: 3,
        markerMargin: EdgeInsets.symmetric(horizontal: 1),
        // Fin de semana en naranja suave
        weekendTextStyle: TextStyle(color: Color(0xFFFF8F00)),
        // Días fuera del mes ocultos
        outsideDaysVisible: false,
        // Días normales
        defaultTextStyle: TextStyle(color: Color(0xFF3A4A3E)),
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
        headerPadding: EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}

// ── Tile de tarea en la vista calendario ──────────────────────────────────────

class _CalTaskTile extends StatelessWidget {
  const _CalTaskTile({
    required this.tarea,
    required this.completada,
    this.onComplete,
  });

  final Tarea tarea;
  final bool completada;
  final VoidCallback? onComplete;

  String? get _hora {
    final dt = tarea.scheduledDate;
    if (dt == null || (dt.hour == 0 && dt.minute == 0)) return null;
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: completada ? const Color(0xFFEAF4EB) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completada ? const Color(0xFF8DC49A) : const Color(0xFFE8E8E8),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Checkbox circular animado
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
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Nombre, materia y badge de recurrencia
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
                Row(
                  children: [
                    Text(
                      tarea.materia,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7D9882),
                      ),
                    ),
                    if (tarea.recurrence != 'none') ...[
                      const SizedBox(width: 6),
                      _RecurrenceBadge(recurrence: tarea.recurrence),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Hora (si fue asignada y no es medianoche)
          if (_hora != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _hora!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5A9267),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Badge de recurrencia ─────────────────────────────────────────────────────

class _RecurrenceBadge extends StatelessWidget {
  const _RecurrenceBadge({required this.recurrence});
  final String recurrence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD6E8D8)),
      ),
      child: Text(
        recurrence == 'daily' ? '🔁 Diario' : '📅 Semanal',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF7D9882),
        ),
      ),
    );
  }
}
