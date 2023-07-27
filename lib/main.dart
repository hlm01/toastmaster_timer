import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock/wakelock.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Timer',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final options = [
    TimerSettings(red: 7.0, yellow: 6.0, green: 5.0, name: "Prepared Speech"),
    TimerSettings(red: 2.0, yellow: 1.5, green: 1.0, name: "Table Topic"),
    TimerSettings(red: 3.0, yellow: 2.5, green: 2.0, name: "Evaluation"),
    TimerSettings(red: 6.0, yellow: 5.0, green: 4.0, name: "Ice Breaking"),
  ];

  TimerSettings? _selected;

  String minutesToString(double minutes) {
    return "${minutes.truncate()}:${(minutes % 1 * 60).toInt().toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Timer"),
        ),
        body: Column(
          children: options
              .map((e) => RadioListTile(
                  title: Text(e.name),
                  subtitle: Text(
                      "Green: ${minutesToString(e.green)}, Yellow: ${minutesToString(e.yellow)}, Red: ${minutesToString(e.red)}"),
                  value: e,
                  groupValue: _selected,
                  onChanged: (x) => setState(() {
                        _selected = e;
                      })))
              .toList(),
        ),
        floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.play_arrow),
            onPressed: () {
              if (_selected != null) {
                Wakelock.enable();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TimerDisplay(settings: _selected!)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No Timer Selected")));
              }
            }));
  }
}

class TimerSettings {
  final double red, yellow, green;
  final String name;

  TimerSettings(
      {required this.red,
      required this.yellow,
      required this.green,
      required this.name});
}

class TimerDisplay extends StatefulWidget {
  final TimerSettings settings;

  const TimerDisplay({Key? key, required this.settings}) : super(key: key);

  @override
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay> {
  Duration currentTime = const Duration();
  late Timer timer;
  bool stopped = false;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!stopped) {
        setState(() {
          currentTime += const Duration(seconds: 1);
        });
      }
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
  }

  @override
  Widget build(BuildContext context) {
    var color = Colors.black;
    if (currentTime.inSeconds >= widget.settings.red * 60) {
      color = Colors.red;
    } else if (currentTime.inSeconds >= widget.settings.yellow * 60) {
      color = Colors.yellow[700]!;
    } else if (currentTime.inSeconds >= widget.settings.green * 60) {
      color = Colors.green;
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            color: Colors.white,
            icon: Visibility(visible: stopped, child: const Icon(Icons.close)),
            onPressed: () {
              if (stopped) {
                Navigator.pop(context);
              }
            },
          )),
      backgroundColor: color,
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Visibility(
                  visible: stopped,
                  child: Text(
                    '${currentTime.inMinutes.toString().padLeft(2, '0')}:${currentTime.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  IconButton(
                    iconSize: 36,
                    onPressed: () {
                      setState(() {
                        stopped = !stopped;
                      });
                    },
                    padding: const EdgeInsets.all(30),
                    color: Colors.white,
                    icon: stopped
                        ? const Icon(Icons.play_arrow)
                        : const Icon(Icons.pause),
                  ),
                  if (stopped)
                    IconButton(
                      iconSize: 36,
                      onPressed: () {
                        setState(() {
                          stopped = false;
                          currentTime = const Duration();
                        });
                      },
                      padding: const EdgeInsets.all(30),
                      color: Colors.white,
                      icon: const Icon(Icons.replay),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    Wakelock.disable();

    super.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }
}
