import 'package:flutter_tts/flutter_tts.dart';

final FlutterTts flutterTts = FlutterTts();

class TextToSpeech {
  Future<void> speak(String text) async {
    await flutterTts.stop();
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(text);
    await flutterTts.setPitch(1);
    await flutterTts.awaitSynthCompletion(true);
    await flutterTts.setSpeechRate(0.4);
  }
}
