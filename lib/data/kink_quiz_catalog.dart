enum KinkQuizCategory {
  classic,
  oral,
  anal,
  bdsm,
  group,
  roleplay,
  toys,
  sensory,
  publicFantasy,
  romantic,
}

class KinkQuizItem {
  const KinkQuizItem({
    required this.id,
    required this.category,
    required this.titleKey,
    this.descriptionKey,
    this.weightTried = 1,
    this.weightLoved = 2,
    this.enabled = true,
  });

  final String id;
  final KinkQuizCategory category;
  final String titleKey;
  final String? descriptionKey;
  final int weightTried;
  final int weightLoved;
  final bool enabled;
}

const List<KinkQuizItem> kinkQuizCatalog = [
  KinkQuizItem(
    id: 'classic_sex',
    category: KinkQuizCategory.classic,
    titleKey: 'practiceClassicSex',
  ),
  KinkQuizItem(
    id: 'missionary',
    category: KinkQuizCategory.classic,
    titleKey: 'practiceMissionary',
  ),
  KinkQuizItem(
    id: 'cowgirl',
    category: KinkQuizCategory.classic,
    titleKey: 'practiceCowgirl',
  ),
  KinkQuizItem(
    id: 'sideways',
    category: KinkQuizCategory.classic,
    titleKey: 'practiceSideways',
  ),
  KinkQuizItem(
    id: 'spoons',
    category: KinkQuizCategory.classic,
    titleKey: 'practiceSpoons',
  ),
  KinkQuizItem(
    id: 'blowjob',
    category: KinkQuizCategory.oral,
    titleKey: 'practiceBlowjob',
  ),
  KinkQuizItem(
    id: 'cunnilingus',
    category: KinkQuizCategory.oral,
    titleKey: 'practiceCunnilingus',
  ),
  KinkQuizItem(
    id: 'sixty_nine',
    category: KinkQuizCategory.oral,
    titleKey: 'practiceSixtyNine',
  ),
  KinkQuizItem(
    id: 'oral_only',
    category: KinkQuizCategory.oral,
    titleKey: 'practiceOralOnly',
  ),
  KinkQuizItem(
    id: 'anal_sex',
    category: KinkQuizCategory.anal,
    titleKey: 'practiceAnalSex',
  ),
  KinkQuizItem(
    id: 'anal_play',
    category: KinkQuizCategory.anal,
    titleKey: 'practiceAnalPlay',
  ),
  KinkQuizItem(
    id: 'anal_toys',
    category: KinkQuizCategory.anal,
    titleKey: 'practiceAnalToys',
  ),
  KinkQuizItem(
    id: 'bondage',
    category: KinkQuizCategory.bdsm,
    titleKey: 'practiceBondage',
  ),
  KinkQuizItem(
    id: 'dominance',
    category: KinkQuizCategory.bdsm,
    titleKey: 'practiceDominance',
  ),
  KinkQuizItem(
    id: 'spanking',
    category: KinkQuizCategory.bdsm,
    titleKey: 'practiceSpanking',
  ),
  KinkQuizItem(
    id: 'safeword',
    category: KinkQuizCategory.bdsm,
    titleKey: 'practiceSafeword',
  ),
  KinkQuizItem(
    id: 'threesome',
    category: KinkQuizCategory.group,
    titleKey: 'practiceThreesome',
  ),
  KinkQuizItem(
    id: 'group_sex',
    category: KinkQuizCategory.group,
    titleKey: 'practiceGroupSex',
  ),
  KinkQuizItem(
    id: 'swing',
    category: KinkQuizCategory.group,
    titleKey: 'practiceSwing',
  ),
  KinkQuizItem(
    id: 'roleplay',
    category: KinkQuizCategory.roleplay,
    titleKey: 'practiceRoleplay',
  ),
  KinkQuizItem(
    id: 'costumes',
    category: KinkQuizCategory.roleplay,
    titleKey: 'practiceCostumes',
  ),
  KinkQuizItem(
    id: 'power_scenario',
    category: KinkQuizCategory.roleplay,
    titleKey: 'practicePowerScenario',
  ),
  KinkQuizItem(
    id: 'vibrator',
    category: KinkQuizCategory.toys,
    titleKey: 'practiceVibrator',
  ),
  KinkQuizItem(
    id: 'dildo',
    category: KinkQuizCategory.toys,
    titleKey: 'practiceDildo',
  ),
  KinkQuizItem(
    id: 'handcuffs',
    category: KinkQuizCategory.toys,
    titleKey: 'practiceHandcuffs',
  ),
  KinkQuizItem(
    id: 'blindfold',
    category: KinkQuizCategory.toys,
    titleKey: 'practiceBlindfold',
  ),
  KinkQuizItem(
    id: 'massage',
    category: KinkQuizCategory.sensory,
    titleKey: 'practiceMassage',
  ),
  KinkQuizItem(
    id: 'temperature',
    category: KinkQuizCategory.sensory,
    titleKey: 'practiceTemperature',
  ),
  KinkQuizItem(
    id: 'music_mood',
    category: KinkQuizCategory.sensory,
    titleKey: 'practiceMusicMood',
  ),
  KinkQuizItem(
    id: 'window',
    category: KinkQuizCategory.publicFantasy,
    titleKey: 'practiceWindow',
  ),
  KinkQuizItem(
    id: 'balcony',
    category: KinkQuizCategory.publicFantasy,
    titleKey: 'practiceBalcony',
  ),
  KinkQuizItem(
    id: 'car',
    category: KinkQuizCategory.publicFantasy,
    titleKey: 'practiceCar',
  ),
  KinkQuizItem(
    id: 'long_kisses',
    category: KinkQuizCategory.romantic,
    titleKey: 'practiceLongKisses',
  ),
  KinkQuizItem(
    id: 'slow_tempo',
    category: KinkQuizCategory.romantic,
    titleKey: 'practiceSlowTempo',
  ),
  KinkQuizItem(
    id: 'aftercare',
    category: KinkQuizCategory.romantic,
    titleKey: 'practiceAftercare',
  ),
  KinkQuizItem(
    id: 'shower_together',
    category: KinkQuizCategory.romantic,
    titleKey: 'practiceShowerTogether',
  ),
];

List<KinkQuizItem> enabledKinkQuizItems() {
  return kinkQuizCatalog.where((item) => item.enabled).toList();
}

int kinkQuizMaxScore() {
  return enabledKinkQuizItems().fold<int>(
    0,
    (sum, item) => sum + item.weightTried + item.weightLoved,
  );
}
