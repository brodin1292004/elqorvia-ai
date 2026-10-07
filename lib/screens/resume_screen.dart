// Tab 2: the resume as a sheet of paper, with edit and PDF actions.

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models.dart';
import '../services/pdf_service.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'builder_screen.dart';
import 'edit_screen.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  bool _exporting = false;

  void _openBuilder() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BuilderScreen()),
    );
  }

  void _openEditor() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const EditScreen()),
    );
  }

  /// share = false opens the print / save as PDF screen.
  /// share = true opens the share sheet (WhatsApp, email, Drive...).
  Future<void> _exportPdf({required bool share}) async {
    setState(() => _exporting = true);
    try {
      final resume = appState.resume;
      final bytes = await PdfService.build(resume);
      final cleanName = resume.name
          .trim()
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
      final fileName =
          cleanName.isEmpty ? 'resume.pdf' : '${cleanName}_resume.pdf';
      if (share) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      } else {
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: fileName,
        );
      }
    } catch (_) {
      if (mounted) showMessage(context, 'Could not create the PDF. Try again.');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (BuildContext context, Widget? _) {
        final resume = appState.resume;
        if (resume.isEmpty) return _empty();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          children: <Widget>[
            Text('Your resume', style: T.display(28)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                QuietButton(
                  label: 'Save as PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  busy: _exporting,
                  busyLabel: 'Making PDF',
                  onPressed: () => _exportPdf(share: false),
                ),
                QuietButton(
                  label: 'Share',
                  icon: Icons.ios_share,
                  onPressed: _exporting ? null : () => _exportPdf(share: true),
                ),
                QuietButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  onPressed: _openEditor,
                ),
                QuietButton(
                  label: 'Add with AI',
                  icon: Icons.edit_note,
                  onPressed: _openBuilder,
                ),
              ],
            ),
            const SizedBox(height: 18),
            ResumeSheet(resume: resume),
          ],
        );
      },
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Your resume', style: T.display(28)),
          const SizedBox(height: 10),
          Text(
            'Nothing here yet. Write a few lines about yourself and your '
            'resume appears on this page.',
            style: T.body(16),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Write my resume', onPressed: _openBuilder),
          const SizedBox(height: 12),
          QuietButton(
            label: 'Fill it in by hand',
            icon: Icons.edit_outlined,
            wide: true,
            onPressed: _openEditor,
          ),
        ],
      ),
    );
  }
}

/// The resume drawn as a sheet of paper on screen.
class ResumeSheet extends StatelessWidget {
  final Resume resume;
  const ResumeSheet({super.key, required this.resume});

  @override
  Widget build(BuildContext context) {
    final contact = <String>[resume.email, resume.phone, resume.location]
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return Sheet(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(resume.name, style: T.display(26)),
          if (resume.headline.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                resume.headline,
                style: T.body(16, color: AppColors.ink, weight: FontWeight.w600),
              ),
            ),
          if (contact.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 14,
                runSpacing: 2,
                children: contact
                    .map((c) => Text(c, style: T.body(13.5, color: AppColors.muted)))
                    .toList(),
              ),
            ),
          if (resume.summary.isNotEmpty) ...<Widget>[
            _heading('Summary'),
            Text(resume.summary, style: T.body(15)),
          ],
          if (resume.skills.isNotEmpty) ...<Widget>[
            _heading('Skills'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: resume.skills.map((s) => SkillChip(s)).toList(),
            ),
          ],
          ..._entries('Experience', resume.experience),
          ..._entries('Projects', resume.projects),
          ..._entries('Education', resume.education),
        ],
      ),
    );
  }

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(text, style: T.display(15)),
          const SizedBox(height: 5),
          const Divider(height: 1, color: AppColors.line),
        ],
      ),
    );
  }

  List<Widget> _entries(String title, List<Entry> entries) {
    if (entries.isEmpty) return <Widget>[];
    final widgets = <Widget>[_heading(title)];
    for (final e in entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                e.title,
                style: T.body(15.5, color: AppColors.ink, weight: FontWeight.w600),
              ),
              if (e.subtitle.isNotEmpty || e.period.isNotEmpty)
                Text(
                  <String>[e.subtitle, e.period]
                      .where((x) => x.isNotEmpty)
                      .join(', '),
                  style: T.body(13.5, color: AppColors.muted),
                ),
              if (e.points.isNotEmpty) const SizedBox(height: 6),
              for (final p in e.points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 9, right: 9),
                        decoration: const BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(child: Text(p, style: T.body(14.5))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }
}
