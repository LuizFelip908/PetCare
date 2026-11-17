import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/health_event.dart';
import '../../data/repositories/health_history_repository.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/medication_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/vaccine_provider.dart';
import '../../providers/weight_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/pet_selector_bar.dart';
import '../../widgets/weight_chart.dart';
import 'medication_detail_screen.dart';
import 'medication_form_screen.dart';
import 'vaccine_form_screen.dart';
import 'weight_form_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final HealthHistoryRepository _historyRepo = HealthHistoryRepository();
  int? _weightLoadedForPetId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedId = context.read<PetProvider>().selectedPetId;
      if (selectedId != null) {
        context.read<WeightProvider>().loadForPet(selectedId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onFabPressed(int petId) {
    switch (_tabController.index) {
      case 0:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => VaccineFormScreen(initialPetId: petId),
          ),
        );
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MedicationFormScreen(initialPetId: petId),
          ),
        );
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WeightFormScreen(initialPetId: petId),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final pets = petProvider.pets;
    final selectedPet = petProvider.selectedPet;

    // Garante que os pesos do pet selecionado sejam carregados mesmo quando
    // o pet muda fora desta tela (ex.: cadastro ou tela de detalhes).
    final selectedId = selectedPet?.id;
    if (selectedId != null && selectedId != _weightLoadedForPetId) {
      _weightLoadedForPetId = selectedId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<WeightProvider>().loadForPet(selectedId);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saúde'),
        bottom: pets.isEmpty
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primaryDark,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Vacinas'),
                  Tab(text: 'Medicamentos'),
                  Tab(text: 'Histórico'),
                  Tab(text: 'Peso'),
                ],
              ),
      ),
      body: pets.isEmpty || selectedPet == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: EmptyStateCard(
                  icon: Icons.favorite_outline,
                  title: 'Cadastre um pet primeiro',
                  subtitle:
                      'Para controlar vacinas, medicamentos, histórico e peso, cadastre um animal em Meus Pets.',
                ),
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 10),
                PetSelectorBar(
                  pets: pets,
                  selectedPetId: selectedPet.id,
                  onSelected: (id) {
                    petProvider.selectPet(id);
                    context.read<WeightProvider>().loadForPet(id);
                  },
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _VaccinesTab(petId: selectedPet.id!),
                      _MedicationsTab(petId: selectedPet.id!),
                      _HistoryTab(
                        petId: selectedPet.id!,
                        historyRepo: _historyRepo,
                      ),
                      _WeightTab(petId: selectedPet.id!),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: (pets.isEmpty ||
              selectedPet == null ||
              _tabController.index == 2)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _onFabPressed(selectedPet.id!),
              icon: const Icon(Icons.add),
              label: Text(
                _tabController.index == 0
                    ? 'Vacina'
                    : _tabController.index == 1
                        ? 'Medicamento'
                        : 'Registrar Peso',
              ),
            ),
    );
  }
}

class _VaccinesTab extends StatelessWidget {
  const _VaccinesTab({required this.petId});

  final int petId;

  @override
  Widget build(BuildContext context) {
    final vaccines = context.watch<VaccineProvider>().forPet(petId);

    if (vaccines.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EmptyStateCard(
            icon: Icons.vaccines_outlined,
            title: 'Nenhuma vacina registrada',
            subtitle:
                'Mantenha a carteira de vacinação atualizada com datas e próximas doses.',
            actionLabel: 'Registrar Vacina',
            onAction: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => VaccineFormScreen(initialPetId: petId),
                ),
              );
            },
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: vaccines.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final v = vaccines[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: const CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.vaccines_outlined, color: AppColors.primaryDark),
            ),
            title: Text(
              v.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Aplicada em ${DateFormatter.formatDate(v.appliedAt)}'),
                if (v.nextDoseAt != null)
                  Text(
                    'Próxima dose: ${DateFormatter.formatDate(v.nextDoseAt!)}',
                    style: const TextStyle(
                      color: AppColors.alert,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (v.clinic.isNotEmpty) Text('Clínica: ${v.clinic}'),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => VaccineFormScreen(vaccine: v),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MedicationsTab extends StatelessWidget {
  const _MedicationsTab({required this.petId});

  final int petId;

  @override
  Widget build(BuildContext context) {
    final meds = context.watch<MedicationProvider>().forPet(petId);

    if (meds.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EmptyStateCard(
            icon: Icons.medication_outlined,
            title: 'Nenhum medicamento cadastrado',
            subtitle:
                'Cadastre medicamentos prescritos pelo veterinário, horários e lembretes.',
            actionLabel: 'Adicionar Medicamento',
            onAction: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MedicationFormScreen(initialPetId: petId),
                ),
              );
            },
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: meds.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final m = meds[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: m.isCurrentlyActive
                  ? AppColors.primaryLight
                  : AppColors.surfaceCream,
              child: Icon(
                Icons.medication_outlined,
                color: m.isCurrentlyActive
                    ? AppColors.primaryDark
                    : AppColors.textMuted,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    m.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Chip(
                  label: Text(
                    m.isCurrentlyActive ? 'Ativo' : 'Finalizado',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: m.isCurrentlyActive
                      ? AppColors.primaryLight
                      : AppColors.surfaceCream,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [
                  if (m.dosage.isNotEmpty) m.dosage,
                  'Horários: ${m.schedules.join(", ")}',
                ].join(' • '),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (m.id == null) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MedicationDetailScreen(medicationId: m.id!),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    required this.petId,
    required this.historyRepo,
  });

  final int petId;
  final HealthHistoryRepository historyRepo;

  @override
  Widget build(BuildContext context) {
    // Watch providers so timeline refreshes automatically when records change
    context.watch<VaccineProvider>();
    context.watch<MedicationProvider>();
    context.watch<AppointmentProvider>();

    return FutureBuilder<List<HealthEvent>>(
      future: historyRepo.getHistoryForPet(petId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final events = snapshot.data ?? const [];
        if (events.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              EmptyStateCard(
                icon: Icons.history_rounded,
                title: 'Histórico de saúde vazio',
                subtitle:
                    'Vacinas, medicamentos, consultas e exames deste pet aparecerão aqui em ordem cronológica.',
              ),
            ],
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: events.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final ev = events[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(
                    _iconForCategory(ev.category),
                    color: AppColors.primaryDark,
                  ),
                ),
                title: Text(
                  ev.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormatter.formatDate(ev.date)} • ${ev.subtitle}',
                    ),
                    if (ev.notes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        ev.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _iconForCategory(HealthEventCategory cat) {
    switch (cat) {
      case HealthEventCategory.vaccine:
        return Icons.vaccines_outlined;
      case HealthEventCategory.medication:
        return Icons.medication_outlined;
      case HealthEventCategory.consultation:
        return Icons.medical_services_outlined;
      case HealthEventCategory.exam:
        return Icons.biotech_outlined;
    }
  }
}

class _WeightTab extends StatelessWidget {
  const _WeightTab({required this.petId});

  final int petId;

  @override
  Widget build(BuildContext context) {
    final weightProvider = context.watch<WeightProvider>();
    final records = weightProvider.forPet(petId);
    final reversed = [...records].reversed.toList();

    if (records.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EmptyStateCard(
            icon: Icons.monitor_weight_outlined,
            title: 'Nenhuma pesagem registrada',
            subtitle:
                'Acompanhe a evolução do peso do seu pet ao longo do tempo.',
            actionLabel: 'Registrar Peso',
            onAction: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WeightFormScreen(initialPetId: petId),
                ),
              );
            },
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      children: [
        WeightChart(records: records),
        const SizedBox(height: 16),
        Text(
          'Registros Anteriores',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        ...reversed.map(
          (rec) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(
                    Icons.monitor_weight_outlined,
                    color: AppColors.primaryDark,
                  ),
                ),
                title: Text(
                  '${rec.weightKg.toStringAsFixed(2)} kg',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  [
                    DateFormatter.formatDate(rec.recordedAt),
                    if (rec.notes.isNotEmpty) rec.notes,
                  ].join(' • '),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () async {
                    final confirmed = await showConfirmationDialog(
                      context,
                      title: 'Excluir registro de peso',
                      message:
                          'Deseja excluir a pesagem de ${rec.weightKg.toStringAsFixed(2)} kg?',
                    );
                    if (!confirmed || !context.mounted || rec.id == null) {
                      return;
                    }
                    await weightProvider.deleteRecord(rec.id!, petId);
                    if (context.mounted) {
                      await context.read<PetProvider>().loadPets();
                    }
                  },
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => WeightFormScreen(record: rec),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

