// Tab 3: search jobs. Every job is scored against the resume and the
// best fits are listed first.

import 'package:flutter/material.dart';

import '../config.dart';
import '../models.dart';
import '../services/ai_service.dart';
import '../services/job_service.dart';
import '../services/matcher.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'job_detail_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final TextEditingController _what = TextEditingController();
  final TextEditingController _where = TextEditingController();

  List<Job>? _jobs; // null = nothing searched yet
  bool _loading = false;
  String? _error;

  List<String>? _aiRoles; // role ideas from the AI, once asked
  bool _suggesting = false;

  @override
  void dispose() {
    _what.dispose();
    _where.dispose();
    super.dispose();
  }

  Future<void> _search([String? role]) async {
    if (role != null) _what.text = role;
    final what = _what.text.trim();
    if (what.isEmpty) {
      showMessage(context, 'Type a job title first, like Flutter developer.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final found = await JobService.search(what, _where.text.trim());
      final resume = appState.resume;
      if (!resume.isEmpty) {
        // Work out each score once, then put the best fits first.
        final scores = <String, int>{
          for (final job in found) job.id: localFit(resume, job).score,
        };
        found.sort((a, b) => (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0));
      }
      if (mounted) setState(() => _jobs = found);
    } on JobException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not load jobs. Try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _suggestRoles() async {
    setState(() => _suggesting = true);
    try {
      final roles = await AiService.suggestRoles(appState.resume);
      if (mounted) setState(() => _aiRoles = roles);
    } on AiException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (_) {
      if (mounted) showMessage(context, 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _suggesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (BuildContext context, Widget? _) {
        final resume = appState.resume;
        final roles = _aiRoles ?? localRoles(resume);
        final jobs = _jobs;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          children: <Widget>[
            Text('Jobs that fit', style: T.display(28)),
            const SizedBox(height: 14),
            TextField(
              controller: _what,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              style: T.body(16),
              decoration: fieldDecoration(label: 'Job title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _where,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              style: T.body(16),
              decoration: fieldDecoration(label: 'City (optional)'),
            ),
            const SizedBox(height: 14),

            // Role ideas taken from the resume.
            if (!resume.isEmpty) ...<Widget>[
              Text('Roles your resume points to', style: T.body(14, color: AppColors.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final role in roles)
                    ActionChip(
                      label: Text(role, style: T.body(14, color: AppColors.ink, weight: FontWeight.w600)),
                      backgroundColor: AppColors.sheet,
                      side: const BorderSide(color: AppColors.line),
                      onPressed: () => _search(role),
                    ),
                ],
              ),
              if (_aiRoles == null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _suggesting ? null : _suggestRoles,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(_suggesting
                        ? 'Reading your resume'
                        : 'Ask the AI for better role ideas'),
                  ),
                ),
              const SizedBox(height: 8),
            ],

            PrimaryButton(
              label: 'Search jobs',
              busyLabel: 'Searching',
              busy: _loading,
              onPressed: () => _search(),
            ),
            const SizedBox(height: 18),

            if (!Config.hasJobs) ...<Widget>[
              const DemoBanner(
                'Demo mode. These are sample jobs. Add your Adzuna keys in '
                'lib/config.dart to search real ones.',
              ),
              const SizedBox(height: 14),
            ],

            if (resume.isEmpty && jobs != null && jobs.isNotEmpty) ...<Widget>[
              Text(
                'Build your resume to see how well each job fits you.',
                style: T.body(14.5, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
            ],

            if (_error != null)
              Text(_error!, style: T.body(15, color: AppColors.redPen)),

            if (jobs == null && _error == null && !_loading)
              Text(
                resume.isEmpty
                    ? 'Type a job title and search.'
                    : 'Tap a role above, or type your own and search.',
                style: T.body(15, color: AppColors.muted),
              ),

            if (jobs != null && jobs.isEmpty)
              Text(
                'No jobs found for that search. Try a shorter title, or '
                'clear the city.',
                style: T.body(15),
              ),

            if (jobs != null)
              for (final job in jobs) _JobCard(job: job, resume: resume),

            if (Config.hasJobs && jobs != null && jobs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Jobs by Adzuna', style: T.body(13, color: AppColors.muted)),
              ),
          ],
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  final Resume resume;
  const _JobCard({required this.job, required this.resume});

  @override
  Widget build(BuildContext context) {
    final fit = localFit(resume, job);
    final tracked = appState.trackedFor(job.id);
    final place = <String>[job.company, job.location]
        .where((x) => x.isNotEmpty)
        .join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => JobDetailScreen(job: job),
            ),
          );
        },
        child: Sheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(job.title, style: T.display(18)),
              if (place.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(place, style: T.body(14, color: AppColors.muted)),
                ),
              if (job.salary.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(job.salary, style: T.body(14)),
                ),
              if (!resume.isEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(child: FitBar(score: fit.score)),
                    const SizedBox(width: 12),
                    Text(
                      '${fit.score}% fit',
                      style: T.body(14, color: AppColors.ink, weight: FontWeight.w700),
                    ),
                  ],
                ),
                if (fit.matched.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: fit.matched
                        .take(4)
                        .map((s) => Marked(prettySkill(s)))
                        .toList(),
                  ),
                ],
              ],
              if (tracked != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.bookmark, size: 16, color: AppColors.ink),
                      const SizedBox(width: 6),
                      Text(
                        'In your applications: ${tracked.stage}',
                        style: T.body(13.5, color: AppColors.ink, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
