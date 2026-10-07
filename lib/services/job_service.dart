// Finds jobs. With Adzuna keys in config.dart it searches real jobs.
// Without keys it returns sample jobs so the screens still work.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models.dart';

class JobException implements Exception {
  final String message;
  JobException(this.message);

  @override
  String toString() => message;
}

class JobService {
  static Future<List<Job>> search(String what, String where) async {
    if (!Config.hasJobs) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return List<Job>.of(_sampleJobs);
    }

    final uri = Uri.https(
      'api.adzuna.com',
      '/v1/api/jobs/${Config.jobCountry}/search/1',
      <String, String>{
        'app_id': Config.adzunaAppId,
        'app_key': Config.adzunaAppKey,
        'results_per_page': '25',
        'what': what,
        if (where.isNotEmpty) 'where': where,
        'content-type': 'application/json',
      },
    );

    http.Response res;
    try {
      res = await http.get(uri).timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw JobException('The job search took too long. Try again.');
    } catch (_) {
      throw JobException(
          'Could not reach the job search. Check your internet connection.');
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw JobException(
          'Your Adzuna keys were not accepted. Check them in lib/config.dart.');
    }
    if (res.statusCode != 200) {
      throw JobException(
          'The job search had a problem (code ${res.statusCode}). Try again.');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final jobs = <Job>[];
    if (data is Map && data['results'] is List) {
      for (final item in data['results'] as List) {
        if (item is Map<String, dynamic>) {
          jobs.add(Job.fromAdzuna(item));
        }
      }
    }
    return jobs;
  }
}

const List<Job> _sampleJobs = <Job>[
  Job(
    id: 's1',
    title: 'Junior Flutter Developer',
    company: 'Sample Apps Studio',
    location: 'Chennai, Tamil Nadu',
    salary: '₹3.0 lakh to ₹4.5 lakh a year',
    posted: 'Posted 2 days ago',
    description:
        'We are looking for a junior Flutter developer to build Android and iOS apps. You should know Dart, Flutter, REST API integration, Firebase and Git. Knowledge of Figma is a plus. Good communication and teamwork matter to us.',
  ),
  Job(
    id: 's2',
    title: 'UI UX Designer',
    company: 'Sample Design Lab',
    location: 'Kochi, Kerala',
    salary: '₹3.6 lakh to ₹5.0 lakh a year',
    posted: 'Posted 4 days ago',
    description:
        'Design clean mobile and web interfaces. Required: Figma, wireframing, prototyping, user research and typography. Photoshop and Illustrator are useful. You will work closely with developers, so basic HTML and CSS knowledge helps.',
  ),
  Job(
    id: 's3',
    title: 'Python Developer',
    company: 'Sample Tech Solutions',
    location: 'Bengaluru, Karnataka',
    salary: '₹4.0 lakh to ₹6.0 lakh a year',
    posted: 'Posted yesterday',
    description:
        'Build backend services in Python with Django or Flask. You need SQL, MySQL or PostgreSQL, REST API design, Git and basic Linux. Docker and AWS are a bonus. Problem solving and clear communication are important.',
  ),
  Job(
    id: 's4',
    title: 'Graphic Designer',
    company: 'Sample Media House',
    location: 'Coimbatore, Tamil Nadu',
    salary: '₹2.4 lakh to ₹3.6 lakh a year',
    posted: 'Posted 6 days ago',
    description:
        'Create posters, social media creatives and brand material. Must know Photoshop, Illustrator and Canva. Experience in branding, logo design and typography preferred. Video editing or motion graphics is a plus.',
  ),
  Job(
    id: 's5',
    title: 'Data Analyst',
    company: 'Sample Insights',
    location: 'Hyderabad, Telangana',
    salary: '₹4.0 lakh to ₹5.5 lakh a year',
    posted: 'Posted 3 days ago',
    description:
        'Turn raw data into clear reports. Required skills: Excel, SQL, Python with Pandas, data visualization with Power BI or Tableau, and basic statistics. Strong communication to explain findings to non technical teams.',
  ),
  Job(
    id: 's6',
    title: 'Full Stack Web Developer',
    company: 'Sample Web Works',
    location: 'Thiruvananthapuram, Kerala',
    salary: '₹3.5 lakh to ₹5.5 lakh a year',
    posted: 'Posted 5 days ago',
    description:
        'Develop web applications end to end. Front end: HTML, CSS, JavaScript and React. Back end: Node.js or Python, with MySQL or MongoDB. You should be comfortable with Git, REST API work and testing.',
  ),
  Job(
    id: 's7',
    title: 'QA Tester',
    company: 'Sample Quality Labs',
    location: 'Madurai, Tamil Nadu',
    posted: 'Posted 1 week ago',
    description:
        'Test mobile and web apps before release. Manual testing experience needed, with automation testing in Selenium as a plus. Familiar with Jira, SQL basics and agile teams. Sharp attention to detail and good communication.',
  ),
  Job(
    id: 's8',
    title: 'Content Writer',
    company: 'Sample Digital Agency',
    location: 'Remote, India',
    salary: '₹2.4 lakh to ₹3.0 lakh a year',
    posted: 'Posted today',
    description:
        'Write blog posts, website copy and social media captions. Needs strong content writing and copywriting, SEO basics, WordPress and Canva. Experience with digital marketing or Google Analytics is welcome.',
  ),
];
