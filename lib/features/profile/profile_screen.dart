import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/demo_data_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vaccine_provider.dart';
import '../../providers/weight_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import 'privacy_policy_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _rescheduleAll(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    if (!settings.notificationsEnabled) return;

    final petProvider = context.read<PetProvider>();
    final apptProvider = context.read<AppointmentProvider>();
    final medProvider = context.read<MedicationProvider>();
    final vaccineProvider = context.read<VaccineProvider>();

    for (final a in apptProvider.appointments) {
      final pet = petProvider.getById(a.petId);
      await NotificationService.instance.scheduleAppointmentReminder(
        appointment: a,
        petName: pet?.name ?? 'Pet',
        globalEnabled: true,
        leadMinutes: settings.appointmentLeadMinutes,
      );
    }
    for (final m in medProvider.medications) {
      final pet = petProvider.getById(m.petId);
      await NotificationService.instance.scheduleMedicationReminders(
        medication: m,
        petName: pet?.name ?? 'Pet',
        globalEnabled: true,
      );
    }
    for (final v in vaccineProvider.vaccines) {
      final pet = petProvider.getById(v.petId);
      await NotificationService.instance.scheduleVaccineReminder(
        vaccine: v,
        petName: pet?.name ?? 'Pet',
        globalEnabled: true,
      );
    }
  }

  Future<void> _reloadAll(BuildContext context) async {
    final petProvider = context.read<PetProvider>();
    await petProvider.loadPets();
    if (!context.mounted) return;
    await Future.wait([
      context.read<VaccineProvider>().loadAll(),
      context.read<MedicationProvider>().loadAll(),
      context.read<AppointmentProvider>().loadAll(),
    ]);
    if (!context.mounted) return;
    final selectedId = petProvider.selectedPetId;
    if (selectedId != null) {
      await context.read<WeightProvider>().loadForPet(selectedId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final petProvider = context.watch<PetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil e Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            'Notificações',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Lembretes locais'),
                  subtitle: const Text(
                    'Alertas de medicamentos, consultas e vacinas',
                  ),
                  activeThumbColor: AppColors.primary,
                  value: settings.notificationsEnabled,
                  onChanged: (val) async {
                    final ok = await settings.setNotificationsEnabled(val);
                    if (!context.mounted) return;
                    if (!ok && val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Permissão de notificação negada pelo sistema. Ative nas configurações do aparelho.',
                          ),
                        ),
                      );
                    } else if (val) {
                      await _rescheduleAll(context);
                    }
                  },
                ),
                if (!settings.hasSystemPermission)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: AppColors.alertLight,
                    child: const Text(
                      'A permissão de notificações está desativada no sistema operacional.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.alert,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Divider(),
                ListTile(
                  title: const Text('Antecedência para consultas'),
                  subtitle: Text(
                    _leadTimeLabel(settings.appointmentLeadMinutes),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final selected = await showDialog<int>(
                      context: context,
                      builder: (ctx) => SimpleDialog(
                        title: const Text('Antecedência do lembrete'),
                        children: [15, 30, 60, 120, 1440]
                            .map(
                              (mins) => SimpleDialogOption(
                                onPressed: () => Navigator.pop(ctx, mins),
                                child: Text(_leadTimeLabel(mins)),
                              ),
                            )
                            .toList(),
                      ),
                    );
                    if (selected != null && context.mounted) {
                      await settings.setAppointmentLeadMinutes(selected);
                      if (context.mounted) await _rescheduleAll(context);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          Text(
            'Dados de Demonstração',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(
                      Icons.science_outlined,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  title: const Text('Carregar dados de exemplo'),
                  subtitle: const Text(
                    'Adiciona 2 pets fictícios marcados como exemplo para testar o app',
                  ),
                  onTap: () async {
                    await DemoDataService().insertDemoData();
                    if (!context.mounted) return;
                    await _reloadAll(context);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dados de exemplo carregados.'),
                        ),
                      );
                    }
                  },
                ),
                if (petProvider.hasDemo) ...[
                  const Divider(),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.dangerLight,
                      child: Icon(
                        Icons.delete_sweep_outlined,
                        color: AppColors.danger,
                      ),
                    ),
                    title: const Text(
                      'Remover dados de exemplo',
                      style: TextStyle(color: AppColors.danger),
                    ),
                    subtitle: const Text(
                      'Exclui apenas os registros marcados como exemplo',
                    ),
                    onTap: () async {
                      final confirmed = await showConfirmationDialog(
                        context,
                        title: 'Remover dados de exemplo',
                        message:
                            'Todos os pets e registros de exemplo serão removidos. Seus dados reais serão preservados.',
                        confirmLabel: 'Remover',
                      );
                      if (!confirmed || !context.mounted) return;
                      await DemoDataService().removeDemoData();
                      if (context.mounted) await _reloadAll(context);
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 22),
          Text(
            'Privacidade e Informações',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Política de Privacidade'),
                  subtitle: const Text('Armazenamento local e permissões'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('PetCare — Cuidados com animais de estimação'),
                  subtitle: Text('Versão 1.0.0 • Dados salvos localmente (SQLite)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _leadTimeLabel(int minutes) {
    if (minutes < 60) return '$minutes minutos antes';
    if (minutes == 60) return '1 hora antes';
    if (minutes == 120) return '2 horas antes';
    if (minutes == 1440) return '1 dia antes';
    return '$minutes minutos antes';
  }
}

