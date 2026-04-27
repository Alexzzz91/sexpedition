class AdventTask {
  const AdventTask({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.intensity,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final int intensity;
}

const adventTasks = <AdventTask>[
  AdventTask(
    id: 'slow_kiss_map',
    title: 'Карта поцелуев',
    description:
        'Выберите 5 мест на теле партнёра и уделите каждому минимум минуту.',
    category: 'Нежность',
    intensity: 1,
  ),
  AdventTask(
    id: 'hotel_memory',
    title: 'Место для памяти',
    description:
        'Придумайте место, где вы хотели бы оставить новую сексуальную память.',
    category: 'Фантазия',
    intensity: 1,
  ),
  AdventTask(
    id: 'blind_touch',
    title: 'Прикосновения вслепую',
    description:
        'Один закрывает глаза на 10 минут, второй исследует только руками и губами.',
    category: 'Игра',
    intensity: 2,
  ),
  AdventTask(
    id: 'three_words',
    title: 'Три слова желания',
    description:
        'Каждый пишет три слова о том, чего хочет сегодня, и вы выбираете одно общее.',
    category: 'Разговор',
    intensity: 1,
  ),
  AdventTask(
    id: 'new_room_rule',
    title: 'Правило новой комнаты',
    description:
        'Выберите место, где обычно не занимаетесь сексом, и сделайте его сценой дня.',
    category: 'Эксперимент',
    intensity: 2,
  ),
  AdventTask(
    id: 'massage_then_more',
    title: 'Массаж без спешки',
    description:
        'Начните с 15 минут массажа. Переходить дальше можно только после таймера.',
    category: 'Нежность',
    intensity: 2,
  ),
  AdventTask(
    id: 'yes_no_maybe',
    title: 'Да, нет, может быть',
    description:
        'Назовите по одной практике в каждой категории и обсудите безопасный вариант на сегодня.',
    category: 'Разговор',
    intensity: 1,
  ),
  AdventTask(
    id: 'surprise_outfit',
    title: 'Сюрприз-образ',
    description:
        'Один выбирает образ или деталь одежды, второй узнаёт только перед встречей.',
    category: 'Игра',
    intensity: 2,
  ),
  AdventTask(
    id: 'no_hands_minute',
    title: 'Минута без рук',
    description:
        'В течение минуты можно использовать всё, кроме рук. Потом поменяйтесь.',
    category: 'Эксперимент',
    intensity: 3,
  ),
  AdventTask(
    id: 'aftercare_note',
    title: 'Записка после',
    description:
        'После близости каждый пишет одну фразу, которую хочет запомнить об этом моменте.',
    category: 'Память',
    intensity: 1,
  ),
];

AdventTask adventTaskById(String id) {
  return adventTasks.firstWhere(
    (task) => task.id == id,
    orElse: () => adventTasks.first,
  );
}
