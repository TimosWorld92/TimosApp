import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const Duration kDuration = Duration(hours: 2, minutes: 35);
const String kEndKey = 'waesche.end';
const int kNotificationId = 1;

const Color kBg = Color(0xFF0F1115);
const Color kCard = Color(0xFF1A1D24);
const Color kText = Color(0xFFF2F4F8);
const Color kMuted = Color(0xFF8B93A7);
const Color kAccent = Color(0xFF4F8CFF);
const Color kDone = Color(0xFF38C172);

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  await _notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  runApp(const TimosApp());
}

Future<void> _scheduleNotification(DateTime end) async {
  final android = _notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await android?.requestNotificationsPermission();
  final exact = await android?.requestExactAlarmsPermission();

  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'waesche_timer',
      'Wäsche-Timer',
      channelDescription: 'Erinnerung, wenn die Wäsche fertig ist',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      enableVibration: true,
    ),
  );

  await _notifications.zonedSchedule(
    id: kNotificationId,
    title: 'Wäsche fertig',
    body: 'Die 2:35 Stunden sind um.',
    scheduledDate: tz.TZDateTime.from(end, tz.local),
    notificationDetails: details,
    androidScheduleMode: exact == false
        ? AndroidScheduleMode.inexactAllowWhileIdle
        : AndroidScheduleMode.exactAllowWhileIdle,
  );
}

class TimosApp extends StatelessWidget {
  const TimosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimosApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(
          primary: kAccent,
          surface: kCard,
        ),
      ),
      home: const TimerPage(),
    );
  }
}

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  Timer? _ticker;
  DateTime? _end;

  bool get _running =>
      _end != null && _end!.isAfter(DateTime.now());
  bool get _done => _end != null && !_running;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restore();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _syncTicker();
    }
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(kEndKey);
    if (!mounted) return;
    setState(() {
      _end = millis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(millis);
    });
    _syncTicker();
  }

  void _syncTicker() {
    _ticker?.cancel();
    if (_running) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    }
  }

  Future<void> _start() async {
    final end = DateTime.now().add(kDuration);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kEndKey, end.millisecondsSinceEpoch);
    if (!mounted) return;
    setState(() => _end = end);
    _syncTicker();
    await _scheduleNotification(end);
  }

  Future<void> _reset() async {
    _ticker?.cancel();
    await _notifications.cancel(id: kNotificationId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kEndKey);
    if (!mounted) return;
    setState(() => _end = null);
  }

  String _format(Duration d) {
    final total = d.isNegative ? 0 : d.inSeconds;
    final h = (total ~/ 3600).toString().padLeft(2, '0');
    final m = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _end == null
        ? kDuration
        : _end!.difference(DateTime.now());
    final label = _end == null
        ? 'Wäsche · 2:35 Std.'
        : (_done ? 'Wäsche fertig' : 'Wäsche läuft');
    final value = _done ? '00:00:00' : _format(remaining);
    final buttonText = _end == null
        ? 'Wäsche starten'
        : (_done ? 'Zurücksetzen' : 'Abbrechen');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'TimosApp',
                  style: TextStyle(
                    color: kText,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 340),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: kMuted,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              value,
                              style: TextStyle(
                                color: _done ? kDone : kText,
                                fontSize: 56,
                                fontWeight: FontWeight.w700,
                                height: 1,
                                letterSpacing: 1,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 340),
                          child: FilledButton(
                            onPressed: _end == null ? _start : _reset,
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  _running ? const Color(0xFF2A2F3A) : kAccent,
                              foregroundColor: kText,
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              buttonText,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF232733))),
              ),
              child: const Padding(
                padding: EdgeInsets.only(top: 14, bottom: 18),
                child: Text(
                  'Wäsche',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
