# TimosApp

Wäsche-Timer als Flutter-App für Android. Startet einen Timer über 2:35 Stunden
und schickt eine Benachrichtigung, wenn die Wäsche fertig ist.

## Funktionen

- Timer über 2:35 Std. mit Start / Abbrechen / Zurücksetzen
- Läuft weiter, auch wenn die App geschlossen ist (Endzeit wird gespeichert)
- Benachrichtigung zum Timer-Ende über `flutter_local_notifications`
- Eigenes App-Icon

## Projektstruktur

| Pfad | Zweck |
| --- | --- |
| `lib/main.dart` | Die App (UI, Timer-Logik, Benachrichtigungen) |
| `android/` | Android-Konfiguration (Manifest, Gradle, Icons) |
| `test/widget_test.dart` | Widget-Test |
| `icon-192.png`, `icon-512.png` | Quelldateien für das App-Icon |

## Entwicklung

```bash
flutter pub get
flutter analyze
flutter test
flutter run            # auf angeschlossenem Gerät/Emulator
```

## APK bauen

```bash
flutter build apk --release
```

Die fertige Datei liegt danach unter:

```
build/app/outputs/flutter-apk/app-release.apk
```

## APK aufs Handy installieren

**Variante A – per USB (adb):**

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Variante B – Datei übertragen:**

1. `app-release.apk` auf das Handy kopieren (USB, Cloud, Messenger, …).
2. Am Handy die Datei antippen.
3. Android fragt nach der Erlaubnis, Apps aus unbekannten Quellen zu
   installieren – für den verwendeten Dateimanager/Browser erlauben.
4. Installation bestätigen.

> Hinweis: Beim ersten Start nach der Benachrichtigungs-Berechtigung fragen
> lassen und zusätzlich ggf. „Alarme und Erinnerungen" erlauben, damit die
> Meldung pünktlich erscheint.

## Hinweis zur Signatur

Der Release-Build ist aktuell mit dem **Debug-Schlüssel** signiert (siehe
`android/app/build.gradle.kts`). Für eine Veröffentlichung im Play Store müsste
ein eigener Release-Keystore eingerichtet werden.
