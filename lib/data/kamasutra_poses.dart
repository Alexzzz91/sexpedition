/// Справочник поз (для записей о сексе и будущей статистики).
class KamasutraPose {
  const KamasutraPose({required this.id, required this.label});
  final String id;
  final String label;
}

const List<KamasutraPose> kamasutraPoses = [
  KamasutraPose(id: 'missionary', label: 'Миссионерская'),
  KamasutraPose(id: 'cowgirl', label: 'Наездница'),
  KamasutraPose(id: 'reverse_cowgirl', label: 'Обратная наездница'),
  KamasutraPose(id: 'doggy', label: 'Догги-стайл'),
  KamasutraPose(id: 'spoons', label: 'Ложки'),
  KamasutraPose(id: 'standing', label: 'Стоя'),
  KamasutraPose(id: 'sitting', label: 'Сидя'),
  KamasutraPose(id: 'sideways', label: 'Боком'),
  KamasutraPose(id: 'scissors', label: 'Ножницы'),
  KamasutraPose(id: 'triangle', label: 'Треугольник'),
  KamasutraPose(id: 'tigress', label: 'Тигрица'),
  KamasutraPose(id: 'lotus', label: 'Лотос'),
  KamasutraPose(id: 'tree', label: 'Дерево'),
  KamasutraPose(id: 'boat', label: 'Лодка'),
  KamasutraPose(id: 'yab-yum', label: 'Яб-Юм'),
  KamasutraPose(id: 'butterfly', label: 'Бабочка'),
  KamasutraPose(id: 'crab', label: 'Краб'),
  KamasutraPose(id: 'splitting_bamboo', label: 'Расщепление бамбука'),
  KamasutraPose(id: 'rising', label: 'Восхождение'),
  KamasutraPose(id: 'suspended_congress', label: 'Подвешенный конгресс'),
  KamasutraPose(id: 'supported_congress', label: 'Поддерживаемый конгресс'),
  KamasutraPose(id: 'wheel', label: 'Колесо'),
  KamasutraPose(id: 'bridge', label: 'Мост'),
  KamasutraPose(id: 'reclining', label: 'Возлежание'),
  KamasutraPose(id: 'propeller', label: 'Пропеллер'),
  KamasutraPose(id: 'climbing', label: 'Восхождение на дерево'),
  KamasutraPose(id: 'indrani', label: 'Индрани'),
  KamasutraPose(id: 'pair', label: 'Пара'),
  KamasutraPose(id: 'milk_water', label: 'Молоко и вода'),
  KamasutraPose(id: 'folded', label: 'Сложенная'),
];
