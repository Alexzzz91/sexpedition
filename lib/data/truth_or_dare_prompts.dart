enum TruthOrDareLevel { soft, hot, extreme }

class TruthOrDarePrompt {
  const TruthOrDarePrompt({
    required this.id,
    required this.text,
    this.level = TruthOrDareLevel.soft,
  });

  final String id;
  final String text;
  final TruthOrDareLevel level;
}

const List<TruthOrDarePrompt> truthPrompts = [
  TruthOrDarePrompt(
    id: 'truth_secret_from_family',
    text: 'Какой секрет о тебе до сих пор не знают близкие?',
  ),
  TruthOrDarePrompt(
    id: 'truth_hottest_body_part',
    text: 'Какая часть твоего тела тебе кажется самой сексуальной?',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'truth_last_lie',
    text: 'Какую последнюю ложь ты говорил(а)?',
  ),
  TruthOrDarePrompt(
    id: 'truth_awkward_date',
    text: 'Какое свидание было самым неловким в твоей жизни?',
  ),
  TruthOrDarePrompt(
    id: 'truth_hidden_hobby',
    text: 'Какое хобби у тебя есть, о котором почти никто не знает?',
  ),
  TruthOrDarePrompt(
    id: 'truth_weird_search',
    text: 'Что самое странное ты искал(а) в интернете за последнее время?',
  ),
  TruthOrDarePrompt(
    id: 'truth_ex_still_feelings',
    text: 'Остались ли у тебя чувства к кому-то из бывших?',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'truth_relationship_taboo',
    text: 'Что для тебя абсолютно непростительно в отношениях?',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'truth_nonobvious_attraction',
    text: 'Какая неочевидная вещь в человеке тебя сильно привлекает?',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'truth_wild_youth',
    text: 'Какой безумный поступок из молодости ты помнишь лучше всего?',
  ),
  TruthOrDarePrompt(
    id: 'truth_how_to_seduce_you',
    text: 'Что нужно сделать, чтобы быстро тебя соблазнить?',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'truth_what_turns_you_on',
    text: 'Что тебя заводит сильнее всего: слова, взгляд, прикосновение или сценарий?',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'truth_hottest_lingerie',
    text: 'Какое нижнее белье ты считаешь самым горячим?',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'truth_public_naughty_story',
    text: 'Какой самый дерзкий поступок на публике у тебя был?',
    level: TruthOrDareLevel.extreme,
  ),
  TruthOrDarePrompt(
    id: 'truth_fetishes',
    text: 'Есть ли у тебя фетиши, о которых редко говоришь?',
    level: TruthOrDareLevel.extreme,
  ),
  TruthOrDarePrompt(
    id: 'truth_last_naughty_dream',
    text: 'Какой последний откровенный сон тебе запомнился?',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'truth_best_kiss_memory',
    text: 'Самый запоминающийся поцелуй в твоей жизни?',
  ),
  TruthOrDarePrompt(
    id: 'truth_ideal_evening',
    text: 'Как выглядит твой идеальный романтический вечер?',
  ),
  TruthOrDarePrompt(
    id: 'truth_best_body_part_partner',
    text: 'Какая часть тела у партнера тебе нравится больше всего?',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'truth_make_evening_worthy',
    text: 'Что точно сделает вечер с тобой незабываемым?',
  ),
  TruthOrDarePrompt(
    id: 'truth_jealousy_trigger',
    text: 'Что чаще всего вызывает у тебя ревность?',
  ),
  TruthOrDarePrompt(
    id: 'truth_strangest_bedroom_item',
    text: 'Какая самая странная вещь когда-либо была у тебя в спальне?',
    level: TruthOrDareLevel.extreme,
  ),
  TruthOrDarePrompt(
    id: 'truth_if_million',
    text: 'Что ты сделал(а) бы за миллион долларов?',
  ),
  TruthOrDarePrompt(
    id: 'truth_biggest_regret',
    text: 'О чем ты сожалеешь больше всего в личной жизни?',
  ),
  TruthOrDarePrompt(
    id: 'truth_showing_interest',
    text: 'Как ты обычно показываешь человеку, что он тебе нравится?',
  ),
  TruthOrDarePrompt(
    id: 'truth_hidden_fear',
    text: 'О каком страхе ты обычно никому не рассказываешь?',
  ),
  TruthOrDarePrompt(
    id: 'truth_never_told_anyone',
    text: 'Что ты никогда не говорил(а) вслух, но очень хотел(а)?',
  ),
  TruthOrDarePrompt(
    id: 'truth_next_experiment',
    text: 'Что нового в интимной жизни ты хочешь попробовать в ближайшее время?',
    level: TruthOrDareLevel.extreme,
  ),
  TruthOrDarePrompt(
    id: 'truth_secret_desire',
    text: 'Какое твое тайное желание ты пока не реализовал(а)?',
    level: TruthOrDareLevel.extreme,
  ),
];

const List<TruthOrDarePrompt> darePrompts = [
  TruthOrDarePrompt(
    id: 'dare_signature_dance_move',
    text: 'Покажи свое коронное танцевальное движение.',
  ),
  TruthOrDarePrompt(
    id: 'dare_invisible_guitar',
    text: 'Сыграй минуту на воображаемой гитаре.',
  ),
  TruthOrDarePrompt(
    id: 'dare_sleep_pose',
    text: 'Покажи позу, в которой ты обычно спишь.',
  ),
  TruthOrDarePrompt(
    id: 'dare_serenade',
    text: 'Исполни мини-серенаду любому игроку.',
    level: TruthOrDareLevel.soft,
  ),
  TruthOrDarePrompt(
    id: 'dare_twerk_minute',
    text: 'Сделай тверк в течение 30 секунд.',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'dare_catwalk',
    text: 'Пройди по комнате как модель на подиуме.',
  ),
  TruthOrDarePrompt(
    id: 'dare_persuade_kiss',
    text: 'Попробуй уговорить одного игрока на поцелуй (только по согласию).',
    level: TruthOrDareLevel.extreme,
  ),
  TruthOrDarePrompt(
    id: 'dare_ice_on_stomach',
    text: 'Подержи кубик льда на животе, пока он не растает.',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'dare_plank',
    text: 'Простой в планке 1 минуту.',
  ),
  TruthOrDarePrompt(
    id: 'dare_pushups_or_squats',
    text: 'Сделай 15 приседаний или 10 отжиманий.',
  ),
  TruthOrDarePrompt(
    id: 'dare_monkey_mode',
    text: 'Веди себя как обезьяна до своего следующего хода.',
  ),
  TruthOrDarePrompt(
    id: 'dare_spin_and_walk',
    text: 'Покрутись 10 раз вокруг себя и попробуй пройти по прямой.',
  ),
  TruthOrDarePrompt(
    id: 'dare_belly_dance',
    text: 'Станцуй короткий танец живота.',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'dare_strip_no_undress',
    text: 'Станцуй стриптиз без раздевания.',
    level: TruthOrDareLevel.extreme,
  ),
  TruthOrDarePrompt(
    id: 'dare_private_dance',
    text: 'Станцуй приватный танец для выбранного игрока.',
    level: TruthOrDareLevel.extreme,
  ),
  TruthOrDarePrompt(
    id: 'dare_hot_food_bite',
    text: 'Соблазнительно съешь кусочек любой еды.',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'dare_kiss_air_video',
    text: 'Сними 5-секундное видео, как ты целуешь воздух.',
  ),
  TruthOrDarePrompt(
    id: 'dare_lullaby',
    text: 'Спой колыбельную одному из игроков.',
  ),
  TruthOrDarePrompt(
    id: 'dare_reverse_alphabet',
    text: 'Произнеси алфавит в обратном порядке.',
  ),
  TruthOrDarePrompt(
    id: 'dare_tongue_twister',
    text: 'Скажи скороговорку 3 раза подряд без ошибки.',
  ),
  TruthOrDarePrompt(
    id: 'dare_old_person',
    text: 'Изображай старика или старушку 1 минуту.',
  ),
  TruthOrDarePrompt(
    id: 'dare_pickup_line',
    text: 'Скажи лучшую версию своего подката любому игроку.',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'dare_three_compliments',
    text: 'Скажи одному игроку 3 откровенных комплимента подряд.',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'dare_hand_kiss',
    text: 'Поцелуй руку выбранному игроку и сделай реверанс.',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'dare_eye_contact',
    text: 'Смотри в глаза выбранному игроку 30 секунд без смеха.',
  ),
  TruthOrDarePrompt(
    id: 'dare_message_flirty',
    text: 'Отправь флирт-сообщение партнеру или крашу.',
    level: TruthOrDareLevel.hot,
  ),
  TruthOrDarePrompt(
    id: 'dare_new_dance_move',
    text: 'Придумай новое танцевальное движение и дай ему название.',
  ),
  TruthOrDarePrompt(
    id: 'dare_two_truths_one_lie',
    text: 'Расскажи две правды и одну ложь про себя.',
  ),
  TruthOrDarePrompt(
    id: 'dare_rizz_sale',
    text: 'За 30 секунд «продай» себя как идеального партнера.',
  ),
  TruthOrDarePrompt(
    id: 'dare_seductively_read',
    text: 'Прочитай любой нейтральный текст максимально соблазнительным голосом.',
    level: TruthOrDareLevel.extreme,
  ),
];
