import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/pet_provider.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/pet_avatar.dart';
import 'pet_detail_screen.dart';
import 'pet_form_screen.dart';

class PetsScreen extends StatelessWidget {
  const PetsScreen({
    super.key,
    this.onNavigateToTab,
  });

  final ValueChanged<int>? onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final pets = petProvider.pets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pets'),
      ),
      body: pets.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: EmptyStateCard(
                  icon: Icons.pets_rounded,
                  title: 'Nenhum animal cadastrado',
                  subtitle:
                      'Cadastre seu cão ou gato para organizar vacinas, medicamentos, consultas e peso.',
                  actionLabel: 'Cadastrar Pet',
                  onAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PetFormScreen(),
                      ),
                    );
                  },
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              itemCount: pets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final pet = pets[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: PetAvatar(pet: pet, radius: 28),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            pet.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (pet.isDemo)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.alertLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Exemplo',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.alert,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        [
                          pet.species.label,
                          if (pet.breed.isNotEmpty) pet.breed,
                          DateFormatter.formatAge(pet.birthDate),
                          if (pet.currentWeight != null)
                            '${pet.currentWeight!.toStringAsFixed(1)} kg',
                        ].join(' • '),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
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
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PetFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo Pet'),
      ),
    );
  }
}

