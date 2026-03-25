/// Справочник поз (для записей о сексе и будущей статистики).
class KamasutraPose {
  const KamasutraPose({
    required this.id,
    required this.label,
    required this.imageAsset,
    required this.description,
    this.stepAssets = const [],
    this.stepTexts = const [],
  });

  final String id;
  final String label;
  final String imageAsset;
  final String description;
  final List<String> stepAssets;
  final List<String> stepTexts;
}

KamasutraPose _pose(
  String id,
  String label, {
  String? description,
}) {
  return KamasutraPose(
    id: id,
    label: label,
    imageAsset: 'assets/kamasutra/common/cover.svg',
    description: description ??
        'Плавно займите позицию, поддерживайте зрительный контакт и ориентируйтесь на комфорт обоих партнёров.',
    stepAssets: const [
      'assets/kamasutra/common/step_1.svg',
      'assets/kamasutra/common/step_2.svg',
      'assets/kamasutra/common/step_3.svg',
    ],
    stepTexts: const [
      'Шаг 1: договоритесь о темпе и границах.',
      'Шаг 2: займите устойчивое положение и синхронизируйте движение.',
      'Шаг 3: добавьте вариации угла и глубины по ощущениям.',
    ],
  );
}

final List<KamasutraPose> kamasutraPoses = [
  _pose('missionary', 'Миссионерская', description: 'Классическая позиция лицом к лицу с удобной глубиной контроля.'),
  _pose('cowgirl', 'Наездница', description: 'Партнёр сверху контролирует ритм и амплитуду движений.'),
  _pose('reverse_cowgirl', 'Обратная наездница', description: 'Вариант наездницы с разворотом корпуса спиной к партнёру.'),
  _pose('doggy', 'Догги-стайл', description: 'Позиция с опорой на руки/локти, удобна для вариативных углов.'),
  _pose('spoons', 'Ложки', description: 'Боковая близкая позиция с мягким ритмом и телесным контактом.'),
  _pose('standing', 'Стоя', description: 'Вертикальная позиция, часто требует опоры на стену или мебель.'),
  _pose('sitting', 'Сидя', description: 'Партнёры сидят лицом друг к другу, удобна для контроля глубины.'),
  _pose('sideways', 'Боком', description: 'Позиция на боку с расслабленной нагрузкой на спину и колени.'),
  _pose('scissors', 'Ножницы', description: 'Ноги партнёров перекрещиваются для плотного контакта и угла.'),
  _pose('triangle', 'Треугольник', description: 'Позиция с разворотом таза и акцентом на угол проникновения.'),
  _pose('tigress', 'Тигрица'),
  _pose('lotus', 'Лотос'),
  _pose('tree', 'Дерево'),
  _pose('boat', 'Лодка'),
  _pose('yab-yum', 'Яб-Юм'),
  _pose('butterfly', 'Бабочка'),
  _pose('crab', 'Краб'),
  _pose('splitting_bamboo', 'Расщепление бамбука'),
  _pose('rising', 'Восхождение'),
  _pose('suspended_congress', 'Подвешенный конгресс'),
  _pose('supported_congress', 'Поддерживаемый конгресс'),
  _pose('wheel', 'Колесо'),
  _pose('bridge', 'Мост'),
  _pose('reclining', 'Возлежание'),
  _pose('propeller', 'Пропеллер'),
  _pose('climbing', 'Восхождение на дерево'),
  _pose('indrani', 'Индрани'),
  _pose('pair', 'Пара'),
  _pose('milk_water', 'Молоко и вода'),
  _pose('folded', 'Сложенная'),
];
