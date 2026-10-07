// Interview practice. The AI writes five questions for the role, the
// user types an answer to each, and the AI coaches every answer.

import 'package:flutter/material.dart';

import '../config.dart';
import '../models.dart';
import '../services/ai_service.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class InterviewScreen extends StatefulWidget {
  final String role;
  final Job? job; // set when practising for one specific job
  const InterviewScreen({super.key, required this.role, this.job});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final TextEditingController _answer = TextEditingController();

  List<String>? _questions; // null while loading
  String? _loadError;
  int _index = 0; // which question is on screen
  AnswerReview? _review; // feedback for the current answer
  bool _reviewing = false;
  final List<int> _scores = <int>[]; // one score per finished question

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  /// Starts over with a fresh set of questions.
  Future<void> _loadQuestions() async {
    setState(() {
      _questions = null;
      _loadError = null;
      _index = 0;
      _review = null;
      _scores.clear();
      _answer.clear();
    });
    await _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final questions = await AiService.interviewQuestions(
        appState.resume,
        widget.role,
        widget.job,
      );
      if (mounted) setState(() => _questions = questions);
    } on AiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _loadError = 'Could not prepare the questions. Try again.');
      }
    }
  }

  Future<void> _checkAnswer() async {
    final questions = _questions;
    if (questions == null) return;
    final answer = _answer.text.trim();
    if (answer.length < 15) {
      showMessage(context, 'Type your answer first. A few sentences is enough.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _reviewing = true);
    try {
      final review = await AiService.reviewAnswer(
        appState.resume,
        widget.role,
        questions[_index],
        answer,
      );
      if (mounted) setState(() => _review = review);
    } on AiException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (_) {
      if (mounted) showMessage(context, 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  void _next() {
    final review = _review;
    if (review == null) return;
    setState(() {
      _scores.add(review.score);
      _index++;
      _review = null;
      _answer.clear();
    });
  }

  void _tryAgain() {
    setState(() => _review = null);
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    return Scaffold(
      appBar: plainAppBar('Interview practice'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: <Widget>[
            if (_loadError != null)
              ..._errorView(_loadError!)
            else if (questions == null)
              ..._loadingView()
            else if (_index >= questions.length)
              ..._resultsView(questions)
            else
              ..._questionView(questions),
          ],
        ),
      ),
    );
  }

  List<Widget> _loadingView() {
    return <Widget>[
      const SizedBox(height: 40),
      const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: AppColors.ink,
          ),
        ),
      ),
      const SizedBox(height: 18),
      Center(
        child: Text(
          'Writing questions for ${widget.role}',
          textAlign: TextAlign.center,
          style: T.body(15, color: AppColors.muted),
        ),
      ),
    ];
  }

  List<Widget> _errorView(String message) {
    return <Widget>[
      const SizedBox(height: 20),
      Text(message, style: T.body(16, color: AppColors.redPen)),
      const SizedBox(height: 16),
      QuietButton(label: 'Try again', wide: true, onPressed: _loadQuestions),
    ];
  }

  List<Widget> _questionView(List<String> questions) {
    final review = _review;
    final isLast = _index == questions.length - 1;

    return <Widget>[
      Text(
        'Question ${_index + 1} of ${questions.length}, for ${widget.role}',
        style: T.body(14, color: AppColors.muted),
      ),
      const SizedBox(height: 8),
      Text(questions[_index], style: T.display(22)),
      const SizedBox(height: 16),
      TextField(
        controller: _answer,
        readOnly: review != null,
        minLines: 6,
        maxLines: 14,
        textCapitalization: TextCapitalization.sentences,
        style: T.body(16),
        decoration: fieldDecoration(
          hint: 'Answer the way you would say it in the room.',
        ),
      ),
      const SizedBox(height: 16),

      if (review == null) ...<Widget>[
        if (!Config.hasAi) ...<Widget>[
          const DemoBanner(
            'Demo mode. Feedback is basic until you add your Gemini key '
            'in lib/config.dart.',
          ),
          const SizedBox(height: 14),
        ],
        PrimaryButton(
          label: 'Check my answer',
          busyLabel: 'Reading your answer',
          busy: _reviewing,
          onPressed: _checkAnswer,
        ),
      ] else ...<Widget>[
        Sheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${review.score} out of 10', style: T.display(22)),
              const SizedBox(height: 8),
              FitBar(score: review.score * 10),
              const SizedBox(height: 16),
              if (review.good.isNotEmpty) TickLine(review.good),
              for (final fix in review.improve) PenNote(fix),
              if (review.better.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text('A stronger answer', style: T.display(16)),
                const SizedBox(height: 6),
                Text(review.better, style: T.body(15)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: isLast ? 'See my results' : 'Next question',
          onPressed: _next,
        ),
        const SizedBox(height: 10),
        QuietButton(
          label: 'Answer this one again',
          wide: true,
          onPressed: _tryAgain,
        ),
      ],
    ];
  }

  List<Widget> _resultsView(List<String> questions) {
    final total = _scores.fold<int>(0, (sum, s) => sum + s);
    final average = _scores.isEmpty ? 0.0 : total / _scores.length;
    final String verdict;
    if (average >= 8) {
      verdict = 'Strong. Keep your answers this specific in the real interview.';
    } else if (average >= 6) {
      verdict = 'A good base. Work on the red notes and run it once more.';
    } else {
      verdict = 'Not ready yet. Practise again, and use real examples and numbers.';
    }

    return <Widget>[
      Text('Practice finished', style: T.display(28)),
      const SizedBox(height: 6),
      Text('For ${widget.role}', style: T.body(15, color: AppColors.muted)),
      const SizedBox(height: 18),
      Sheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${average.toStringAsFixed(1)} out of 10 on average',
              style: T.display(22),
            ),
            const SizedBox(height: 8),
            FitBar(score: (average * 10).round()),
            const SizedBox(height: 14),
            Text(verdict, style: T.body(15)),
            const SizedBox(height: 16),
            for (int i = 0; i < _scores.length && i < questions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(questions[i], style: T.body(14)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_scores[i]}/10',
                      style: T.body(14, color: AppColors.ink, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      PrimaryButton(
        label: 'Practise again with new questions',
        onPressed: _loadQuestions,
      ),
      const SizedBox(height: 10),
      QuietButton(
        label: 'Done',
        wide: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
    ];
  }
}
