---
name: Бесплатный деплой для тестирования
overview: "Куда и как бесплатно выложить приложение для тестирования: веб (Firebase Hosting и альтернативы) и мобильные сборки (Firebase App Distribution / внутреннее тестирование)."
todos: []
isProject: false
---

# Бесплатный деплой приложения для тестирования

## Рекомендация: веб на Firebase Hosting

У вас уже есть проект Firebase (sexpedition-55), Auth и Firestore. Проще всего выложить **веб-версию** на **Firebase Hosting** — бесплатный квот хватает на тестирование, один консоль и домен вида `https://sexpedition-55.web.app`.

**Шаги:**

1. **Добавить Hosting в [firebase.json](firebase.json)**
  В корень конфига добавить секцию `hosting` с `public: build/web` и опционально `ignore` для лишних файлов.
2. **Собрать веб-билд**
  Выполнить `flutter build web` (результат в `build/web`).
3. **Задеплоить**
  Выполнить `firebase deploy --only hosting`. После деплоя в консоли будет ссылка на сайт.
4. **Проверить**
  В Firebase Console → Hosting можно посмотреть URL, настроить свой домен (опционально) и при необходимости откатить версию.

Ограничения бесплатного тарифа (Spark): трафик и хранилище в пределах квот; для тестов этого достаточно.

---

## Другие бесплатные варианты для веба

- **Vercel** — подключить репозиторий, билд: `flutter build web`, корень публикации `build/web`. Бесплатный план с лимитами.
- **Netlify** — то же: указать команду сборки и папку `build/web`.
- **GitHub Pages** — залить содержимое `build/web` в ветку `gh-pages` или через GitHub Actions. Ограничение: только статика, без серверных редиректов (для SPA обычно настраивают 404 → index.html через конфиг).

Firebase Hosting выгоден тем, что проект уже в Firebase и не нужно настраивать переменные окружения для одного и того же бэкенда.

---

## Мобильное тестирование (Android / iOS)

- **Android**  
  - **Firebase App Distribution** — бесплатно: загружаете AAB/APK, добавляете тестеров по email, они получают ссылку на установку.  
  - **Google Play Internal testing** — бесплатно: загрузка в Play Console, внутренние тестеры по списку (до 100 человек).
- **iOS**  
  - **TestFlight** — бесплатно для тестеров, но нужна платная учётная запись Apple Developer (99 USD/год).  
  - **Firebase App Distribution** — бесплатно раздаёт сборки тестерам, но для подписи iOS-сборки всё равно нужен Apple Developer.

Для быстрого теста без магазинов удобнее всего: **веб на Firebase Hosting** (доступ по ссылке с любого устройства) и при необходимости **Firebase App Distribution** для Android-сборки.

---

## Итог


| Платформа | Сервис                          | Условие                             |
| --------- | ------------------------------- | ----------------------------------- |
| Web       | Firebase Hosting                | Бесплатно в квотах, уже в проекте   |
| Web       | Vercel / Netlify / GitHub Pages | Бесплатные планы                    |
| Android   | Firebase App Distribution       | Бесплатно, рассылка ссылки тестерам |
| Android   | Google Play Internal testing    | Бесплатно                           |
| iOS       | TestFlight / App Distribution   | Нужен Apple Developer 99 USD/год    |


План внедрения: добавить `hosting` в [firebase.json](firebase.json), выполнить `flutter build web` и `firebase deploy --only hosting`.