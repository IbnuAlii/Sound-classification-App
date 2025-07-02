// import 'dart:typed_data';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'somali_translations.dart';

// Simple Category class
class Category {
  final String label;
  final double score;
  final String somaliLabel;

  Category(this.label, this.score)
    : somaliLabel = SomaliTranslations.getSomaliTranslation(label);

  // Get display label (Somali if available, otherwise English)
  String get displayLabel => somaliLabel != label ? somaliLabel : label;
}

class Classifier {
  Interpreter? interpreter;
  late InterpreterOptions _interpreterOptions;

  List<int>? _outputShape;

  final String _modelFileName = 'assets/yamnet.tflite';
  final String _labelFileName = 'assets/yamnet_class_map.csv';

  static const int sampleRate = 16000;

  Map<int, String> labels = {};

  Classifier({int? numThreads}) {
    _interpreterOptions = InterpreterOptions();

    if (numThreads != null) {
      _interpreterOptions.threads = numThreads;
    }

    loadModel();
    loadLabels();
  }

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset(
        _modelFileName,
        options: _interpreterOptions,
      );
      print('Interpreter Created Successfully');

      _outputShape = interpreter!.getOutputTensor(0).shape;
    } catch (e) {
      print('Unable to create interpreter, Caught Exception: ${e.toString()}');
    }
  }

  Future<void> loadLabels() async {
    labels = await loadLabelsFile(_labelFileName);
  }

  List<Category> predict(List<int> audioSample) {
    try {
      if (interpreter == null) {
        print('Interpreter not initialized yet');
        return [];
      }

      // Ensure input size matches model expectation (15600 elements)
      var input = Float32List(15600);

      // Normalize audio data to [-1, 1] as float32
      for (int i = 0; i < 15600; i++) {
        if (i < audioSample.length) {
          // int16 PCM normalization
          input[i] = audioSample[i] / 32768.0;
        } else {
          // Pad with zeros if audio sample is too short
          input[i] = 0.0;
        }
      }

      print('Predict: input length: \\n${input.length}');
      print('Predict: first 20 input values: \\n${input.take(20).toList()}');

      // Create output tensor with correct shape [1, 521]
      var output = List.generate(1, (i) => List.filled(521, 0.0));

      // Run inference
      interpreter!.run(input, output);

      Map<String, double> labeledProb = {};
      for (int i = 0; i < 521; i++) {
        if (labels.containsKey(i)) {
          labeledProb[labels[i]!] = output[0][i];
        }
      }
      return getTopProbability(labeledProb);
    } catch (e) {
      print('Prediction error: ${e.toString()}');
      return [];
    }
  }

  void close() {
    interpreter?.close();
  }
}

List<Category> getTopProbability(Map<String, double> labeledProb) {
  var pq = PriorityQueue<MapEntry<String, double>>(compare);
  pq.addAll(labeledProb.entries);
  var result = <Category>[];
  while (pq.isNotEmpty && result.length < 5) {
    result.add(Category(pq.first.key, pq.first.value));
    pq.removeFirst();
  }
  return result;
}

int compare(MapEntry<String, double> e1, MapEntry<String, double> e2) {
  if (e1.value > e2.value) {
    return -1;
  } else if (e1.value == e2.value) {
    return 0;
  } else {
    return 1;
  }
}

Future<Map<int, String>> loadLabelsFile(String fileAssetLocation) async {
  try {
    final fileString = await rootBundle.loadString(fileAssetLocation);
    return labelListFromString(fileString);
  } catch (e) {
    print('Error loading labels: ${e.toString()}');
    return {};
  }
}

Map<int, String> labelListFromString(String fileString) {
  var classMap = <int, String>{};
  final newLineList = fileString.split('\n');
  for (var i = 1; i < newLineList.length; i++) {
    final entry = newLineList[i].trim();
    if (entry.length > 0) {
      final data = entry.split(',');
      if (data.length >= 3) {
        try {
          classMap[int.parse(data[0])] = data[2];
        } catch (e) {
          print('Error parsing label: ${e.toString()}');
        }
      }
    }
  }
  return classMap;
}
