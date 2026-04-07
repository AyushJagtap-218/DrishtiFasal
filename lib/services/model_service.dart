import 'dart:io';
import 'dart:math' as Math;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class NonLeafImageException implements Exception {
  final String message;

  const NonLeafImageException([
    this.message = "Please upload a leaf image for accurate prediction.",
  ]);

  @override
  String toString() => message;
}

class ModelService {
  Interpreter? _interpreter;

  // ✅ LABELS
  static const List<String> labels = [
    "Apple_scab",
    "Bacterial_spot",
    "Black_rot",
    "Cedar_apple_rust",
    "Cercospora_leaf_spot Gray_leaf_spot",
    "Common_rust_",
    "Early_blight",
    "Esca_(Black_Measles)",
    "Haunglongbing_(Citrus_greening)",
    "Healthy",
    "Late_blight",
    "Leaf_Mold",
    "Leaf_blight_(Isariopsis_Leaf_Spot)",
    "Leaf_scorch",
    "Northern_Leaf_Blight",
    "Powdery_mildew",
    "Septoria_leaf_spot",
    "Spider_mites Two-spotted_spider_mite",
    "Target_Spot",
    "Tomato_Yellow_Leaf_Curl_Virus",
    "Tomato_mosaic_virus",
  ];

  // ✅ SCALER VALUES
  static const List<double> mean = [
    25.2406272,
    68.6932585,
    112.2083132,
    8.50348
  ];

  static const List<double> std = [
    4.42961525,
    16.8270221,
    94.0420894,
    4.610272
  ];

  // ✅ CROP STAGE ENCODING
  static const Map<String, int> cropStageMap = {
    "Flowering": 0,
    "Fruiting": 1,
    "Maturity": 2,
    "Seedling": 3,
    "Vegetative": 4,
  };

  static const double _leafGreenRatioThreshold = 0.12;
  static const int _leafSamplingStep = 6;

  // ✅ WEEK FROM STAGE
  int getWeekFromStage(String stage) {
    switch (stage) {
      case "Seedling":
        return 2;
      case "Vegetative":
        return 6;
      case "Flowering":
        return 10;
      case "Fruiting":
        return 13;
      case "Maturity":
        return 16;
      default:
        return 8;
    }
  }

  // ✅ Normalize
  double normalize(double value, int index) {
    return (value - mean[index]) / std[index];
  }

  // ✅ Load Model
  Future<void> loadModel() async {
    _interpreter ??= await Interpreter.fromAsset(
      'assets/models/hybrid_model_float32.tflite',
    );
    print("✅ Model Loaded");
  }

  // ✅ Image Preprocessing
  List preprocessImage(File imageFile) {
    final image = img.decodeImage(imageFile.readAsBytesSync())!;
    final resized = img.copyResize(image, width: 224, height: 224);

    return [
      List.generate(224, (y) =>
          List.generate(224, (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          }))
    ];
  }

  bool _isLeafImage(File imageFile) {
    final decoded = img.decodeImage(imageFile.readAsBytesSync());
    if (decoded == null) return false;

    int greenPixels = 0;
    int samples = 0;

    for (int y = 0; y < decoded.height; y += _leafSamplingStep) {
      for (int x = 0; x < decoded.width; x += _leafSamplingStep) {
        samples++;
        final pixel = decoded.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        final brightness = (r + g + b) / 3.0;

        final isGreenish = g > r * 1.05 &&
            g > b * 1.05 &&
            g > 60 &&
            brightness > 55;

        if (isGreenish) {
          greenPixels++;
        }
      }
    }

    if (samples == 0) return false;

    final ratio = greenPixels / samples;
    return ratio >= _leafGreenRatioThreshold;
  }

  // ✅ Softmax
  List<double> softmax(List<double> logits) {
    double maxLogit = logits.reduce((a, b) => a > b ? a : b);

    List<double> exps =
        logits.map((x) => Math.exp(x - maxLogit)).toList();

    double sum = exps.reduce((a, b) => a + b);

    return exps.map((e) => e / sum).toList();
  }

  // ✅ Prediction
  Map<String, dynamic> predict({
    File? image,
    double? temperature,
    double? humidity,
    double? rainfall,
    String? cropStage,
  }) {
    if (_interpreter == null) {
      throw Exception("Model not loaded");
    }

    // ✅ Default values if missing (for non-hybrid modes)
    double temp = temperature ?? mean[0];
    double hum = humidity ?? mean[1];
    double rain = rainfall ?? mean[2];
    String stage = cropStage ?? "Vegetative"; // safe default

    int stageEncoded = cropStageMap[stage] ?? 0;
    int week = getWeekFromStage(stage);

    double tempNorm = normalize(temp, 0);
    double humidityNorm = normalize(hum, 1);
    double rainfallNorm = normalize(rain, 2);
    double weekNorm = normalize(week.toDouble(), 3);

    double stageValue = stageEncoded.toDouble();

    List<Object> inputs = [];

    // ✅ IMAGE INPUT (ALWAYS REQUIRED)
    if (image != null) {
      if (!_isLeafImage(image)) {
        throw const NonLeafImageException();
      }

      inputs.add(preprocessImage(image));
    } else {
      // 🔥 Dummy black image
      inputs.add(List.generate(
        1,
        (_) => List.generate(
          224,
          (_) => List.generate(
            224,
            (_) => [0.0, 0.0, 0.0],
          ),
        ),
      ));
    }

    // ✅ TABULAR INPUT (ALWAYS REQUIRED)
    inputs.add([
      [
        tempNorm,
        humidityNorm,
        rainfallNorm,
        weekNorm,
        stageValue,
      ]
    ]);

    var output = List.generate(1, (_) => List.filled(21, 0.0));

    _interpreter!.runForMultipleInputs(
      inputs,
      {0: output},
    );

    List<double> rawOutput = List<double>.from(output[0]);
    List<double> probabilities = softmax(rawOutput);

    return getPredictionResult(
      probabilities,
      stage,
      week,
    );
  }

  // ✅ Final Result (UPDATED)
  Map<String, dynamic> getPredictionResult(
    List<double> probs,
    String cropStage,
    int week,
  ) {
    double maxValue = probs[0];
    int maxIndex = 0;

    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxValue) {
        maxValue = probs[i];
        maxIndex = i;
      }
    }

    return {
      "label": labels[maxIndex],
      "confidence": maxValue * 100,   // ✅ DOUBLE
      "crop_stage": cropStage,        // ✅ STRING
      "week_of_season": week,         // ✅ INT
    };
  }
}
