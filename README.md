# مەسروف (Masruf)

Personal daily expense tracker in Kurdish (Sorani), offline-first, Flutter.

## Features
- Expenses and income (salary + other sources), multi-currency IQD / USD with a configurable rate.
- Categories and income sources are fully editable in the app (icon, colour, monthly budget).
- Recurring monthly items (rent, loans/installments with start + end month, salary).
  Each month they appear as "ماوە بدرێت" on the home screen until recorded.
- Analytics: donut by category, budget progress, 6-month income vs expense bars.
- PIN lock, light/dark theme, CSV export.

## Run
```
flutter pub get
flutter run                          # Android / iOS
flutter run --dart-define=DEMO=true  # fills an empty DB with sample data
```

## Screenshots (no device needed)
Renders the real app with demo data into `build/screenshots/*.png`:
```
flutter test test/screenshots_test.dart --update-goldens
```

## Structure
```
lib/core      strings (Kurdish), theme, formatting, icon map
lib/data      models, sqflite DB + seed, repository, CSV export, demo seed
lib/state     Riverpod providers (settings, month, summaries, due items)
lib/ui        shell + screens: home, analytics, recurring, settings, tx sheet, lock
```
