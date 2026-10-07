// The shapes of the data the app works with:
// a Resume, a Job, and the results the AI sends back.

import 'dart:convert';

String _s(dynamic v) => v == null ? '' : v.toString().trim();

List<String> _strings(dynamic v) {
  if (v is List) {
    return v.map((e) => _s(e)).where((e) => e.isNotEmpty).toList();
  }
  return <String>[];
}

List<Entry> _entries(dynamic v) {
  if (v is List) {
    return v.map((e) => Entry.fromJson(e)).where((e) => !e.isBlank).toList();
  }
  return <Entry>[];
}

/// One block on a resume: a job, a project, or a degree.
class Entry {
  String title; // role, project name, or degree
  String subtitle; // company, tools used, or college
  String period; // "2023 to 2025"
  List<String> points; // bullet points

  Entry({
    this.title = '',
    this.subtitle = '',
    this.period = '',
    List<String>? points,
  }) : points = points ?? <String>[];

  factory Entry.fromJson(dynamic j) {
    if (j is! Map) return Entry();
    return Entry(
      title: _s(j['title']),
      subtitle: _s(j['subtitle']),
      period: _s(j['period']),
      points: _strings(j['points']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'subtitle': subtitle,
        'period': period,
        'points': points,
      };

  bool get isBlank =>
      title.trim().isEmpty && subtitle.trim().isEmpty && points.isEmpty;
}

class Resume {
  String name;
  String headline; // e.g. "Flutter Developer"
  String email;
  String phone;
  String location;
  String summary;
  List<String> skills;
  List<Entry> experience;
  List<Entry> projects;
  List<Entry> education;

  Resume({
    this.name = '',
    this.headline = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.summary = '',
    List<String>? skills,
    List<Entry>? experience,
    List<Entry>? projects,
    List<Entry>? education,
  })  : skills = skills ?? <String>[],
        experience = experience ?? <Entry>[],
        projects = projects ?? <Entry>[],
        education = education ?? <Entry>[];

  factory Resume.fromJson(Map<String, dynamic> j) {
    return Resume(
      name: _s(j['name']),
      headline: _s(j['headline']),
      email: _s(j['email']),
      phone: _s(j['phone']),
      location: _s(j['location']),
      summary: _s(j['summary']),
      skills: _strings(j['skills']),
      experience: _entries(j['experience']),
      projects: _entries(j['projects']),
      education: _entries(j['education']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'headline': headline,
        'email': email,
        'phone': phone,
        'location': location,
        'summary': summary,
        'skills': skills,
        'experience': experience.map((e) => e.toJson()).toList(),
        'projects': projects.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
      };

  /// A separate copy, so editing it does not change the original.
  Resume copy() {
    final decoded = jsonDecode(jsonEncode(toJson()));
    return Resume.fromJson(decoded as Map<String, dynamic>);
  }

  bool get isEmpty =>
      name.isEmpty &&
      headline.isEmpty &&
      summary.isEmpty &&
      skills.isEmpty &&
      experience.isEmpty &&
      projects.isEmpty &&
      education.isEmpty;

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  /// The whole resume as plain text. Used for AI prompts and matching.
  String plainText() {
    final b = StringBuffer();
    b.writeln(name);
    b.writeln(headline);
    b.writeln(summary);
    b.writeln('Skills: ${skills.join(', ')}');
    void block(String label, List<Entry> list) {
      if (list.isEmpty) return;
      b.writeln(label);
      for (final e in list) {
        b.writeln('${e.title}, ${e.subtitle}, ${e.period}');
        for (final p in e.points) {
          b.writeln('- $p');
        }
      }
    }

    block('Experience', experience);
    block('Projects', projects);
    block('Education', education);
    return b.toString();
  }
}

class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String description;
  final String url;
  final String salary; // already formatted, may be empty
  final String posted; // "3 days ago", may be empty

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    this.url = '',
    this.salary = '',
    this.posted = '',
  });

  /// Used when a job is saved on the phone.
  factory Job.fromJson(Map<String, dynamic> j) {
    return Job(
      id: _s(j['id']),
      title: _s(j['title']),
      company: _s(j['company']),
      location: _s(j['location']),
      description: _s(j['description']),
      url: _s(j['url']),
      salary: _s(j['salary']),
    );
  }

  // "posted" is left out on purpose: "Posted 2 days ago" would be
  // wrong by the time a saved job is opened again.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'company': company,
        'location': location,
        'description': description,
        'url': url,
        'salary': salary,
      };

  /// Builds a Job from one item of the Adzuna API answer.
  factory Job.fromAdzuna(Map<String, dynamic> j) {
    final company = j['company'];
    final loc = j['location'];
    return Job(
      id: _s(j['id']),
      title: _clean(_s(j['title'])),
      company: company is Map ? _s(company['display_name']) : '',
      location: loc is Map ? _s(loc['display_name']) : '',
      description: _clean(_s(j['description'])),
      url: _s(j['redirect_url']),
      salary: _salary(j),
      posted: _ago(_s(j['created'])),
    );
  }
}

String _clean(String s) => s
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&amp;', '&')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _money(num v) =>
    v >= 100000 ? '₹${(v / 100000).toStringAsFixed(1)} lakh' : '₹${v.round()}';

String _salary(Map<String, dynamic> j) {
  // Adzuna guesses a salary when the advert has none. Do not show guesses.
  if (_s(j['salary_is_predicted']) == '1') return '';
  final min = j['salary_min'];
  final max = j['salary_max'];
  if (min is! num || min <= 0) return '';
  if (max is num && max > min) {
    return '${_money(min)} to ${_money(max)} a year';
  }
  return '${_money(min)} a year';
}

String _ago(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return '';
  final days = DateTime.now().difference(date).inDays;
  if (days <= 0) return 'Posted today';
  if (days == 1) return 'Posted yesterday';
  if (days < 30) return 'Posted $days days ago';
  return 'Posted over a month ago';
}

/// Quick match worked out on the phone, with no AI call.
class LocalFit {
  final int score; // 0 to 100
  final List<String> matched;
  final List<String> missing;
  const LocalFit(this.score, this.matched, this.missing);
}

/// The detailed AI report for one job.
class FitReport {
  final int score;
  final List<String> strengths;
  final List<String> gaps;
  final String advice;
  final String tailoredSummary;

  const FitReport({
    required this.score,
    required this.strengths,
    required this.gaps,
    required this.advice,
    required this.tailoredSummary,
  });

  factory FitReport.fromJson(Map<String, dynamic> j) {
    final raw = j['score'];
    final score = raw is num ? raw.round() : int.tryParse(_s(raw)) ?? 0;
    return FitReport(
      score: score.clamp(0, 100).toInt(),
      strengths: _strings(j['strengths']),
      gaps: _strings(j['gaps']),
      advice: _s(j['advice']),
      tailoredSummary: _s(j['tailoredSummary']),
    );
  }
}

/// What a recruiter notices in the first few seconds.
class ScanResult {
  final int score;
  final String impression;
  final List<String> fixes;

  const ScanResult({
    required this.score,
    required this.impression,
    required this.fixes,
  });

  factory ScanResult.fromJson(Map<String, dynamic> j) {
    final raw = j['score'];
    final score = raw is num ? raw.round() : int.tryParse(_s(raw)) ?? 0;
    return ScanResult(
      score: score.clamp(0, 100).toInt(),
      impression: _s(j['impression']),
      fixes: _strings(j['fixes']),
    );
  }
}

/// The steps a job application moves through.
class Stage {
  static const String saved = 'Saved';
  static const String applied = 'Applied';
  static const String interview = 'Interview';
  static const String offer = 'Offer';
  static const String closed = 'Closed';

  /// The normal path, in order.
  static const List<String> path = <String>[saved, applied, interview, offer];

  /// Every possible stage. "Closed" means it did not work out.
  static const List<String> all = <String>[
    saved,
    applied,
    interview,
    offer,
    closed,
  ];
}

/// A job the user saved, plus how far the application has got.
class TrackedJob {
  final Job job;
  String stage;
  final DateTime savedAt;
  DateTime updatedAt;

  TrackedJob({
    required this.job,
    this.stage = Stage.saved,
    DateTime? savedAt,
    DateTime? updatedAt,
  })  : savedAt = savedAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory TrackedJob.fromJson(Map<String, dynamic> j) {
    final rawJob = j['job'];
    final stage = _s(j['stage']);
    return TrackedJob(
      job: Job.fromJson(
        rawJob is Map<String, dynamic> ? rawJob : <String, dynamic>{},
      ),
      stage: Stage.all.contains(stage) ? stage : Stage.saved,
      savedAt: DateTime.tryParse(_s(j['savedAt'])),
      updatedAt: DateTime.tryParse(_s(j['updatedAt'])),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'job': job.toJson(),
        'stage': stage,
        'savedAt': savedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// The coach's feedback on one interview answer.
class AnswerReview {
  final int score; // 0 to 10
  final String good;
  final List<String> improve;
  final String better;

  const AnswerReview({
    required this.score,
    required this.good,
    required this.improve,
    required this.better,
  });

  factory AnswerReview.fromJson(Map<String, dynamic> j) {
    final raw = j['score'];
    final score = raw is num ? raw.round() : int.tryParse(_s(raw)) ?? 0;
    return AnswerReview(
      score: score.clamp(0, 10).toInt(),
      good: _s(j['good']),
      improve: _strings(j['improve']),
      better: _s(j['better']),
    );
  }
}
