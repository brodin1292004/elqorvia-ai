// The "tell your story" screen. The user types rough notes and the AI
// turns them into a structured resume.

import 'package:flutter/material.dart';

import '../config.dart';
import '../services/ai_service.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  final TextEditingController _notes = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _build() async {
    final notes = _notes.text.trim();
    if (Config.hasAi && notes.length < 20) {
      showMessage(context, 'Write a little more first. Two or three lines is enough.');
      return;
    }
    FocusScope.of(context).unfocus();

    // Grab these before the "await", because the screen may close after it.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _busy = true);
    try {
      final result = await AiService.buildFromNotes(notes, appState.resume);
      await appState.setResume(result);
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(Config.hasAi
            ? 'Resume built. Check every detail before you send it.'
            : 'Sample resume loaded. Add your Gemini key to build your own.'),
      ));
    } on AiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResume = !appState.resume.isEmpty;
    return Scaffold(
      appBar: plainAppBar(hasResume ? 'Add to your resume' : 'Tell your story'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: <Widget>[
            Text(
              hasResume
                  ? 'Type what is new: a project, a course, a job. It gets merged into your resume.'
                  : 'No forms. Write it the way you would say it. Spelling and order do not matter.',
              style: T.body(16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              minLines: 9,
              maxLines: 16,
              textCapitalization: TextCapitalization.sentences,
              style: T.body(16),
              decoration: fieldDecoration(
                hint: 'My name is ...\n'
                    'I studied ... at ... and finished in ...\n'
                    'I worked at ... as ...\n'
                    'I made a project that ...\n'
                    'I am good at ...\n'
                    'Phone, email, city ...',
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Worth mentioning: your name and contact details, studies, '
              'any work or internship, projects, tools you know, and '
              'numbers wherever you have them.',
              style: T.body(14, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            if (!Config.hasAi) ...<Widget>[
              const DemoBanner(
                'Demo mode. This button loads a sample resume. Add your '
                'Gemini key in lib/config.dart to build from your notes.',
              ),
              const SizedBox(height: 14),
            ],
            PrimaryButton(
              label: hasResume ? 'Update my resume' : 'Build my resume',
              busyLabel: 'Writing your resume',
              busy: _busy,
              onPressed: _build,
            ),
          ],
        ),
      ),
    );
  }
}
