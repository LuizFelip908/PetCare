import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/medication.dart';
import '../../providers/medication_provider.dart';
import '../../providers/pet_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import 'medication_form_screen.dart';

class MedicationDetailScreen extends StatelessWidget {
  const MedicationDetailScreen({super.key, required this.medicationId});

  final int medicationId;

  @override
  Widget build(BuildContext context) {
    final medProvider = context.watch<MedicationProvider>();
    Medication? med;
    for (final m in medProvider.medications) {
      if (m.id == medicationId) {
        med = m;
        break;
      }
    }

    if (med == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medicamento')),
        body: const Center(child: Text('Medicamento não encontrado.')),
      );
    }

    final currentMed = med;
    final pet = context.watch<PetProvider>().getById(currentMed.petId);
    final logs = medProvider.logsForMedication(medicationId);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentMed.name),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MedicationFormScreen(medication: currentMed),
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
                title: 'Excluir medicamento',
                message:
                    'Deseja excluir "${currentMed.name}" e seu histórico de administrações?',
              );
              if (!confirmed || !context.mounted) return;
              await medProvider.deleteMedication(currentMed.id!);
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
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          med.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Chip(
                        label: Text(
                          med.isCurrentlyActive ? 'Ativo' : 'Finalizado',
                        ),
                        backgroundColor: med.isCurrentlyActive
                            ? AppColors.primaryLight
                            : AppColors.surfaceCream,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pet: ${pet?.name ?? 'Pet'}'
                    '${med.dosage.isNotEmpty ? ' • Dose: ${med.dosage}' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Período: ${DateFormatter.formatDate(med.startDate)}'
                    '${med.endDate != null ? ' até ${DateFormatter.formatDate(med.endDate!)}' : ' (uso contínuo)'}',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: med.schedules
                        .map(
                          (s) => Chip(
                            avatar: const Icon(Icons.access_time, size: 16),
                            label: Text(s),
                          ),
                        )
                        .toList(),
                  ),
                  if (med.instructions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 10),
                    Text(
                      'Orientações',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(med.instructions),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              String selectedSchedule =
                  med!.schedules.isNotEmpty ? med.schedules.first : '';
              if (med.schedules.length > 1) {
                final chosen = await showModalBottomSheet<String>(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Qual horário foi administrado?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ...med!.schedules.map(
                          (s) => ListTile(
                            leading: const Icon(Icons.access_time),
                            title: Text('Horário das $s'),
                            onTap: () => Navigator.pop(ctx, s),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.check_circle_outline),
                          title: const Text('Dose avulsa / agora'),
                          onTap: () => Navigator.pop(ctx, 'Agora'),
                        ),
                      ],
                    ),
                  ),
                );
                if (chosen == null) return;
                selectedSchedule = chosen;
              }
              await medProvider.markAdministered(
                medication: currentMed,
                scheduledTime: selectedSchedule,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Administração registrada com sucesso.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Marcar administração realizada'),
          ),
          const SizedBox(height: 20),
          Text(
            'Histórico de Administrações (${logs.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (logs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhuma administração registrada ainda.'),
              ),
            )
          else
            ...logs.map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.check, color: AppColors.primaryDark),
                    ),
                    title: Text(
                      DateFormatter.formatDateTime(log.administeredAt),
                    ),
                    subtitle: log.scheduledTime.isNotEmpty
                        ? Text('Horário previsto: ${log.scheduledTime}')
                        : null,
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        if (log.id != null) {
                          medProvider.deleteLog(log.id!);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

