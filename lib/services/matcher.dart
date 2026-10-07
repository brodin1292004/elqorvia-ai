// The "no AI needed" brain. It runs on the phone, instantly and free:
//   - finds skill words inside a job advert
//   - compares them with the resume to give a fit score
//   - gives a basic resume check when there is no AI key yet

import '../models.dart';

/// Skill words the app looks for in job adverts. Add your own freely.
const List<String> kSkillTerms = <String>[
  'flutter', 'dart', 'python', 'java', 'kotlin', 'swift', 'javascript',
  'typescript', 'react', 'react native', 'angular', 'vue', 'node.js',
  'express', 'django', 'flask', 'spring boot', 'php', 'laravel', 'html',
  'css', 'tailwind', 'bootstrap', 'sql', 'mysql', 'postgresql', 'mongodb',
  'firebase', 'rest api', 'graphql', 'git', 'github', 'docker', 'kubernetes',
  'aws', 'azure', 'linux', 'c++', 'c#', '.net', 'android', 'ios', 'figma',
  'adobe xd', 'photoshop', 'illustrator', 'indesign', 'after effects',
  'premiere pro', 'canva', 'coreldraw', 'ui design', 'ux design', 'ui/ux',
  'wireframing', 'prototyping', 'user research', 'typography', 'branding',
  'logo design', 'video editing', 'motion graphics', 'excel', 'power bi',
  'tableau', 'pandas', 'numpy', 'machine learning', 'deep learning',
  'data analysis', 'data visualization', 'statistics', 'tensorflow', 'nlp',
  'seo', 'content writing', 'copywriting', 'social media',
  'digital marketing', 'google analytics', 'wordpress', 'communication',
  'teamwork', 'leadership', 'problem solving', 'project management', 'agile',
  'scrum', 'testing', 'selenium', 'manual testing', 'automation testing',
  'jira', 'customer service', 'sales', 'tally', 'accounting', 'gst',
  'ms office', 'teaching', 'training',
];

const Set<String> _smallWords = <String>{
  'and', 'the', 'for', 'with', 'senior', 'junior', 'lead', 'intern',
  'fresher', 'trainee', 'associate', 'executive', 'job', 'jobs',
};

const Map<String, String> _specialNames = <String, String>{
  'ios': 'iOS', 'ui/ux': 'UI/UX', 'html': 'HTML', 'mysql': 'MySQL',
  'postgresql': 'PostgreSQL', 'mongodb': 'MongoDB', 'node.js': 'Node.js',
  'javascript': 'JavaScript', 'typescript': 'TypeScript', 'github': 'GitHub',
  'ui design': 'UI design', 'ux design': 'UX design', 'rest api': 'REST API',
  'graphql': 'GraphQL', 'power bi': 'Power BI', 'ms office': 'MS Office',
  'adobe xd': 'Adobe XD', 'coreldraw': 'CorelDRAW', 'wordpress': 'WordPress',
  'git': 'Git', 'vue': 'Vue', '.net': '.NET', 'numpy': 'NumPy',
  'tensorflow': 'TensorFlow',
};

/// Turns "power bi" into "Power BI" and "sql" into "SQL" for display.
String prettySkill(String term) {
  final t = term.trim().toLowerCase();
  final special = _specialNames[t];
  if (special != null) return special;
  if (t.length <= 3) return t.toUpperCase();
  return t
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

bool _isWordChar(int c) => (c >= 48 && c <= 57) || (c >= 97 && c <= 122);

/// True when [term] appears in [lowerText] as a whole word.
/// So "java" is found in "java developer" but not inside "javascript".
bool containsTerm(String lowerText, String term) {
  if (term.isEmpty) return false;
  int from = 0;
  while (true) {
    final i = lowerText.indexOf(term, from);
    if (i < 0) return false;
    final end = i + term.length;
    final before = i == 0 ? 32 : lowerText.codeUnitAt(i - 1);
    final after = end >= lowerText.length ? 32 : lowerText.codeUnitAt(end);
    if (!_isWordChar(before) && !_isWordChar(after)) return true;
    from = i + 1;
  }
}

Set<String> skillsIn(String lowerText) {
  final found = <String>{};
  for (final term in kSkillTerms) {
    if (containsTerm(lowerText, term)) found.add(term);
  }
  return found;
}

/// Compares the resume with one job. No internet needed.
LocalFit localFit(Resume resume, Job job) {
  if (resume.isEmpty) {
    return const LocalFit(0, <String>[], <String>[]);
  }
  final jobText = '${job.title} ${job.description}'.toLowerCase();
  final resumeText = resume.plainText().toLowerCase();

  // Skills the job asks for.
  final wanted = skillsIn(jobText);
  for (final s in resume.skills) {
    final t = s.toLowerCase().trim();
    if (t.length > 1 && containsTerm(jobText, t)) wanted.add(t);
  }

  final matched = <String>[];
  final missing = <String>[];
  for (final w in wanted) {
    if (containsTerm(resumeText, w)) {
      matched.add(w);
    } else {
      missing.add(w);
    }
  }

  // Does the job title itself appear in the resume?
  final titleWords = job.title
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9+#.]+'))
      .where((w) => w.length > 2 && !_smallWords.contains(w))
      .toSet();
  int titleHits = 0;
  for (final w in titleWords) {
    if (containsTerm(resumeText, w)) titleHits++;
  }
  final double titleScore =
      titleWords.isEmpty ? 0.0 : titleHits / titleWords.length;
  final double skillScore =
      wanted.isEmpty ? titleScore : matched.length / wanted.length;

  // When the advert only shows one or two skills, the app cannot be
  // sure of the fit, so the score is held lower.
  final double evidence =
      wanted.length >= 4 ? 1.0 : 0.55 + 0.15 * wanted.length;
  final raw =
      ((skillScore * 0.7 + titleScore * 0.3) * 100 * evidence).round();
  final score = raw.clamp(4, 97).toInt();
  return LocalFit(score, matched, missing);
}

/// Job titles to search for, guessed from the resume without AI.
List<String> localRoles(Resume resume) {
  final roles = <String>[];
  void add(String role) {
    final exists = roles.any((r) => r.toLowerCase() == role.toLowerCase());
    if (!exists && role.trim().isNotEmpty) roles.add(role.trim());
  }

  if (resume.headline.isNotEmpty) add(resume.headline);
  final text = resume.plainText().toLowerCase();
  bool has(String term) => containsTerm(text, term);

  if (has('flutter') || has('dart')) add('Flutter Developer');
  if (has('python')) add('Python Developer');
  if (has('figma') || has('ui/ux') || has('ui design')) add('UI UX Designer');
  if (has('photoshop') || has('illustrator') || has('coreldraw')) {
    add('Graphic Designer');
  }
  if (has('react') || has('html') || has('javascript')) add('Web Developer');
  if (has('excel') || has('power bi') || has('sql')) add('Data Analyst');
  if (has('java')) add('Java Developer');
  if (has('content writing') || has('seo')) add('Content Writer');
  if (has('testing') || has('selenium')) add('QA Tester');

  if (roles.isEmpty) {
    add('Software Developer');
    add('Graphic Designer');
    add('Data Analyst');
  }
  return roles.take(5).toList();
}

/// A basic resume check that works without AI.
ScanResult localScan(Resume r) {
  int score = 100;
  final fixes = <String>[];
  final points = <String>[
    for (final e in r.experience) ...e.points,
    for (final e in r.projects) ...e.points,
  ];

  if (r.email.isEmpty || r.phone.isEmpty) {
    score -= 15;
    fixes.add('Put your phone number and email at the top.');
  }
  final summaryWords = r.summary.trim().split(RegExp(r'\s+')).length;
  if (r.summary.trim().isEmpty || summaryWords < 15) {
    score -= 15;
    fixes.add('Write two lines that say who you are and what you want.');
  }
  if (r.experience.isEmpty && r.projects.isEmpty) {
    score -= 20;
    fixes.add('Add one project, even a college one.');
  }
  if (r.skills.length < 6) {
    score -= 12;
    fixes.add('List at least six skills.');
  }
  if (points.isNotEmpty && !points.any((p) => RegExp(r'\d').hasMatch(p))) {
    score -= 12;
    fixes.add('Add a number to one point, like "20 posters a month".');
  }
  if (points.any((p) => p.trim().split(RegExp(r'\s+')).length > 28)) {
    score -= 8;
    fixes.add('Cut long points down to one line each.');
  }
  if (r.education.isEmpty) {
    score -= 10;
    fixes.add('Add your degree and college.');
  }

  final String impression;
  if (fixes.isEmpty) {
    impression =
        'Clear and complete at first glance. A recruiter can find your role, skills and proof quickly.';
  } else if (score >= 70) {
    impression =
        'A solid start. The basics are here, but a few gaps will slow a recruiter down.';
  } else {
    impression =
        'A recruiter would struggle to see your strengths quickly. Fix the notes below first.';
  }
  return ScanResult(
    score: score.clamp(20, 96).toInt(),
    impression: impression,
    fixes: fixes.take(4).toList(),
  );
}
