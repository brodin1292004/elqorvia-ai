// Tab 4: Applications. Every saved job and how far it has got.

import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'interview_screen.dart';
import 'job_detail_screen.dart';
import 'stage_picker.dart';

class TrackerScreen extends StatefulWidget {
  /// Lets this tab switch to another one (2 = Jobs).
  final ValueChanged<int> onGoTo;
  const TrackerScreen({super.key, required this.onGoTo});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  String? _filter; // null = show every stage

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (BuildContext context, Widget? _) {
        final all = appState.tracked;
        if (all.isEmpty) return _empty();

        final shown = _filter == null
            ? all
            : all.where((t) => t.stage == _filter).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          children: <Widget>[
            Text('My applications', style: T.display(28)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _filterChip('All', null, all.length),
                for (final stage in Stage.all)
                  if (all.any((t) => t.stage == stage))
                    _filterChip(
                      stage,
                      stage,
                      all.where((t) => t.stage == stage).length,
                    ),
              ],
            ),
            const SizedBox(height: 16),
            if (shown.isEmpty)
              Text('Nothing at this stage.', style: T.body(15, color: AppColors.muted)),
            for (final item in shown) _TrackedCard(item: item),
          ],
        );
      },
    );
  }

  Widget _filterChip(String label, String? stage, int count) {
    final selected = _filter == stage;
    return ActionChip(
      label: Text(
        '$label $count',
        style: T.body(14, color: AppColors.ink, weight: FontWeight.w600),
      ),
      backgroundColor: selected ? AppColors.marker : AppColors.sheet,
      side: BorderSide(
        color: selected ? AppColors.markerEdge : AppColors.line,
      ),
      onPressed: () => setState(() => _filter = stage),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('My applications', style: T.display(28)),
          const SizedBox(height: 10),
          Text(
            'Jobs you save appear here, so you always know which ones '
            'you applied to and what happened next.',
            style: T.body(16),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Find jobs to save',
            onPressed: () => widget.onGoTo(2),
          ),
        ],
      ),
    );
  }
}

class _TrackedCard extends StatelessWidget {
  final TrackedJob item;
  const _TrackedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final job = item.job;
    final closed = item.stage == Stage.closed;
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
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                job.title,
                style: T.display(18, color: closed ? AppColors.muted : AppColors.ink),
              ),
              if (place.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(place, style: T.body(14, color: AppColors.muted)),
                ),
              const SizedBox(height: 12),
              StageBar(stage: item.stage),
              const SizedBox(height: 8),
              if (closed)
                Text('Closed', style: T.pen(21))
              else
                Text(
                  item.stage,
                  style: T.body(14.5, color: AppColors.ink, weight: FontWeight.w700),
                ),
              Text(
                'Updated ${agoLabel(item.updatedAt)}',
                style: T.body(13, color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 18,
                children: <Widget>[
                  TextButton(
                    onPressed: () => showStagePicker(context, job),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Change status'),
                  ),
                  if (!closed)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                InterviewScreen(role: job.title, job: job),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Practise interview'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
