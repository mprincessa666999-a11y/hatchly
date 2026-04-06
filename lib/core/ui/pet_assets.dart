import 'package:flutter/material.dart';

class PetAssets {
  /// Маппинг id питомца → путь к грустной картинке
  static const Map<String, String> sadImages = {
    'chunya': 'assets/pets/chynya_sad.png',
    'astra': 'assets/pets/astra_sad.png',
    'flik': 'assets/pets/flik_sad.png',
    'niks': 'assets/pets/pix_sad.png',
    'plyuh': 'assets/pets/plyukh_sad.png',
    'zippo': 'assets/pets/zippo_sad.png',
  };

  /// Получить путь к картинке по id питомца
  static String sadImage(String? petId) {
    if (petId == null) return sadImages.values.first;
    return sadImages[petId.toLowerCase()] ?? sadImages.values.first;
  }

  /// Виджет грустного питомца для пустых экранов
  static Widget sadPetWidget({String? petId, double size = 120}) {
    return Image.asset(
      sadImage(petId),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
