import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/piano_constants.dart';
import 'virtual_piano_painter.dart';

class VirtualPianoWidget extends StatefulWidget {
  final int startMidiNote;
  final int endMidiNote;
  final Set<int> currentlyPressedKeys;
  final Set<int> activeTargetNotes;
  final Set<int> previewTargetNotes;
  final bool showNoteLabels;
  final ValueChanged<int> onNotePressed;

  const VirtualPianoWidget({
    super.key,
    required this.startMidiNote,
    required this.endMidiNote,
    required this.currentlyPressedKeys,
    required this.activeTargetNotes,
    required this.previewTargetNotes,
    this.showNoteLabels = true,
    required this.onNotePressed,
  });

  @override
  State<VirtualPianoWidget> createState() => _VirtualPianoWidgetState();
}

class _VirtualPianoWidgetState extends State<VirtualPianoWidget> {
  final FocusNode _focusNode = FocusNode();
  // Track pointerId -> midiNote for multi-touch support
  final Map<int, int> _activePointers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  int? _hitTestNote(Offset localPosition, Size size) {
    final whiteNotes = <int>[];
    for (int note = widget.startMidiNote; note <= widget.endMidiNote; note++) {
      if (!PianoConstants.isBlackKey(note)) {
        whiteNotes.add(note);
      }
    }

    if (whiteNotes.isEmpty) return null;

    final whiteKeyWidth = size.width / whiteNotes.length;
    final blackKeyWidth = whiteKeyWidth * 0.62;
    final blackKeyHeight = size.height * 0.63;

    // 1. Hit test black keys first (top layer)
    if (localPosition.dy <= blackKeyHeight) {
      for (int i = 0; i < whiteNotes.length; i++) {
        final note = whiteNotes[i];
        final nextNote = note + 1;
        if (nextNote <= widget.endMidiNote && PianoConstants.isBlackKey(nextNote)) {
          final x = (i + 1) * whiteKeyWidth - (blackKeyWidth / 2);
          final rect = Rect.fromLTWH(x, 0, blackKeyWidth, blackKeyHeight);
          if (rect.contains(localPosition)) {
            return nextNote;
          }
        }
      }
    }

    // 2. Hit test white keys
    if (localPosition.dy >= 0 && localPosition.dy <= size.height) {
      final index = (localPosition.dx / whiteKeyWidth).floor();
      if (index >= 0 && index < whiteNotes.length) {
        return whiteNotes[index];
      }
    }

    return null;
  }

  void _handlePointerDown(PointerDownEvent event, Size size) {
    _focusNode.requestFocus();
    final note = _hitTestNote(event.localPosition, size);
    if (note != null) {
      _activePointers[event.pointer] = note;
      widget.onNotePressed(note);
    }
  }

  void _handlePointerMove(PointerMoveEvent event, Size size) {
    final note = _hitTestNote(event.localPosition, size);
    final prevNote = _activePointers[event.pointer];

    if (note != null && note != prevNote) {
      _activePointers[event.pointer] = note;
      widget.onNotePressed(note);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final char = event.character?.toLowerCase();
      if (char != null && PianoConstants.qwertyKeyToMidi.containsKey(char)) {
        final midiNote = PianoConstants.qwertyKeyToMidi[char]!;
        widget.onNotePressed(midiNote);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Listener(
            onPointerDown: (e) => _handlePointerDown(e, size),
            onPointerMove: (e) => _handlePointerMove(e, size),
            onPointerUp: _handlePointerUp,
            onPointerCancel: _handlePointerCancel,
            child: CustomPaint(
              size: size,
              painter: VirtualPianoPainter(
                startMidiNote: widget.startMidiNote,
                endMidiNote: widget.endMidiNote,
                currentlyPressedKeys: widget.currentlyPressedKeys,
                activeTargetNotes: widget.activeTargetNotes,
                previewTargetNotes: widget.previewTargetNotes,
                showNoteLabels: widget.showNoteLabels,
              ),
            ),
          );
        },
      ),
    );
  }
}
