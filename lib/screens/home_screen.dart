// Tab 1: Home.
// New user: explains the idea and invites them to start.
// Returning user: resume preview, recruiter scan, and a way into jobs.

import 'package:flutter/material.dart';

import '../config.dart';
import '../models.dart';
import '../services/ai_service.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'builder_screen.dart';
import 'interview_screen.dart';

class HomeScreen extends StatefulWidget {
  /// Lets Home switch to another tab (1 = Resume, 2 = Jobs, 3 = Applications).
  final ValueChanged<int> onGoTo;
  const HomeScreen({super.key, required this.onGoTo});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _scanning = false;

  Future<void> _scan() async {
    setState(() => _scanning = true);
    try {
      final result = await AiService.scan(appState.resume);
      appState.setScan(result);
    } on AiException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (_) {
      if (mounted) showMessage(context, 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _openInterview(Resume resume) {
    final role = resume.headline.isEmpty ? 'your next job' : resume.headline;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => InterviewScreen(role: role)),
    );
  }

  void _openBuilder() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BuilderScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (BuildContext context, Widget? _) {
        final resume = appState.resume;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Marked('Elqorvia AI', style: T.display(20)),
            ),
            const SizedBox(height: 28),
            if (resume.isEmpty) ..._welcome() else ..._dashboard(resume),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------
  // First time: no resume yet
  // ---------------------------------------------------------------
  List<Widget> _welcome() {
    return <Widget>[
      Text('Tell it like you would tell a friend.', style: T.display(32)),
      const SizedBox(height: 12),
      Text(
        'Type your studies, projects and work in your own words. '
        'Elqorvia turns them into a clean one page resume, then shows '
        'which jobs fit it.',
        style: T.body(16),
      ),
      const SizedBox(height: 24),
      Sheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('You type', style: T.body(13, color: AppColors.muted)),
            const SizedBox(height: 4),
            Text(
              'i finished bca this year. made a food order app in flutter '
              'for my final project, did everything myself',
              style: T.body(15),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: AppColors.line),
            ),
            Text('Your resume says', style: T.body(13, color: AppColors.muted)),
            const SizedBox(height: 6),
            Text(
              'Designed and built a food ordering app in Flutter as a '
              'solo final year project.',
              style: T.body(15, color: AppColors.ink, weight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[Marked('Flutter'), Marked('App design')],
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      PrimaryButton(label: 'Write my resume', onPressed: _openBuilder),
      if (!Config.hasAi) ...<Widget>[
        const SizedBox(height: 16),
        const DemoBanner(
          'Demo mode. The AI gives sample answers until you add your '
          'Gemini key in lib/config.dart.',
        ),
      ],
    ];
  }

  // ---------------------------------------------------------------
  // Returning: resume exists
  // ---------------------------------------------------------------
  List<Widget> _dashboard(Resume resume) {
    final scan = appState.scan;
    final greeting =
        resume.firstName.isEmpty ? 'Welcome back' : 'Hi ${resume.firstName}';

    return <Widget>[
      Text(greeting, style: T.display(30)),
      const SizedBox(height: 4),
      Text('Here is where your resume stands today.', style: T.body(16)),
      const SizedBox(height: 20),

      // Small preview of the resume. Tap to open the Resume tab.
      GestureDetector(
        onTap: () => widget.onGoTo(1),
        child: Sheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(resume.name, style: T.display(20)),
              if (resume.headline.isNotEmpty)
                Text(
                  resume.headline,
                  style: T.body(15, color: AppColors.ink, weight: FontWeight.w600),
                ),
              if (resume.summary.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  resume.summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: T.body(14.5),
                ),
              ],
              if (resume.skills.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: resume.skills
                      .take(6)
                      .map((s) => SkillChip(s))
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Open full resume',
                style: T.body(14, color: AppColors.ink, weight: FontWeight.w600)
                    .copyWith(decoration: TextDecoration.underline),
              ),
            ],
          ),
        ),
      ),

      const SectionTitle('Recruiter scan'),
      Text(
        'A recruiter gives a resume about six seconds. See what they '
        'would notice in yours.',
        style: T.body(15),
      ),
      const SizedBox(height: 14),
      if (scan != null) ...<Widget>[
        Sheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${scan.score} out of 100', style: T.display(22)),
              const SizedBox(height: 8),
              FitBar(score: scan.score),
              const SizedBox(height: 14),
              Text(scan.impression, style: T.body(15)),
              if (scan.fixes.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                for (final fix in scan.fixes) PenNote(fix),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
      QuietButton(
        label: scan == null ? 'Scan my resume' : 'Scan again',
        busyLabel: 'Reading your resume',
        busy: _scanning,
        wide: true,
        onPressed: _scan,
      ),

      const SectionTitle('Jobs that fit'),
      Text(
        'Every job gets a fit score against your resume, with the '
        'skills you already have marked in yellow.',
        style: T.body(15),
      ),
      const SizedBox(height: 14),
      PrimaryButton(
        label: 'Find jobs for this resume',
        onPressed: () => widget.onGoTo(2),
      ),
      if (appState.tracked.isNotEmpty) ...<Widget>[
        const SizedBox(height: 12),
        QuietButton(
          label: appState.tracked.length == 1
              ? 'See my 1 saved job'
              : 'See my ${appState.tracked.length} saved jobs',
          icon: Icons.bookmark_border,
          wide: true,
          onPressed: () => widget.onGoTo(3),
        ),
      ],

      const SectionTitle('Interview practice'),
      Text(
        'Five questions written for your resume. Answer each one and '
        'get honest feedback before the real thing.',
        style: T.body(15),
      ),
      const SizedBox(height: 14),
      QuietButton(
        label: 'Practise an interview',
        wide: true,
        onPressed: () => _openInterview(resume),
      ),

      const SectionTitle('Keep it up to date'),
      const SizedBox(height: 6),
      QuietButton(
        label: 'Add more to my resume',
        icon: Icons.edit_note,
        wide: true,
        onPressed: _openBuilder,
      ),
    ];
  }
}
