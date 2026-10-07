// One job in full: save and track it, quick fit, AI fit report,
// cover letter, interview practice, apply.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models.dart';
import '../services/ai_service.dart';
import '../services/matcher.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'interview_screen.dart';
import 'stage_picker.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;
  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  FitReport? _report;
  bool _reportBusy = false;
  bool _letterBusy = false;

  Job get job => widget.job;

  // Redraw this screen whenever the saved jobs or the resume change.
  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    appState.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    appState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _openInterview() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InterviewScreen(role: job.title, job: job),
      ),
    );
  }

  Future<void> _getReport() async {
    setState(() => _reportBusy = true);
    try {
      final report = await AiService.fitReport(appState.resume, job);
      if (mounted) setState(() => _report = report);
    } on AiException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (_) {
      if (mounted) showMessage(context, 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _reportBusy = false);
    }
  }

  Future<void> _writeLetter() async {
    setState(() => _letterBusy = true);
    try {
      final letter = await AiService.coverLetter(appState.resume, job);
      if (mounted) _showLetter(letter);
    } on AiException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (_) {
      if (mounted) showMessage(context, 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _letterBusy = false);
    }
  }

  void _showLetter(String letter) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sheet,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          builder: (BuildContext _, ScrollController controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
              children: <Widget>[
                Text('Cover letter', style: T.display(22)),
                const SizedBox(height: 4),
                Text(
                  'Read it and change anything that does not sound like you.',
                  style: T.body(14, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                SelectableText(letter, style: T.body(15.5)),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Copy letter',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: letter));
                    Navigator.of(sheetContext).pop();
                    showMessage(context, 'Letter copied.');
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _useSummary(String summary) {
    final old = appState.resume.summary;
    final updated = appState.resume.copy()..summary = summary;
    appState.setResume(updated);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Summary updated in your resume.'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.marker,
            onPressed: () {
              final back = appState.resume.copy()..summary = old;
              appState.setResume(back);
            },
          ),
        ),
      );
  }

  Future<void> _apply() async {
    final uri = Uri.tryParse(job.url);
    bool opened = false;
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (opened) {
      // Keep the job in "My applications" so it is easy to find again.
      if (appState.trackedFor(job.id) == null) {
        await appState.track(job);
      }
    } else if (mounted) {
      showMessage(context, 'Could not open the job page.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final resume = appState.resume;
    final fit = localFit(resume, job);
    final report = _report;
    final tracked = appState.trackedFor(job.id);
    final place = <String>[job.company, job.location]
        .where((x) => x.isNotEmpty)
        .join(', ');

    return Scaffold(
      appBar: plainAppBar(''),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: PrimaryButton(
          label: job.url.isEmpty ? 'Sample job, no apply link' : 'Apply on the job site',
          onPressed: job.url.isEmpty ? null : _apply,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: <Widget>[
          Text(job.title, style: T.display(28)),
          if (place.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(place, style: T.body(16)),
            ),
          if (job.salary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(job.salary, style: T.body(15)),
            ),
          if (job.posted.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(job.posted, style: T.body(14, color: AppColors.muted)),
            ),

          const SizedBox(height: 16),
          if (tracked == null)
            Align(
              alignment: Alignment.centerLeft,
              child: QuietButton(
                label: 'Save this job',
                icon: Icons.bookmark_border,
                onPressed: () {
                  appState.track(job);
                  showMessage(context, 'Saved to your applications.');
                },
              ),
            )
          else
            Sheet(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (tracked.stage == Stage.closed)
                    Text('Closed', style: T.pen(21))
                  else
                    Text(
                      'In your applications: ${tracked.stage}',
                      style: T.body(15, color: AppColors.ink, weight: FontWeight.w700),
                    ),
                  const SizedBox(height: 8),
                  StageBar(stage: tracked.stage),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 18,
                    children: <Widget>[
                      if (tracked.stage == Stage.saved)
                        TextButton(
                          onPressed: () =>
                              appState.track(job, stage: Stage.applied),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('I have applied'),
                        ),
                      TextButton(
                        onPressed: () => showStagePicker(context, job),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Change status'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SectionTitle('How you fit'),
          if (resume.isEmpty)
            Text(
              'Build your resume first. Then this page shows your fit '
              'score, your gaps, and a cover letter for this job.',
              style: T.body(15),
            )
          else ...<Widget>[
            Sheet(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${report?.score ?? fit.score}% fit',
                    style: T.display(24),
                  ),
                  const SizedBox(height: 8),
                  FitBar(score: report?.score ?? fit.score),
                  if (fit.matched.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    Text('On your resume', style: T.body(13.5, color: AppColors.muted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: fit.matched
                          .map((s) => Marked(prettySkill(s)))
                          .toList(),
                    ),
                  ],
                  if (fit.missing.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    Text('Asked for, not on your resume', style: T.body(13.5, color: AppColors.muted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: fit.missing
                          .map((s) => SkillChip(prettySkill(s)))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (report != null) ...<Widget>[
              Sheet(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (report.strengths.isNotEmpty) ...<Widget>[
                      Text('Why you fit', style: T.display(16)),
                      const SizedBox(height: 10),
                      for (final s in report.strengths) TickLine(s),
                      const SizedBox(height: 8),
                    ],
                    if (report.gaps.isNotEmpty) ...<Widget>[
                      Text('What is missing', style: T.display(16)),
                      const SizedBox(height: 10),
                      for (final g in report.gaps) PenNote(g),
                      const SizedBox(height: 8),
                    ],
                    if (report.advice.isNotEmpty) ...<Widget>[
                      Text('Before you apply', style: T.display(16)),
                      const SizedBox(height: 6),
                      Text(report.advice, style: T.body(15)),
                    ],
                    if (report.tailoredSummary.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 18),
                      Text('A summary written for this job', style: T.display(16)),
                      const SizedBox(height: 6),
                      Text(report.tailoredSummary, style: T.body(15)),
                      const SizedBox(height: 12),
                      QuietButton(
                        label: 'Use this summary in my resume',
                        onPressed: () => _useSummary(report.tailoredSummary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (!Config.hasAi) ...<Widget>[
              const DemoBanner(
                'Demo mode. The report and letter below are basic versions. '
                'Add your Gemini key for the full AI ones.',
              ),
              const SizedBox(height: 14),
            ],

            if (report == null)
              QuietButton(
                label: 'Get my full fit report',
                busyLabel: 'Comparing you with this job',
                busy: _reportBusy,
                wide: true,
                onPressed: _getReport,
              ),
            if (report == null) const SizedBox(height: 10),
            QuietButton(
              label: 'Write a cover letter',
              busyLabel: 'Writing your letter',
              busy: _letterBusy,
              wide: true,
              onPressed: _writeLetter,
            ),
            const SizedBox(height: 10),
            QuietButton(
              label: 'Practise the interview for this job',
              wide: true,
              onPressed: _openInterview,
            ),
          ],

          const SectionTitle('About the job'),
          Text(job.description, style: T.body(15.5)),
          if (job.url.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'This is a short preview. The full advert opens when you apply.',
                style: T.body(13.5, color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}
