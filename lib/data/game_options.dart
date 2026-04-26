enum GameDiceOptionCategory { place, pose }

class GameDiceOption {
  const GameDiceOption({
    required this.id,
    required this.label,
    required this.category,
    this.isDefault = true,
    this.enabled = true,
  });

  final String id;
  final String label;
  final GameDiceOptionCategory category;
  final bool isDefault;
  final bool enabled;
}

const List<GameDiceOption> defaultGameDiceOptions = [
  GameDiceOption(
    id: 'kitchen_table',
    label: 'Кухня на столе',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'sofa',
    label: 'Диван',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'bed',
    label: 'Кровать',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'bathroom',
    label: 'Ванная комната',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'mirror',
    label: 'У зеркала',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'balcony_window',
    label: 'На балконе / у окна',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'kitchen_counter',
    label: 'На кухне у столешницы',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'soft_blanket_floor',
    label: 'На полу на мягком пледе',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'shower',
    label: 'В душе',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'hallway_wall',
    label: 'В коридоре у стены',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'armchair',
    label: 'В кресле',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'washing_machine',
    label: 'На стиральной машине',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'car',
    label: 'В машине',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'wardrobe',
    label: 'В гардеробной',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'evening_window',
    label: 'У окна вечером',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'hotel',
    label: 'В отеле',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'carpet',
    label: 'На ковре',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'chair',
    label: 'На стуле',
    category: GameDiceOptionCategory.place,
  ),
  GameDiceOption(
    id: 'cowgirl',
    label: 'Девушка сверху',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'doggy',
    label: 'Раком',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'sideways',
    label: 'Боком',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'blowjob',
    label: 'Миньет',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'cunnilingus',
    label: 'Кунилингус',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'missionary',
    label: 'Миссионерская',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'spoons',
    label: 'Ложки',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'standing_wall',
    label: 'Стоя у стены',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'sitting_face_to_face',
    label: 'Сидя лицом к лицу',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'reverse_cowgirl',
    label: 'Обратная наездница',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'missionary_angle',
    label: 'Миссионерская с вариацией угла',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'sixty_nine',
    label: '69',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'deep_kissing',
    label: 'Глубокие поцелуи без спешки',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'massage_before',
    label: 'Массаж перед продолжением',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'soft_bound_hands',
    label: 'Руки связаны мягко',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'oral_only',
    label: 'Только оральные ласки',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'slow_tempo',
    label: 'Медленный темп',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'fast_tempo',
    label: 'Быстрый темп',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'no_hands',
    label: 'Без рук',
    category: GameDiceOptionCategory.pose,
  ),
  GameDiceOption(
    id: 'blindfold',
    label: 'С завязанными глазами',
    category: GameDiceOptionCategory.pose,
  ),
];

List<GameDiceOption> enabledDiceOptions(GameDiceOptionCategory category) {
  return defaultGameDiceOptions
      .where((option) => option.category == category && option.enabled)
      .toList();
}
