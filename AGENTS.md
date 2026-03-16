# AGENTS.md

Контекст для AI-агентов и разработчиков: описание проекта, структура кода, команды и соглашения.

---

## Описание проекта

Flutter-приложение **«Секс-календарь»**: календарь событий, управление партнёрами, список желаний. Бэкенд — Firebase (Auth, Firestore).

---

## Стек

- **Flutter** (Dart 3.x), Material 3
- **Firebase**: Auth (email/password), Firestore
- **Зависимости**: firebase_core, firebase_auth, cloud_firestore, provider, table_calendar

Коллекции Firestore: `users`, `connections`, `events`, `wishes`, `wish_requests`.

---

## Структура lib/

| Путь | Назначение |
|------|------------|
| `main.dart` | Точка входа, инициализация Firebase, корень MaterialApp |
| `app.dart` | StreamBuilder по authStateChanges: не авторизован → AuthScreen, иначе → MainShell |
| `screen/` | Экраны: AuthScreen, MainShell (нижняя навигация), CalendarScreen, WishesScreen, PartnersScreen, ProfileScreen |
| `models/` | Доменные модели: calendar_event, partner_connection, user_profile, wish, wish_request |
| `services/` | Репозитории для Firestore: events_repository, partners_repository, wishes_repository |
| `firebase_options.dart` | Генерируется FlutterFire CLI, **не редактировать вручную** |

---

## Команды

- **Запуск**: `flutter run`, `flutter run -d chrome`, `flutter run -d web-server`, `flutter run -d linux`
- **Зависимости**: `flutter pub get`
- **Анализ**: `flutter analyze`
- **Сборка веба**: `flutter build web`
- **Деплой веба**: `firebase deploy --only hosting` (после `flutter build web`)

---

## Firebase

- **Проект**: sexpedition-55
- **Hosting**: каталог `build/web`, URL: https://sexpedition-55.web.app
- **Правила**: `firestore.rules` в корне; при необходимости — `firestore.indexes.json`

---

## Соглашения для агентов

1. Не менять `lib/firebase_options.dart` вручную.
2. Новые экраны — в `lib/screen/`, модели — в `lib/models/`, работа с Firestore — в `lib/services/`.
3. Стримы для списков создавать один раз (например в `initState`) и передавать в виджеты по параметру, чтобы не пересоздавать подписку при каждом `build`.
