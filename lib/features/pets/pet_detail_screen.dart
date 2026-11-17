import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/pet.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/vaccine_provider.dart';
import '../../providers/weight_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/pet_avatar.dart';
import 'pet_form_screen.dart';

class PetDetailScreen extends StatelessWidget {
  const PetDetailScreen({
    super.key,
    required this.petId,
    this.onNavigateToTab,
  });

  final int petId;
  final ValueChanged<int>? onNavigateToTab;

  Future<void> _deletePet(BuildContext context, Pet pet) async {
    final petProvider = context.read<PetProvider>();
    final relatedCount = await petProvider.countRelatedRecords(petId);

    if (!context.mounted) return;
    final warning = relatedCount > 0
        ? 'Este pet possui $relatedCount registro(s) vinculado(s) '
            '(vacinas, medicamentos, agenda ou peso). '
            'Todos os dados relacionados também serão excluídos permanentemente.'
        : 'Tem certeza que deseja excluir o perfil de ${pet.name}?';

    final confirmed = await showConfirmationDialog(
      context,
      title: 'Excluir ${pet.name}',
      message: warning,
    );
    if (!confirmed || !context.mounted) return;

    // Capture providers before async gaps
    final vaccineProvider = context.read<VaccineProvider>();
    final medProvider = context.read<MedicationProvider>();
    final apptProvider = context.read<AppointmentProvider>();

    // Cancel notifications for all records belonging to this pet
    for (final v in vaccineProvider.forPet(petId)) {
      if (v.id != null) {
        await NotificationService.instance.cancelVaccineReminder(v.id!);
      }
    }
    for (final m in medProvider.forPet(petId)) {
      if (m.id != null) {
        await NotificationService.instance.cancelMedicationReminders(m.id!);
      }
    }
    for (final a in apptProvider.forPet(petId)) {
      if (a.id != null) {
        await NotificationService.instance.cancelAppointmentReminder(a.id!);
      }
    }

    await petProvider.deletePet(petId);
    await Future.wait([
      vaccineProvider.loadAll(),
      medProvider.loadAll(),
      apptProvider.loadAll(),
    ]);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final pet = petProvider.getById(petId);

    if (pet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil do Pet')),
        body: const Center(child: Text('Pet não encontrado.')),
      );
    }

    final vaccines = context.watch<VaccineProvider>().forPet(petId);
    final meds = context.watch<MedicationProvider>().forPet(petId);
    final appts = context.watch<AppointmentProvider>().forPet(petId);

    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
        actions: [
          IconButton(
            tooltip: 'Editar pet',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PetFormScreen(pet: pet),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Excluir pet',
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _deletePet(context, pet),
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
                children: [
                  PetAvatar(pet: pet, radius: 44),
                  const SizedBox(height: 12),
                  Text(
                    pet.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.species.label} • ${pet.breed.isNotEmpty ? pet.breed : 'Raça não informada'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (pet.isDemo) ...[
                    const SizedBox(height: 8),
                    const Chip(
                      label: Text('Registro de exemplo'),
                      backgroundColor: AppColors.alertLight,
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoMetric(
                        label: 'Sexo',
                        value: pet.sex.label,
                      ),
                      _InfoMetric(
                        label: 'Idade',
                        value: DateFormatter.formatAge(pet.birthDate),
                      ),
                      _InfoMetric(
                        label: 'Peso',
                        value: pet.currentWeight != null
                            ? '${pet.currentWeight!.toStringAsFixed(1)} kg'
                            : '—',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (pet.notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Observações',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(pet.notes),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Resumo de Cuidados',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          _QuickTile(
            icon: Icons.vaccines_outlined,
            title: 'Vacinas registradas',
            count: vaccines.length,
            onTap: () {
              petProvider.selectPet(petId);
              context.read<WeightProvider>().loadForPet(petId);
              Navigator.of(context).pop();
              onNavigateToTab?.call(3);
            },
          ),
          const SizedBox(height: 8),
          _QuickTile(
            icon: Icons.medication_outlined,
            title: 'Medicamentos',
            count: meds.length,
            onTap: () {
              petProvider.selectPet(petId);
              Navigator.of(context).pop();
              onNavigateToTab?.call(3);
            },
          ),
          const SizedBox(height: 8),
          _QuickTile(
            icon: Icons.calendar_month_outlined,
            title: 'Compromissos na agenda',
            count: appts.length,
            onTap: () {
              petProvider.selectPet(petId);
              Navigator.of(context).pop();
              onNavigateToTab?.call(2);
            },
          ),
        ],
      ),
    );
  }
}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(icon, color: AppColors.primaryDark),
        ),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                  ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

