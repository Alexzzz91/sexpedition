import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hy.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_th.dart';
import 'app_localizations_uz.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('hy'),
    Locale('kk'),
    Locale('ru'),
    Locale('sv'),
    Locale('th'),
    Locale('uz'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Секс-календарь'**
  String get appTitle;

  /// No description provided for @navCalendar.
  ///
  /// In ru, this message translates to:
  /// **'Календарь'**
  String get navCalendar;

  /// No description provided for @navWishes.
  ///
  /// In ru, this message translates to:
  /// **'Желания'**
  String get navWishes;

  /// No description provided for @navPartners.
  ///
  /// In ru, this message translates to:
  /// **'Партнёры'**
  String get navPartners;

  /// No description provided for @navProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get navProfile;

  /// No description provided for @profileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profileTitle;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In ru, this message translates to:
  /// **'Как в системе'**
  String get languageSystem;

  /// No description provided for @kinkQuizTitle.
  ///
  /// In ru, this message translates to:
  /// **'Анкета предпочтений'**
  String get kinkQuizTitle;

  /// No description provided for @kinkQuizSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Оцените, что вы пробовали и что вам нравится'**
  String get kinkQuizSubtitle;

  /// No description provided for @tried.
  ///
  /// In ru, this message translates to:
  /// **'Пробовал'**
  String get tried;

  /// No description provided for @loved.
  ///
  /// In ru, this message translates to:
  /// **'Люблю'**
  String get loved;

  /// No description provided for @showPartner.
  ///
  /// In ru, this message translates to:
  /// **'Показывать партнёру'**
  String get showPartner;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено'**
  String get saved;

  /// No description provided for @score.
  ///
  /// In ru, this message translates to:
  /// **'Результат'**
  String get score;

  /// No description provided for @maxScore.
  ///
  /// In ru, this message translates to:
  /// **'Максимум'**
  String get maxScore;

  /// No description provided for @levelLow.
  ///
  /// In ru, this message translates to:
  /// **'Мягкий интерес'**
  String get levelLow;

  /// No description provided for @levelMedium.
  ///
  /// In ru, this message translates to:
  /// **'Открытый исследователь'**
  String get levelMedium;

  /// No description provided for @levelHigh.
  ///
  /// In ru, this message translates to:
  /// **'Смелый экспериментатор'**
  String get levelHigh;

  /// No description provided for @levelMax.
  ///
  /// In ru, this message translates to:
  /// **'Максимальная открытость'**
  String get levelMax;

  /// No description provided for @levelDescriptionLow.
  ///
  /// In ru, this message translates to:
  /// **'Вы выбираете комфорт и спокойный темп.'**
  String get levelDescriptionLow;

  /// No description provided for @levelDescriptionMedium.
  ///
  /// In ru, this message translates to:
  /// **'У вас уже есть интерес к экспериментам и понятные границы.'**
  String get levelDescriptionMedium;

  /// No description provided for @levelDescriptionHigh.
  ///
  /// In ru, this message translates to:
  /// **'Вы открыты к разнообразию и хорошо знаете свои предпочтения.'**
  String get levelDescriptionHigh;

  /// No description provided for @levelDescriptionMax.
  ///
  /// In ru, this message translates to:
  /// **'Ваш профиль очень разнообразный, главное — согласие и безопасность.'**
  String get levelDescriptionMax;

  /// No description provided for @categoryClassic.
  ///
  /// In ru, this message translates to:
  /// **'Классика'**
  String get categoryClassic;

  /// No description provided for @categoryOral.
  ///
  /// In ru, this message translates to:
  /// **'Оральные практики'**
  String get categoryOral;

  /// No description provided for @categoryAnal.
  ///
  /// In ru, this message translates to:
  /// **'Анальные практики'**
  String get categoryAnal;

  /// No description provided for @categoryBdsm.
  ///
  /// In ru, this message translates to:
  /// **'BDSM'**
  String get categoryBdsm;

  /// No description provided for @categoryGroup.
  ///
  /// In ru, this message translates to:
  /// **'Групповые сценарии'**
  String get categoryGroup;

  /// No description provided for @categoryRoleplay.
  ///
  /// In ru, this message translates to:
  /// **'Ролевые игры'**
  String get categoryRoleplay;

  /// No description provided for @categoryToys.
  ///
  /// In ru, this message translates to:
  /// **'Игрушки'**
  String get categoryToys;

  /// No description provided for @categorySensory.
  ///
  /// In ru, this message translates to:
  /// **'Сенсорика'**
  String get categorySensory;

  /// No description provided for @categoryPublicFantasy.
  ///
  /// In ru, this message translates to:
  /// **'Фантазии о месте'**
  String get categoryPublicFantasy;

  /// No description provided for @categoryRomantic.
  ///
  /// In ru, this message translates to:
  /// **'Романтика'**
  String get categoryRomantic;

  /// No description provided for @practiceClassicSex.
  ///
  /// In ru, this message translates to:
  /// **'Классический секс'**
  String get practiceClassicSex;

  /// No description provided for @practiceMissionary.
  ///
  /// In ru, this message translates to:
  /// **'Миссионерская'**
  String get practiceMissionary;

  /// No description provided for @practiceCowgirl.
  ///
  /// In ru, this message translates to:
  /// **'Девушка сверху'**
  String get practiceCowgirl;

  /// No description provided for @practiceSideways.
  ///
  /// In ru, this message translates to:
  /// **'Боком'**
  String get practiceSideways;

  /// No description provided for @practiceSpoons.
  ///
  /// In ru, this message translates to:
  /// **'Ложки'**
  String get practiceSpoons;

  /// No description provided for @practiceBlowjob.
  ///
  /// In ru, this message translates to:
  /// **'Миньет'**
  String get practiceBlowjob;

  /// No description provided for @practiceCunnilingus.
  ///
  /// In ru, this message translates to:
  /// **'Кунилингус'**
  String get practiceCunnilingus;

  /// No description provided for @practiceSixtyNine.
  ///
  /// In ru, this message translates to:
  /// **'69'**
  String get practiceSixtyNine;

  /// No description provided for @practiceOralOnly.
  ///
  /// In ru, this message translates to:
  /// **'Только оральные ласки'**
  String get practiceOralOnly;

  /// No description provided for @practiceAnalSex.
  ///
  /// In ru, this message translates to:
  /// **'Анальный секс'**
  String get practiceAnalSex;

  /// No description provided for @practiceAnalPlay.
  ///
  /// In ru, this message translates to:
  /// **'Анальные ласки'**
  String get practiceAnalPlay;

  /// No description provided for @practiceAnalToys.
  ///
  /// In ru, this message translates to:
  /// **'Анальные игрушки'**
  String get practiceAnalToys;

  /// No description provided for @practiceBondage.
  ///
  /// In ru, this message translates to:
  /// **'Связывание'**
  String get practiceBondage;

  /// No description provided for @practiceDominance.
  ///
  /// In ru, this message translates to:
  /// **'Доминация/подчинение'**
  String get practiceDominance;

  /// No description provided for @practiceSpanking.
  ///
  /// In ru, this message translates to:
  /// **'Шлёпанье'**
  String get practiceSpanking;

  /// No description provided for @practiceSafeword.
  ///
  /// In ru, this message translates to:
  /// **'Стоп-слово и правила'**
  String get practiceSafeword;

  /// No description provided for @practiceThreesome.
  ///
  /// In ru, this message translates to:
  /// **'Секс втроём'**
  String get practiceThreesome;

  /// No description provided for @practiceGroupSex.
  ///
  /// In ru, this message translates to:
  /// **'Групповой секс'**
  String get practiceGroupSex;

  /// No description provided for @practiceSwing.
  ///
  /// In ru, this message translates to:
  /// **'Свинг'**
  String get practiceSwing;

  /// No description provided for @practiceRoleplay.
  ///
  /// In ru, this message translates to:
  /// **'Ролевые сценарии'**
  String get practiceRoleplay;

  /// No description provided for @practiceCostumes.
  ///
  /// In ru, this message translates to:
  /// **'Костюмы'**
  String get practiceCostumes;

  /// No description provided for @practicePowerScenario.
  ///
  /// In ru, this message translates to:
  /// **'Сценарии власти'**
  String get practicePowerScenario;

  /// No description provided for @practiceVibrator.
  ///
  /// In ru, this message translates to:
  /// **'Вибратор'**
  String get practiceVibrator;

  /// No description provided for @practiceDildo.
  ///
  /// In ru, this message translates to:
  /// **'Дилдо'**
  String get practiceDildo;

  /// No description provided for @practiceHandcuffs.
  ///
  /// In ru, this message translates to:
  /// **'Наручники'**
  String get practiceHandcuffs;

  /// No description provided for @practiceBlindfold.
  ///
  /// In ru, this message translates to:
  /// **'Повязка на глаза'**
  String get practiceBlindfold;

  /// No description provided for @practiceMassage.
  ///
  /// In ru, this message translates to:
  /// **'Массаж'**
  String get practiceMassage;

  /// No description provided for @practiceTemperature.
  ///
  /// In ru, this message translates to:
  /// **'Температурные игры'**
  String get practiceTemperature;

  /// No description provided for @practiceMusicMood.
  ///
  /// In ru, this message translates to:
  /// **'Музыка и атмосфера'**
  String get practiceMusicMood;

  /// No description provided for @practiceWindow.
  ///
  /// In ru, this message translates to:
  /// **'У окна'**
  String get practiceWindow;

  /// No description provided for @practiceBalcony.
  ///
  /// In ru, this message translates to:
  /// **'На балконе'**
  String get practiceBalcony;

  /// No description provided for @practiceCar.
  ///
  /// In ru, this message translates to:
  /// **'В машине'**
  String get practiceCar;

  /// No description provided for @practiceLongKisses.
  ///
  /// In ru, this message translates to:
  /// **'Долгие поцелуи'**
  String get practiceLongKisses;

  /// No description provided for @practiceSlowTempo.
  ///
  /// In ru, this message translates to:
  /// **'Медленный темп'**
  String get practiceSlowTempo;

  /// No description provided for @practiceAftercare.
  ///
  /// In ru, this message translates to:
  /// **'Послеигра'**
  String get practiceAftercare;

  /// No description provided for @practiceShowerTogether.
  ///
  /// In ru, this message translates to:
  /// **'Совместный душ'**
  String get practiceShowerTogether;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'fr',
    'hy',
    'kk',
    'ru',
    'sv',
    'th',
    'uz',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'hy':
      return AppLocalizationsHy();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
    case 'th':
      return AppLocalizationsTh();
    case 'uz':
      return AppLocalizationsUz();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
