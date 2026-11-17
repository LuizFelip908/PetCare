import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/appointment.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import 'appointment_form_screen.dart';

class AppointmentDetailScreen extends StatelessWidget {
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  final int appointmentId;

  @override
  Widget build(BuildContext context) {
    final apptProvider = context.watch<AppointmentProvider>();
    Appointment? appt;
    for (final a in apptProvider.appointments) {
      if (a.id == appointmentId) {
        appt = a;
        break;
      }
    }

    if (appt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compromisso')),
        body: const Center(child: Text('Compromisso não encontrado.')),
      );
    }

    final currentAppt = appt;
    final pet = context.watch<PetProvider>().getById(currentAppt.petId);
    final settings = context.read<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Compromisso'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AppointmentFormScreen(appointment: currentAppt),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Excluir',
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () async {
              final confirmed = await showConfirmationDialog(
                context,
                title: 'Excluir compromisso',
                message: 'Deseja excluir "${currentAppt.title}" da agenda?',
              );
              if (!confirmed || !context.mounted) return;
              await apptProvider.deleteAppointment(currentAppt.id!);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(appt.type.label),
                        backgroundColor: AppColors.primaryLight,
                      ),
                      const Spacer(),
                      if (appt.completed)
                        const Chip(
                          label: Text('Concluído'),
                          backgroundColor: AppColors.surfaceCream,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    appt.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(
                    icon: Icons.pets_outlined,
                    label: 'Pet',
                    value: pet?.name ?? 'Pet removido',
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Data e hora',
                    value: DateFormatter.formatDateTime(appt.dateTime),
                  ),
                  if (appt.location.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Local',
                      value: appt.location,
                    ),
                  ],
                  if (appt.notes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 10),
                    Text(
                      'Observações',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(appt.notes),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              apptProvider.toggleCompleted(
                appt!,
                petName: pet?.name ?? 'Pet',
                notificationsEnabled: settings.notificationsEnabled,
                leadMinutes: settings.appointmentLeadMinutes,
              );
            },
            icon: Icon(
              appt.completed ? Icons.undo_rounded : Icons.check_circle_outline,
            ),
            label: Text(
              appt.completed
                  ? 'Reabrir compromisso'
                  : 'Marcar como concluído',
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryDark),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}

