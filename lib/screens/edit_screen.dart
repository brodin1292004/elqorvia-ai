// Edit the resume by hand. Changes are made on a copy and only saved
// when the user taps "Save changes".

import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late final Resume _draft = appState.resume.copy();

  Future<void> _save() async {
    // copy() also throws away entries the user left completely blank.
    final cleaned = _draft.copy();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await appState.setResume(cleaned);
    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Changes saved.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: plainAppBar('Edit resume'),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: PrimaryButton(label: 'Save changes', onPressed: _save),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: <Widget>[
          _field('Full name', _draft.name, (v) => _draft.name = v),
          _field('Job title you want', _draft.headline, (v) => _draft.headline = v),
          _field('Email', _draft.email, (v) => _draft.email = v,
              keyboard: TextInputType.emailAddress),
          _field('Phone', _draft.phone, (v) => _draft.phone = v,
              keyboard: TextInputType.phone),
          _field('City', _draft.location, (v) => _draft.location = v),
          _field('Summary', _draft.summary, (v) => _draft.summary = v, lines: 4),
          _field(
            'Skills, separated by commas',
            _draft.skills.join(', '),
            (v) => _draft.skills = v
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
            lines: 3,
          ),
          ..._entrySection('Experience', _draft.experience, 'Role', 'Company'),
          ..._entrySection('Projects', _draft.projects, 'Project name', 'Tools used'),
          ..._entrySection('Education', _draft.education, 'Degree', 'College or school'),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    int lines = 1,
    TextInputType? keyboard,
    Key? key,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: key,
        initialValue: value,
        onChanged: onChanged,
        minLines: lines,
        maxLines: lines == 1 ? 1 : lines + 4,
        keyboardType: lines == 1 ? keyboard : TextInputType.multiline,
        style: T.body(15.5),
        decoration: fieldDecoration(label: label),
      ),
    );
  }

  List<Widget> _entrySection(
    String title,
    List<Entry> entries,
    String titleLabel,
    String subtitleLabel,
  ) {
    return <Widget>[
      SectionTitle(title),
      const SizedBox(height: 6),
      for (final entry in entries)
        Padding(
          // The key ties each box to its entry, so deleting one entry
          // does not mix up the text typed in the others.
          key: ObjectKey(entry),
          padding: const EdgeInsets.only(bottom: 14),
          child: Sheet(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
            child: Column(
              children: <Widget>[
                _field(titleLabel, entry.title, (v) => entry.title = v),
                _field(subtitleLabel, entry.subtitle, (v) => entry.subtitle = v),
                _field('Dates, like 2023 to 2025', entry.period,
                    (v) => entry.period = v),
                _field(
                  'Points, one per line',
                  entry.points.join('\n'),
                  (v) => entry.points = v
                      .split('\n')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList(),
                  lines: 3,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => entries.remove(entry)),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.redPen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: QuietButton(
          label: 'Add to ${title.toLowerCase()}',
          icon: Icons.add,
          onPressed: () => setState(() => entries.add(Entry())),
        ),
      ),
    ];
  }
}
