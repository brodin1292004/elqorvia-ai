// Small building blocks shared by all screens.

import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';

const BorderRadius _markerShape = BorderRadius.only(
  topLeft: Radius.circular(2),
  topRight: Radius.circular(8),
  bottomLeft: Radius.circular(8),
  bottomRight: Radius.circular(2),
);

/// Text with a yellow highlighter stroke behind it.
class Marked extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const Marked(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: const BoxDecoration(
        color: AppColors.marker,
        borderRadius: _markerShape,
      ),
      child: Text(text, style: style ?? T.body(13, color: AppColors.ink, weight: FontWeight.w600)),
    );
  }
}

/// A plain outlined skill label (not highlighted).
class SkillChip extends StatelessWidget {
  final String text;
  const SkillChip(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.desk,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(text, style: T.body(13, color: AppColors.text)),
    );
  }
}

/// A white sheet of paper that content sits on.
class Sheet extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const Sheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.sheet,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.line),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(0, 6),
            blurRadius: 18,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// The main action on a screen.
class PrimaryButton extends StatelessWidget {
  final String label;
  final String busyLabel;
  final VoidCallback? onPressed;
  final bool busy;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel = 'Working on it',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.line,
          disabledForegroundColor: AppColors.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: T.body(16, weight: FontWeight.w600),
        ),
        child: busy
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(busyLabel),
                ],
              )
            : Text(label),
      ),
    );
  }
}

/// A second, quieter action.
class QuietButton extends StatelessWidget {
  final String label;
  final String busyLabel;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final bool wide;

  const QuietButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.busyLabel = 'Working on it',
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.ink, width: 1.3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: T.body(15, weight: FontWeight.w600),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null && !busy) ...<Widget>[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(busy ? busyLabel : label),
        ],
      ),
    );
    if (wide) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// A highlighter stroke whose length shows a score from 0 to 100.
class FitBar extends StatelessWidget {
  final int score;
  final double height;
  const FitBar({super.key, required this.score, this.height = 12});

  @override
  Widget build(BuildContext context) {
    final double fraction = score.clamp(0, 100) / 100;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.track,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction,
          heightFactor: 1,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.marker,
              borderRadius: _markerShape,
              border: Border.all(color: AppColors.markerEdge, width: 1),
            ),
          ),
        ),
      ),
    );
  }
}

/// A handwritten red pen note, used for things to fix.
class PenNote extends StatelessWidget {
  final String text;
  const PenNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 14,
            height: 2,
            margin: const EdgeInsets.only(top: 12, right: 8),
            color: AppColors.redPen,
          ),
          Expanded(child: Text(text, style: T.pen(21))),
        ],
      ),
    );
  }
}

/// A line with a green tick, used for things that are already good.
class TickLine extends StatelessWidget {
  final String text;
  const TickLine(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2, right: 8),
            child: Icon(Icons.check, size: 18, color: AppColors.tick),
          ),
          Expanded(child: Text(text, style: T.body(15))),
        ],
      ),
    );
  }
}

/// Shown while the app is running without real keys.
class DemoBanner extends StatelessWidget {
  final String text;
  const DemoBanner(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.markerSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.markerEdge),
      ),
      child: Text(text, style: T.body(13.5, color: AppColors.ink)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30, bottom: 6),
      child: Text(text, style: T.display(20)),
    );
  }
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Four highlighter strokes: Saved, Applied, Interview, Offer.
/// The strokes up to the current stage are filled in.
class StageBar extends StatelessWidget {
  final String stage;
  const StageBar({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    final current = Stage.path.indexOf(stage); // -1 when closed
    return Row(
      children: <Widget>[
        for (int i = 0; i < Stage.path.length; i++)
          Expanded(
            child: Container(
              height: 10,
              margin: EdgeInsets.only(
                right: i == Stage.path.length - 1 ? 0 : 5,
              ),
              decoration: BoxDecoration(
                color: i <= current ? AppColors.marker : AppColors.track,
                borderRadius: _markerShape,
                border: i <= current
                    ? Border.all(color: AppColors.markerEdge, width: 1)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// "today", "yesterday" or "5 days ago".
String agoLabel(DateTime date) {
  final days = DateTime.now().difference(date).inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  return '$days days ago';
}
