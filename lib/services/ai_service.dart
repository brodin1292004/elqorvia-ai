// Everything that talks to the AI (Google Gemini) lives in this file.
// Each function builds an instruction (a "prompt"), sends it, and turns
// the answer into something the screens can show.
//
// With no key in config.dart, every function returns a demo answer, so
// the rest of the app still works.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models.dart';
import 'matcher.dart';

/// An error with a message that is safe to show to the user.
class AiException implements Exception {
  final String message;
  AiException(this.message);

  @override
  String toString() => message;
}

class AiService {
  // ------------------------------------------------------------------
  // 1. Rough notes  ->  finished resume
  // ------------------------------------------------------------------
  static Future<Resume> buildFromNotes(String notes, Resume current) async {
    if (!Config.hasAi) {
      await _pause();
      return sampleResume();
    }
    final prompt = '''
You are an expert resume writer for the Indian job market. Turn a person's rough notes into a professional, honest, one page resume.

Rules:
- Use only facts found in the notes or in the existing resume. Never invent employers, degrees, dates, numbers or contact details. If something is unknown, leave it as an empty string.
- The notes may be informal, misspelled, or mix English with another language. Write the resume in clear professional English.
- Start every bullet point with a strong action verb. Keep each under 22 words.
- summary: 2 to 3 sentences, without the word "I".
- headline: the job title this person should apply for.
- skills: short names, at most 14, most relevant first.
- experience: title = job role, subtitle = company.
- projects: title = project name, subtitle = tools used.
- education: title = degree, subtitle = college or school. points can be empty.
- If an existing resume is given, keep its facts and merge the new notes into it.

Return only JSON in exactly this shape:
{"name":"","headline":"","email":"","phone":"","location":"","summary":"","skills":[""],"experience":[{"title":"","subtitle":"","period":"","points":[""]}],"projects":[{"title":"","subtitle":"","period":"","points":[""]}],"education":[{"title":"","subtitle":"","period":"","points":[]}]}

Existing resume (JSON, may be empty):
${jsonEncode(current.toJson())}

New notes from the person:
$notes
''';
    final map = _json(await _ask(prompt, wantJson: true));
    final built = Resume.fromJson(map);
    if (built.isEmpty) {
      throw AiException(
          'The AI could not find resume details in your notes. Add more and try again.');
    }
    return built;
  }

  // ------------------------------------------------------------------
  // 2. Recruiter scan: what stands out in the first six seconds
  // ------------------------------------------------------------------
  static Future<ScanResult> scan(Resume resume) async {
    if (!Config.hasAi) {
      await _pause();
      return localScan(resume);
    }
    final prompt = '''
You are a busy recruiter in India who gives each resume about six seconds. Judge the resume below honestly. Do not flatter.

Return only JSON in exactly this shape:
{"score":0,"impression":"","fixes":[""]}

- score: 0 to 100 for how strong the resume looks at first glance.
- impression: 1 or 2 sentences on what you notice first, good or bad.
- fixes: at most 4 short, specific changes, each under 14 words, written as a direct instruction. Most important first.

Resume:
${resume.plainText()}
''';
    return ScanResult.fromJson(_json(await _ask(prompt, wantJson: true)));
  }

  // ------------------------------------------------------------------
  // 3. Job titles to search for, based on the resume
  // ------------------------------------------------------------------
  static Future<List<String>> suggestRoles(Resume resume) async {
    if (!Config.hasAi) {
      await _pause();
      return localRoles(resume);
    }
    final prompt = '''
Based on the resume below, list the 5 job titles this person has the best chance of getting in India right now. Use the short titles that companies actually write in job adverts, 2 to 3 words each.

Return only JSON in exactly this shape:
{"roles":["","","","",""]}

Resume:
${resume.plainText()}
''';
    final map = _json(await _ask(prompt, wantJson: true));
    final roles = map['roles'];
    if (roles is List) {
      final cleaned = roles
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .take(5)
          .toList();
      if (cleaned.isNotEmpty) return cleaned;
    }
    return localRoles(resume);
  }

  // ------------------------------------------------------------------
  // 4. Fit report for one job
  // ------------------------------------------------------------------
  static Future<FitReport> fitReport(Resume resume, Job job) async {
    if (!Config.hasAi) {
      await _pause();
      return _localReport(resume, job);
    }
    final prompt = '''
Compare this resume with this job advert as a fair hiring manager would.

Return only JSON in exactly this shape:
{"score":0,"strengths":[""],"gaps":[""],"advice":"","tailoredSummary":""}

- score: 0 to 100, how well the resume fits the job. Be realistic.
- strengths: up to 3 short reasons this person fits, each tied to something in the resume.
- gaps: up to 3 short, specific things the job asks for that the resume does not show.
- advice: 1 or 2 sentences on the best next step before applying.
- tailoredSummary: a new 2 to 3 sentence resume summary aimed at this job. Use only facts already in the resume. Do not use the word "I". Do not claim skills the resume does not show.

Resume:
${resume.plainText()}

Job advert:
${job.title} at ${job.company}, ${job.location}
${job.description}
''';
    return FitReport.fromJson(_json(await _ask(prompt, wantJson: true)));
  }

  // ------------------------------------------------------------------
  // 5. Cover letter for one job
  // ------------------------------------------------------------------
  static Future<String> coverLetter(Resume resume, Job job) async {
    if (!Config.hasAi) {
      await _pause();
      return _localLetter(resume, job);
    }
    final prompt = '''
Write a cover letter for the job below, using only facts from the resume.

Rules:
- Under 170 words, plain text, no markdown.
- Warm, direct and confident. No cliches such as "I am writing to apply".
- Mention the company and the role by name.
- Point to one or two concrete things from the resume that matter for this job.
- Never invent experience. Never leave placeholders in brackets.
- End with the person's name.

Resume:
${resume.plainText()}

Job advert:
${job.title} at ${job.company}, ${job.location}
${job.description}
''';
    return _ask(prompt, temperature: 0.7);
  }

  // ------------------------------------------------------------------
  // 6. Interview practice: questions
  // ------------------------------------------------------------------
  static Future<List<String>> interviewQuestions(
    Resume resume,
    String role,
    Job? job,
  ) async {
    if (!Config.hasAi) {
      await _pause();
      return _localQuestions(role);
    }
    final advert = job == null
        ? '(no advert, use the role name)'
        : '${job.title} at ${job.company}\n${job.description}';
    final prompt = '''
You are interviewing a candidate in India for the role below. Write 5 interview questions for this exact candidate.

- Question 1: an opening question about who they are.
- Questions 2 and 3: skill or technical questions drawn from the role and from the skills on the resume.
- Question 4: about one specific project or job that is on the resume. Name it.
- Question 5: a behavioural question about teamwork, pressure or a mistake.
- Match the difficulty to the candidate's experience level.
- Each question under 30 words, written the way an interviewer would say it aloud.

Return only JSON in exactly this shape:
{"questions":["","","","",""]}

Role: $role

Job advert:
$advert

Resume:
${resume.plainText()}
''';
    final map = _json(await _ask(prompt, wantJson: true, temperature: 0.8));
    final raw = map['questions'];
    if (raw is List) {
      final questions = raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .take(5)
          .toList();
      if (questions.isNotEmpty) return questions;
    }
    throw AiException('The AI did not send any questions. Try again.');
  }

  // ------------------------------------------------------------------
  // 7. Interview practice: feedback on one answer
  // ------------------------------------------------------------------
  static Future<AnswerReview> reviewAnswer(
    Resume resume,
    String role,
    String question,
    String answer,
  ) async {
    if (!Config.hasAi) {
      await _pause();
      return _localReview(answer);
    }
    final prompt = '''
You are an interview coach. A candidate for the role "$role" answered an interview question. Review the answer honestly. Do not flatter.

Return only JSON in exactly this shape:
{"score":0,"good":"","improve":[""],"better":""}

- score: 0 to 10. A vague or very short answer scores 4 or less.
- good: one sentence on what worked. If nothing worked, say so plainly.
- improve: up to 3 short, specific fixes, each under 16 words, written as direct instructions.
- better: a stronger answer in under 90 words, in the first person, in natural spoken English. Build it only from facts in the resume and in the candidate's answer. Never invent experience, numbers or employers.

Question: $question

Candidate's answer: $answer

Resume:
${resume.plainText()}
''';
    return AnswerReview.fromJson(_json(await _ask(prompt, wantJson: true)));
  }

  // ==================================================================
  // Below: the plumbing. You rarely need to change this part.
  // ==================================================================

  static Future<void> _pause() =>
      Future<void>.delayed(const Duration(milliseconds: 700));

  /// Sends one prompt to Gemini and returns the text answer.
  static Future<String> _ask(
    String prompt, {
    bool wantJson = false,
    double temperature = 0.4,
  }) async {
    AiException? firstError; // what went wrong with the main model
    bool limited = false; // true when a free limit was hit

    for (final model in Config.geminiModels) {
      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');

      http.Response res;
      try {
        res = await http
            .post(
              uri,
              headers: <String, String>{
                'Content-Type': 'application/json',
                'x-goog-api-key': Config.geminiApiKey,
              },
              body: jsonEncode(<String, dynamic>{
                'contents': [
                  {
                    'role': 'user',
                    'parts': [
                      {'text': prompt},
                    ],
                  },
                ],
                'generationConfig': <String, dynamic>{
                  'temperature': temperature,
                  if (wantJson) 'responseMimeType': 'application/json',
                },
              }),
            )
            .timeout(const Duration(seconds: 60));
      } on TimeoutException {
        throw AiException('The AI took too long to answer. Try again.');
      } catch (_) {
        throw AiException(
            'Could not reach the AI. Check your internet connection.');
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final text = _textFrom(data);
        if (text.isEmpty) {
          throw AiException('The AI sent back an empty answer. Try again.');
        }
        return text;
      }

      final body = res.body;
      final keyProblem = res.statusCode == 400 &&
          (body.contains('API key') || body.contains('API_KEY'));
      if (res.statusCode == 401 || res.statusCode == 403 || keyProblem) {
        throw AiException(
            'Your Gemini key was not accepted. Check geminiApiKey in lib/config.dart.');
      }
      // Any other problem: remember it, then try the next model.
      if (res.statusCode == 429) {
        limited = true;
      } else if (res.statusCode == 404) {
        firstError ??= AiException(
            'The AI model "$model" was not found. Update geminiModels in lib/config.dart.');
      } else if (res.statusCode == 503) {
        firstError ??= AiException(
            'The AI is busy right now. Wait a minute and try again.');
      } else {
        firstError ??= AiException(
            'The AI service had a problem (code ${res.statusCode}). Try again.');
      }
    }

    if (limited) {
      throw AiException(
          'The free AI limit is used up for now. Wait a minute and try again.');
    }
    throw firstError ?? AiException('The AI did not answer. Try again.');
  }

  /// Pulls the plain text out of Gemini's answer.
  static String _textFrom(dynamic data) {
    try {
      final parts = data['candidates'][0]['content']['parts'] as List;
      final b = StringBuffer();
      for (final p in parts) {
        if (p is Map && p['thought'] != true && p['text'] != null) {
          b.write(p['text'].toString());
        }
      }
      return b.toString().trim();
    } catch (_) {
      return '';
    }
  }

  /// Finds the JSON object inside the AI's answer and decodes it.
  static Map<String, dynamic> _json(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      try {
        final decoded = jsonDecode(text.substring(start, end + 1));
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // fall through to the error below
      }
    }
    throw AiException('The AI answer could not be read. Try again.');
  }

  // ------------------------------------------------------------------
  // Demo answers, used when there is no Gemini key yet
  // ------------------------------------------------------------------

  static FitReport _localReport(Resume resume, Job job) {
    final fit = localFit(resume, job);
    return FitReport(
      score: fit.score,
      strengths: fit.matched
          .take(3)
          .map((s) => 'Your resume already shows ${prettySkill(s)}.')
          .toList(),
      gaps: fit.missing
          .take(3)
          .map((s) => 'The job asks for ${prettySkill(s)}, which your resume does not show.')
          .toList(),
      advice: fit.missing.isEmpty
          ? 'Your skills line up well. Apply, and mention your strongest project first.'
          : 'If you have used ${prettySkill(fit.missing.first)}, add it to your resume before applying.',
      tailoredSummary: '',
    );
  }

  static List<String> _localQuestions(String role) {
    return <String>[
      'Tell me about yourself and why you want to work as a $role.',
      'Which of your skills matters most for this role, and how have you used it?',
      'Walk me through a project you are proud of. What exactly did you do?',
      'Tell me about a time something went wrong in your work. What did you do?',
      'Where do you want to be in two years, and how does this job help?',
    ];
  }

  static AnswerReview _localReview(String answer) {
    final words = answer.trim().split(RegExp(r'\s+')).length;
    final hasNumber = RegExp(r'\d').hasMatch(answer);
    int score = 3;
    if (words >= 25) score += 2;
    if (words >= 50) score += 1;
    if (hasNumber) score += 1;
    return AnswerReview(
      score: score,
      good: words >= 25
          ? 'You gave enough detail for an interviewer to follow.'
          : 'You answered the question directly.',
      improve: <String>[
        if (words < 50) 'Say more. Aim for four or five full sentences.',
        if (!hasNumber) 'Add one number, such as how many or how long.',
        'Finish with the result of what you did.',
      ],
      better:
          'Demo feedback. Add your Gemini key in lib/config.dart to get a stronger answer written from your own resume.',
    );
  }

  static String _localLetter(Resume resume, Job job) {
    final skills = resume.skills.take(3).join(', ');
    final company = job.company.isEmpty ? 'your company' : job.company;
    return 'Dear Hiring Team,\n\n'
        'The ${job.title} role at $company caught my attention because it '
        'matches the work I enjoy most. '
        '${skills.isEmpty ? '' : 'My strongest skills are $skills. '}'
        '${resume.summary}\n\n'
        'I would welcome the chance to show how I can contribute to your team.\n\n'
        'Thank you for your time.\n\n'
        '${resume.name}\n\n'
        '(Demo letter. Add your Gemini key in lib/config.dart for a letter '
        'written for this exact job.)';
  }
}

/// The resume shown in demo mode.
Resume sampleResume() {
  return Resume(
    name: 'Your Name',
    headline: 'Junior Flutter Developer',
    email: 'you@example.com',
    phone: '98765 43210',
    location: 'Chennai, Tamil Nadu',
    summary:
        'Computer applications graduate who builds mobile apps with Flutter and Firebase. Shipped a food ordering app as a final year project and enjoys turning rough ideas into clean, working screens.',
    skills: <String>[
      'Flutter', 'Dart', 'Firebase', 'REST API', 'Git', 'Figma', 'SQL',
      'Python', 'Communication',
    ],
    experience: <Entry>[
      Entry(
        title: 'App Development Intern',
        subtitle: 'Sample Software Company',
        period: 'Jan 2025 to Jun 2025',
        points: <String>[
          'Built 6 screens for a customer booking app using Flutter.',
          'Fixed 20 layout bugs reported by testers before release.',
        ],
      ),
    ],
    projects: <Entry>[
      Entry(
        title: 'Food ordering app',
        subtitle: 'Flutter, Firebase',
        period: '2024',
        points: <String>[
          'Designed and built a food ordering app with login, cart and order tracking.',
          'Stored menu and order data in Firebase for 3 sample restaurants.',
        ],
      ),
    ],
    education: <Entry>[
      Entry(
        title: 'Bachelor of Computer Applications',
        subtitle: 'Sample Arts and Science College',
        period: '2022 to 2025',
      ),
    ],
  );
}
