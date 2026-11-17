import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/vaccine_provider.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/pet_avatar.dart';
import '../../widgets/section_header.dart';
import '../agenda/appointment_detail_screen.dart';
import '../agenda/appointment_form_screen.dart';
import '../health/medication_detail_screen.dart';
import '../pets/pet_detail_screen.dart';
import '../pets/pet_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onNavigateToTab,
  });

  final ValueChanged<int> onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final apptProvider = context.watch<AppointmentProvider>();
    final medProvider = context.watch<MedicationProvider>();
    final vaccineProvider = context.watch<VaccineProvider>();

    final pets = petProvider.pets;
    final upcomingAppts = apptProvider.upcomingAppointments.take(4).toList();
    final activeMeds = medProvider.activeMedications.take(4).toList();
    final upcomingVaccines = vaccineProvider.upcomingDoses.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.pets_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('PetCare'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Pets Summary
          SectionHeader(
            title: 'Seus Pets (${pets.length})',
            actionLabel: pets.isEmpty ? null : 'Ver todos',
            onAction: pets.isEmpty ? null : () => onNavigateToTab(1),
          ),
          const SizedBox(height: 10),
          if (pets.isEmpty)
            EmptyStateCard(
              icon: Icons.pets_rounded,
              title: 'Bem-vindo ao PetCare!',
              subtitle:
                  'Cadastre seu primeiro cão ou gato para acompanhar vacinas, medicamentos, consultas e peso.',
              actionLabel: 'Cadastrar Pet',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PetFormScreen(),
                  ),
                );
              },
            )
          else
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pets.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index == pets.length) {
                    return SizedBox(
                      width: 146,
                      child: Card(
                        color: AppColors.surfaceCream,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const PetFormScreen(),
                              ),
                            );
                          },
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primaryLight,
                                child: Icon(
                                  Icons.add,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Novo Pet',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final pet = pets[index];
                  return SizedBox(
                    width: 146,
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          if (pet.id == null) return;
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PetDetailScreen(
                                petId: pet.id!,
                                onNavigateToTab: onNavigateToTab,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PetAvatar(pet: pet, radius: 24),
                              const SizedBox(height: 8),
                              Text(
                                pet.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pet.currentWeight != null
                                    ? '${pet.species.label} • ${pet.currentWeight!.toStringAsFixed(1)} kg'
                                    : pet.species.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 22),

          // Upcoming Appointments
          SectionHeader(
            title: 'Próximos Compromissos',
            actionLabel: 'Agenda',
            onAction: () => onNavigateToTab(2),
          ),
          const SizedBox(height: 10),
          if (upcomingAppts.isEmpty)
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(
                    Icons.event_available_outlined,
                    color: AppColors.primaryDark,
                  ),
                ),
                title: const Text('Sem compromissos próximos'),
                subtitle: const Text(
                  'Toque para agendar consulta, vacina ou banho.',
                ),
                trailing: const Icon(Icons.add),
                onTap: pets.isEmpty
                    ? () => onNavigateToTab(1)
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AppointmentFormScreen(),
                          ),
                        );
                      },
              ),
            )
          else
            ...upcomingAppts.map((appt) {
              final pet = petProvider.getById(appt.petId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    title: Text(
                      appt.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${pet?.name ?? 'Pet'} • ${DateFormatter.formatDateTime(appt.dateTime)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (appt.id == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AppointmentDetailScreen(
                            appointmentId: appt.id!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),

          const SizedBox(height: 22),

          // Medication & Vaccine Reminders
          SectionHeader(
            title: 'Lembretes de Saúde',
            actionLabel: 'Saúde',
            onAction: () => onNavigateToTab(3),
          ),
          const SizedBox(height: 10),
          if (activeMeds.isEmpty && upcomingVaccines.isEmpty)
            const Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.surfaceCream,
                  child: Icon(
                    Icons.notifications_none,
                    color: AppColors.textMuted,
                  ),
                ),
                title: Text('Nenhum lembrete ativo'),
                subtitle: Text(
                  'Medicamentos ativos e próximas doses de vacina aparecerão aqui.',
                ),
              ),
            )
          else ...[
            ...activeMeds.map((med) {
              final pet = petProvider.getById(med.petId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.alertLight,
                      child: Icon(
                        Icons.medication_outlined,
                        color: AppColors.alert,
                      ),
                    ),
                    title: Text(
                      '${med.name} (${pet?.name ?? 'Pet'})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Horários: ${med.schedules.join(", ")}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (med.id == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MedicationDetailScreen(
                            medicationId: med.id!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
            ...upcomingVaccines.map((vac) {
              final pet = petProvider.getById(vac.petId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(
                        Icons.vaccines_outlined,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    title: Text(
                      'Próxima dose: ${vac.name}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${pet?.name ?? 'Pet'} • ${DateFormatter.formatDate(vac.nextDoseAt!)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onNavigateToTab(3),
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aviso: o PetCare é uma ferramenta de organização e não realiza diagnósticos, não prescreve medicamentos e não substitui a orientação de um médico-veterinário.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

