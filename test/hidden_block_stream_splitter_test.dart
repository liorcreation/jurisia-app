import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/core/ai/hidden_block_stream_splitter.dart';

void main() {
  group('HiddenBlockStreamSplitter', () {
    const marker = '<<<MARK>>>';

    test('passes through visible text unchanged when the marker never appears', () {
      final splitter = HiddenBlockStreamSplitter(markerStart: marker);
      final emitted = StringBuffer();

      for (final chunk in ['Bonjour, ', 'comment puis-je vous aider ?']) {
        emitted.write(splitter.feed(chunk));
      }
      emitted.write(splitter.flush());

      expect(emitted.toString(), 'Bonjour, comment puis-je vous aider ?');
      expect(splitter.visibleAccumulated.toString(), 'Bonjour, comment puis-je vous aider ?');
      expect(splitter.hidden.toString(), isEmpty);
      expect(splitter.markerFound, isFalse);
    });

    test('strips a marker split across two separate chunks', () {
      final splitter = HiddenBlockStreamSplitter(markerStart: marker);
      final emitted = StringBuffer();

      for (final chunk in ['Texte visible. ', '<<<MA', 'RK>>>{"hidden":true}']) {
        emitted.write(splitter.feed(chunk));
      }
      emitted.write(splitter.flush());

      expect(emitted.toString(), 'Texte visible. ');
      expect(emitted.toString().contains('MARK'), isFalse);
      expect(splitter.hidden.toString(), '<<<MARK>>>{"hidden":true}');
      expect(splitter.markerFound, isTrue);
    });

    test('strips a marker split byte by byte across many tiny chunks', () {
      final splitter = HiddenBlockStreamSplitter(markerStart: marker);
      final emitted = StringBuffer();
      const fullStream = 'Avant. <<<MARK>>>reste-cache';

      for (final char in fullStream.split('')) {
        emitted.write(splitter.feed(char));
      }
      emitted.write(splitter.flush());

      expect(emitted.toString(), 'Avant. ');
      expect(splitter.hidden.toString(), '<<<MARK>>>reste-cache');
    });

    test('handles the marker arriving as the very first chunk', () {
      final splitter = HiddenBlockStreamSplitter(markerStart: marker);
      final emitted = StringBuffer();

      emitted.write(splitter.feed('<<<MARK>>>payload'));
      emitted.write(splitter.flush());

      expect(emitted.toString(), isEmpty);
      expect(splitter.visibleAccumulated.toString(), isEmpty);
      expect(splitter.hidden.toString(), '<<<MARK>>>payload');
    });

    test('ignores empty deltas without affecting the result', () {
      final splitter = HiddenBlockStreamSplitter(markerStart: marker);
      final emitted = StringBuffer();

      for (final chunk in ['Bonjour', '', ' le monde', '']) {
        emitted.write(splitter.feed(chunk));
      }
      emitted.write(splitter.flush());

      expect(emitted.toString(), 'Bonjour le monde');
    });
  });
}
