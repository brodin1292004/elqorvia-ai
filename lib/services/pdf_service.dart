// Turns the resume into a clean, single column PDF.
// Single column with real text is what company resume scanners
// (called ATS) read most reliably.

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models.dart';

class PdfService {
  static final PdfColor _ink = PdfColor.fromInt(0xFF16245C);
  static final PdfColor _text = PdfColor.fromInt(0xFF2B3452);
  static final PdfColor _muted = PdfColor.fromInt(0xFF68718F);
  static final PdfColor _line = PdfColor.fromInt(0xFFD9DFEC);

  static Future<Uint8List> build(Resume r) async {
    final doc = pw.Document(
      title: _safe('${r.name} resume'),
      author: _safe(r.name),
    );

    final contact = <String>[r.email, r.phone, r.location]
        .where((e) => e.trim().isNotEmpty)
        .map(_safe)
        .join('   |   ');

    final content = <pw.Widget>[
      pw.Text(
        _safe(r.name),
        style: pw.TextStyle(
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
    ];

    if (r.headline.isNotEmpty) {
      content.add(pw.Padding(
        padding: const pw.EdgeInsets.only(top: 3),
        child: pw.Text(
          _safe(r.headline),
          style: pw.TextStyle(fontSize: 12.5, color: _text),
        ),
      ));
    }
    if (contact.isNotEmpty) {
      content.add(pw.Padding(
        padding: const pw.EdgeInsets.only(top: 5),
        child: pw.Text(
          contact,
          style: pw.TextStyle(fontSize: 9.5, color: _muted),
        ),
      ));
    }

    if (r.summary.isNotEmpty) {
      content.add(_heading('Summary'));
      content.add(_para(r.summary));
    }
    if (r.skills.isNotEmpty) {
      content.add(_heading('Skills'));
      content.add(_para(r.skills.join(',  ')));
    }
    _addEntries(content, 'Experience', r.experience);
    _addEntries(content, 'Projects', r.projects);
    _addEntries(content, 'Education', r.education);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(46, 42, 46, 42),
        build: (pw.Context context) => content,
      ),
    );
    return doc.save();
  }

  static void _addEntries(
    List<pw.Widget> content,
    String title,
    List<Entry> entries,
  ) {
    if (entries.isEmpty) return;
    content.add(_heading(title));
    for (final e in entries) {
      content.add(pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Expanded(
              child: pw.Text(
                _safe(e.title),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _text,
                ),
              ),
            ),
            pw.Text(
              _safe(e.period),
              style: pw.TextStyle(fontSize: 9.5, color: _muted),
            ),
          ],
        ),
      ));
      if (e.subtitle.isNotEmpty) {
        content.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 1, bottom: 3),
          child: pw.Text(
            _safe(e.subtitle),
            style: pw.TextStyle(fontSize: 10, color: _muted),
          ),
        ));
      }
      for (final p in e.points) {
        content.add(_bullet(p));
      }
      content.add(pw.SizedBox(height: 5));
    }
  }

  static pw.Widget _heading(String title) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
      padding: const pw.EdgeInsets.only(bottom: 3),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.8)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11.5,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
    );
  }

  static pw.Widget _para(String text) {
    return pw.Text(
      _safe(text),
      style: pw.TextStyle(fontSize: 10.5, color: _text, lineSpacing: 2.5),
    );
  }

  static pw.Widget _bullet(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 2, bottom: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Container(
            width: 3,
            height: 3,
            margin: const pw.EdgeInsets.only(top: 4.5, right: 7),
            decoration: pw.BoxDecoration(
              color: _ink,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _safe(text),
              style: pw.TextStyle(fontSize: 10.5, color: _text, lineSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  /// The built-in PDF font only knows basic Latin letters. This swaps
  /// curly quotes, long dashes and the rupee sign for safe versions and
  /// drops anything else the font cannot draw.
  static String _safe(String input) {
    const swaps = <String, String>{
      '\u2018': "'",
      '\u2019': "'",
      '\u201C': '"',
      '\u201D': '"',
      '\u2013': '-',
      '\u2014': '-',
      '\u2022': '-',
      '\u2026': '...',
      '\u20B9': 'Rs. ',
      '\u00A0': ' ',
    };
    final b = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final swap = swaps[ch];
      if (swap != null) {
        b.write(swap);
      } else if (rune <= 0xFF) {
        b.write(ch);
      }
    }
    return b.toString();
  }
}
