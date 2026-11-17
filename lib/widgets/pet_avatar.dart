import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/models/pet.dart';

class PetAvatar extends StatelessWidget {
  const PetAvatar({
    super.key,
    required this.pet,
    this.radius = 26,
  });

  final Pet pet;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photoPath = pet.photoPath;
    if (photoPath != null && photoPath.isNotEmpty) {
      final file = File(photoPath);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: FileImage(file),
        );
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      child: Icon(
        Icons.pets_rounded,
        size: radius * 0.95,
        color: AppColors.primaryDark,
      ),
    );
  }
}

