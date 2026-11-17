import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/models/pet.dart';
import 'pet_avatar.dart';

class PetSelectorBar extends StatelessWidget {
  const PetSelectorBar({
    super.key,
    required this.pets,
    required this.selectedPetId,
    required this.onSelected,
  });

  final List<Pet> pets;
  final int? selectedPetId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final pet = pets[index];
          final isSelected = pet.id == selectedPetId;
          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,
            avatar: PetAvatar(pet: pet, radius: 12),
            label: Text(pet.name),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primaryLight,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.divider,
            ),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            onSelected: (_) {
              if (pet.id != null) {
                onSelected(pet.id!);
              }
            },
          );
        },
      ),
    );
  }
}

