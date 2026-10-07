// Holds the user's resume and saved jobs while the app is open, and
// saves them on the phone so they are still there next time.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class AppState extends ChangeNotifier {
  Resume resume = Resume();
  ScanResult? scan;

  /// Jobs the user saved, newest first.
  List<TrackedJob> tracked = <TrackedJob>[];

  static const String _resumeKey = 'resume_v1';
  static const String _trackedKey = 'tracked_v1';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedResume = prefs.getString(_resumeKey);
      if (savedResume != null && savedResume.isNotEmpty) {
        final decoded = jsonDecode(savedResume);
        if (decoded is Map<String, dynamic>) {
          resume = Resume.fromJson(decoded);
        }
      }

      final savedJobs = prefs.getString(_trackedKey);
      if (savedJobs != null && savedJobs.isNotEmpty) {
        final decoded = jsonDecode(savedJobs);
        if (decoded is List) {
          final loaded = <TrackedJob>[];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              loaded.add(TrackedJob.fromJson(item));
            }
          }
          tracked = loaded;
        }
      }
    } catch (_) {
      // If a saved copy cannot be read, carry on with what loaded.
    }
  }

  // ---------------------------------------------------------------
  // Resume
  // ---------------------------------------------------------------

  Future<void> setResume(Resume next) async {
    resume = next;
    scan = null; // the old scan no longer matches the resume
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_resumeKey, jsonEncode(next.toJson()));
    } catch (_) {
      // Saving failed. The resume still works until the app closes.
    }
  }

  void setScan(ScanResult result) {
    scan = result;
    notifyListeners();
  }

  // ---------------------------------------------------------------
  // Saved jobs and application tracking
  // ---------------------------------------------------------------

  /// The saved entry for a job, or null when it is not saved.
  TrackedJob? trackedFor(String jobId) {
    for (final t in tracked) {
      if (t.job.id == jobId) return t;
    }
    return null;
  }

  /// Saves a job, or moves an already saved job to a new stage.
  Future<void> track(Job job, {String stage = Stage.saved}) async {
    final existing = trackedFor(job.id);
    if (existing != null) {
      existing.stage = stage;
      existing.updatedAt = DateTime.now();
    } else {
      tracked.insert(0, TrackedJob(job: job, stage: stage));
    }
    notifyListeners();
    await _saveTracked();
  }

  Future<void> untrack(String jobId) async {
    tracked.removeWhere((t) => t.job.id == jobId);
    notifyListeners();
    await _saveTracked();
  }

  Future<void> _saveTracked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = tracked.map((t) => t.toJson()).toList();
      await prefs.setString(_trackedKey, jsonEncode(list));
    } catch (_) {
      // Saving failed. The list still works until the app closes.
    }
  }
}

/// One shared copy used by every screen.
final AppState appState = AppState();
