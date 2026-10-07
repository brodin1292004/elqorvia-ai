// Elqorvia AI: build a resume by talking, see which jobs fit it,
// track your applications and practise the interview.
//
// How the app is organised:
//   main.dart              starts the app and holds the bottom tabs
//   config.dart            your API keys
//   theme.dart             colours and fonts
//   models.dart            Resume, Job and the AI result shapes
//   state.dart             keeps and saves the resume
//   widgets.dart           shared building blocks
//   services/              AI, job search, matching, PDF
//   screens/               one file per screen

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/jobs_screen.dart';
import 'screens/resume_screen.dart';
import 'screens/tracker_screen.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appState.load(); // read the saved resume before showing anything
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elqorvia AI',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const Shell(),
    );
  }
}

/// The frame around the four main tabs.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  void _goTo(int index) {
    setState(() => _tab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: <Widget>[
            HomeScreen(onGoTo: _goTo),
            const ResumeScreen(),
            const JobsScreen(),
            TrackerScreen(onGoTo: _goTo),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _goTo,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Resume',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Applications',
          ),
        ],
      ),
    );
  }
}
