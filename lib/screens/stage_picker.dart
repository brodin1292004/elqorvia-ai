// The small sheet that slides up to change where an application stands.

import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';

const Map<String, String> _stageHelp = <String, String>{
  Stage.saved: 'Interested, not applied yet',
  Stage.applied: 'Application sent',
  Stage.interview: 'Called for an interview',
  Stage.offer: 'They made an offer',
  Stage.closed: 'It did not work out',
};

void showStagePicker(BuildContext context, Job job) {
  final current = appState.trackedFor(job.id);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.sheet,
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Where does this application stand?', style: T.display(20)),
              const SizedBox(height: 10),
              for (final stage in Stage.all)
                InkWell(
                  onTap: () {
                    appState.track(job, stage: stage);
                    Navigator.of(sheetContext).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                stage,
                                style: T.body(16, color: AppColors.ink, weight: FontWeight.w600),
                              ),
                              Text(
                                _stageHelp[stage] ?? '',
                                style: T.body(13.5, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        if (current != null && current.stage == stage)
                          const Icon(Icons.check, color: AppColors.tick),
                      ],
                    ),
                  ),
                ),
              if (current != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      appState.untrack(job.id);
                      Navigator.of(sheetContext).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.redPen,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Remove from my applications'),
                  ),
                ),
            ],
          ),
          ),
        ),
      );
    },
  );
}
