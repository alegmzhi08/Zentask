// lib/screens/ajustes_screen.dart
import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  bool _modoOscuro = false;
  bool _modoEstricto = false;
  bool _recordatorios = true;
  bool _notificacionesRacha = true;

  @override
  void initState() {
    super.initState();
    SettingsService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          // ── PERFIL ─────────────────────────────────────────────────────────
          _buildSectionHeader('Perfil'),
          ListTile(
            leading: const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFF8DC49A),
              child: Icon(Icons.person, color: Colors.white, size: 26),
            ),
            title: const Text(
              'Usuario Zentask',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('usuario@zentask.app'),
            trailing: const Icon(Icons.edit_outlined),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: () {},
          ),

          // ── APARIENCIA ─────────────────────────────────────────────────────
          _buildSectionHeader('Apariencia'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Modo Oscuro'),
            value: _modoOscuro,
            onChanged: (value) => setState(() => _modoOscuro = value),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Color de Énfasis'),
            subtitle: const Text('Verde Zentask'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8DC49A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {},
          ),

          // ── PRODUCTIVIDAD Y ENFOQUE ────────────────────────────────────────
          _buildSectionHeader('Productividad y Enfoque'),
          ListenableBuilder(
            listenable: Listenable.merge([
              SettingsService.instance.pomodoroDuration,
              SettingsService.instance.breakDuration,
            ]),
            builder: (context, _) {
              final work = SettingsService.instance.pomodoroDuration.value;
              final brk = SettingsService.instance.breakDuration.value;
              return ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Duración del Pomodoro'),
                subtitle: Text('$work min trabajo / $brk min descanso'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _abrirConfigPomodoro(context),
              );
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.shield_outlined),
            title: const Text('Modo Estricto'),
            subtitle: const Text('Bloquea distracciones durante sesiones'),
            value: _modoEstricto,
            onChanged: (value) => setState(() => _modoEstricto = value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Recordatorios de Tareas'),
            subtitle: const Text('Notificaciones antes de la fecha de entrega'),
            value: _recordatorios,
            onChanged: (value) => setState(() => _recordatorios = value),
          ),

          // ── GAMIFICACIÓN ───────────────────────────────────────────────────
          _buildSectionHeader('Gamificación'),
          SwitchListTile(
            secondary: const Icon(Icons.local_fire_department_outlined),
            title: const Text('Notificaciones de Racha'),
            subtitle: const Text('Recibe motivación para mantener tu racha diaria'),
            value: _notificacionesRacha,
            onChanged: (value) => setState(() => _notificacionesRacha = value),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Meta Diaria'),
            subtitle: const Text('Completar 3 tareas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          // ── CUENTA ─────────────────────────────────────────────────────────
          _buildSectionHeader('Cuenta'),
          ListTile(
            leading: Icon(Icons.workspace_premium_outlined, color: colorScheme.primary),
            title: Text(
              'Suscripción Premium',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            subtitle: const Text('Desbloquea todas las funciones de Zentask'),
            trailing: Icon(Icons.chevron_right, color: colorScheme.primary),
            onTap: () {},
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () => _confirmarAccionDestructiva(
              context,
              titulo: 'Cerrar sesión',
              mensaje: '¿Seguro que quieres cerrar sesión?',
              etiquetaBoton: 'Cerrar sesión',
              onConfirmar: () {},
            ),
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            title: const Text('Eliminar Cuenta', style: TextStyle(color: Colors.red)),
            subtitle: const Text(
              'Acción irreversible',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
            onTap: () => _confirmarAccionDestructiva(
              context,
              titulo: 'Eliminar cuenta',
              mensaje:
                  'Esta acción es permanente. Se eliminarán todos tus datos, tareas y gatos virtuales.',
              etiquetaBoton: 'Eliminar para siempre',
              onConfirmar: () {},
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _abrirConfigPomodoro(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PomodoroConfigSheet(),
    );
  }

  void _confirmarAccionDestructiva(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    required String etiquetaBoton,
    required VoidCallback onConfirmar,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirmar();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(etiquetaBoton),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Sheet de configuración Pomodoro ─────────────────────────────────────

class _PomodoroConfigSheet extends StatefulWidget {
  const _PomodoroConfigSheet();

  @override
  State<_PomodoroConfigSheet> createState() => _PomodoroConfigSheetState();
}

class _PomodoroConfigSheetState extends State<_PomodoroConfigSheet> {
  late int _trabajo;
  late int _descanso;

  @override
  void initState() {
    super.initState();
    _trabajo = SettingsService.instance.pomodoroDuration.value;
    _descanso = SettingsService.instance.breakDuration.value;
  }

  void _guardar() {
    SettingsService.instance.setPomodoroDuration(_trabajo);
    SettingsService.instance.setBreakDuration(_descanso);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Duración del Pomodoro',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 28),
          _DurationRow(
            label: 'Tiempo de trabajo',
            value: _trabajo,
            unit: 'min',
            canDecrement: _trabajo > SettingsService.minPomodoroDuration,
            canIncrement: _trabajo < SettingsService.maxPomodoroDuration,
            onDecrement: () => setState(() {
              _trabajo = (_trabajo - 5).clamp(
                SettingsService.minPomodoroDuration,
                SettingsService.maxPomodoroDuration,
              );
            }),
            onIncrement: () => setState(() {
              _trabajo = (_trabajo + 5).clamp(
                SettingsService.minPomodoroDuration,
                SettingsService.maxPomodoroDuration,
              );
            }),
          ),
          const SizedBox(height: 20),
          _DurationRow(
            label: 'Descanso corto',
            value: _descanso,
            unit: 'min',
            canDecrement: _descanso > SettingsService.minBreakDuration,
            canIncrement: _descanso < SettingsService.maxBreakDuration,
            onDecrement: () => setState(() {
              _descanso = (_descanso - 1).clamp(
                SettingsService.minBreakDuration,
                SettingsService.maxBreakDuration,
              );
            }),
            onIncrement: () => setState(() {
              _descanso = (_descanso + 1).clamp(
                SettingsService.minBreakDuration,
                SettingsService.maxBreakDuration,
              );
            }),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _guardar,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Guardar', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationRow extends StatelessWidget {
  const _DurationRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.onDecrement,
    required this.onIncrement,
    required this.canDecrement,
    required this.canIncrement,
  });

  final String label;
  final int value;
  final String unit;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool canDecrement;
  final bool canIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        IconButton(
          onPressed: canDecrement ? onDecrement : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: const Color(0xFF8DC49A),
        ),
        SizedBox(
          width: 64,
          child: Text(
            '$value $unit',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: canIncrement ? onIncrement : null,
          icon: const Icon(Icons.add_circle_outline),
          color: const Color(0xFF8DC49A),
        ),
      ],
    );
  }
}
