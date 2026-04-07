import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class ResultScreen extends StatefulWidget {
  final File? image;
  final Map<String, dynamic> result;

  const ResultScreen({
    super.key,
    this.image,
    required this.result,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final List<Map<String, String>> csvRows = [];
  final Map<String, List<Map<String, String>>> diseaseMap = {};

  @override
  void initState() {
    super.initState();
    loadCsv();
  }

  /// ✅ STRONG NORMALIZATION (FIXES ALL MATCH ISSUES)
  String normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^a-z ]'), '')
        .trim();
  }

  /// ✅ SAFE VALUE ACCESS (FIXES "NO DATA FOUND")
  String getValue(Map row, String key) {
    try {
      return row.entries
          .firstWhere(
            (e) =>
                e.key.toString().trim().toLowerCase() ==
                key.toLowerCase(),
          )
          .value
          ?.toString()
          .trim() ??
          "";
    } catch (e) {
      return "";
    }
  }

  /// ✅ LOAD CSV
  Future<void> loadCsv() async {
    final rawData = await rootBundle
        .loadString('assets/data/crop_stage_disease_mapping.csv');

    final rows = const CsvToListConverter(eol: '\n').convert(rawData);

    final headers = rows.first.map((e) => e.toString()).toList();

    csvRows.clear();
    diseaseMap.clear();
    for (var row in rows.skip(1)) {
      final map = <String, String>{};

      for (var i = 0; i < headers.length; i++) {
        map[headers[i]] =
            row.length > i ? row[i].toString() : "";
      }

      map['_normalizedCrop'] = normalize(map['Crop'] ?? "");
      map['_normalizedDisease'] =
          normalize(map['Disease'] ?? "");
      map['_normalizedStage'] =
          normalize(map['Crop_Stage'] ?? "");

      final normalizedDisease = map['_normalizedDisease'] ?? "";
      if (normalizedDisease.isNotEmpty) {
        diseaseMap.putIfAbsent(normalizedDisease, () => []).add(map);
      }

      csvRows.add(map);
    }

    print("✅ CSV Loaded: ${csvRows.length}");
    setState(() {});
  }

  /// ✅ SPLIT "|" VALUES
  List<String> parseMultiValue(String text) {
    if (text.isEmpty) return [];

    return text
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// ✅ FINAL MATCHING LOGIC (FIXED)
  Map<String, String> getSuggestion() {
    if (csvRows.isEmpty) {
      return {
        'Treatment': "Loading...",
        'Prevention': "Loading...",
        'Symptoms': "Loading...",
        'Crop': "",
        'isHealthy': "false",
      };
    }

    final rawDiseaseLabel =
        widget.result["label"]?.toString().trim() ?? "";
    final normalizedDisease =
        normalize(rawDiseaseLabel);

    final normalizedStage =
        normalize(widget.result["crop_stage"]?.toString() ?? "");

    if (normalizedDisease == "healthy") {
      return {
        'Treatment': "",
        'Prevention': "",
        'Symptoms': "",
        'Crop': "",
        'isHealthy': "true",
      };
    }

    print("========== DEBUG ==========");
    print("Disease: $normalizedDisease");
    print("Stage: $normalizedStage");
    print("===========================");

    bool diseaseMatches(String csvDisease, String inputDisease) {
      if (csvDisease.contains(inputDisease) ||
          inputDisease.contains(csvDisease)) {
        return true;
      }

      final csvWords = csvDisease.split(' ').toSet();
      final inputWords = inputDisease.split(' ').toSet();

      int matchCount =
          inputWords.where((word) => csvWords.contains(word)).length;

      return matchCount >= inputWords.length - 1;
    }

    List<Map<String, String>> candidates = [];
    if (normalizedDisease.isNotEmpty) {
      candidates = diseaseMap[normalizedDisease] ?? [];
    }

    if (candidates.isEmpty) {
      candidates = csvRows.where((row) {
        final csvDisease = row['_normalizedDisease'] ?? "";
        return diseaseMatches(csvDisease, normalizedDisease);
      }).toList();
    }

    if (candidates.isEmpty) {
      print("❌ NO MATCH FOUND → fallback");
      return {
        'Treatment': "Consult agricultural expert for treatment.",
        'Prevention': "Consult agricultural expert for prevention.",
      'Symptoms': "Symptoms not found in database.",
      'Crop': "",
      'isHealthy': "false",
    };
  }

    Map<String, String>? stageMatchRow;

    for (var candidate in candidates) {
      final csvStage = candidate['_normalizedStage'] ?? "";
      if (normalizedStage.isEmpty || csvStage.contains(normalizedStage)) {
        stageMatchRow = candidate;
        break;
      }
    }

    final selectedRow = stageMatchRow ?? candidates.first;

    final treatment = getValue(selectedRow, "Treatment");
    final prevention = getValue(selectedRow, "Prevention");
    final symptoms = getValue(selectedRow, "Symptoms");
    final cropName = getValue(selectedRow, "Crop");

    return {
      'Treatment': treatment.isEmpty
          ? "No treatment data available."
          : treatment,
      'Prevention': prevention.isEmpty
          ? "No prevention data available."
          : prevention,
      'Symptoms': symptoms.isEmpty
          ? "No symptoms data available."
          : symptoms,
      'Crop': cropName,
      'isHealthy': "false",
    };
  }

  @override
  Widget build(BuildContext context) {
    final confidence = widget.result["confidence"] ?? 0.0;
    final cropStage = widget.result["crop_stage"];
    final suggestion = getSuggestion();
    final diseaseRaw = widget.result["label"] ?? "Unknown";
    final detectedCrop = suggestion['Crop']?.toString().trim() ?? "";
    final isHealthy = suggestion['isHealthy'] == "true";

    final treatmentList = isHealthy
        ? <String>[]
        : parseMultiValue(suggestion['Treatment'] ?? "");
    final preventionList = isHealthy
        ? <String>[]
        : parseMultiValue(suggestion['Prevention'] ?? "");
    final symptomsList = isHealthy
        ? <String>[]
        : parseMultiValue(suggestion['Symptoms'] ?? "");

    Widget buildList(List<String> items) {
      if (items.isEmpty) {
        return const Text("No data available",
            style: TextStyle(fontSize: 16));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(items.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              "${index + 1}. ${items[index]}",
              style: const TextStyle(fontSize: 16),
            ),
          );
        }),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prediction Result"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              if (widget.image != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  margin:
                      const EdgeInsets.only(bottom: 25),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(15),
                    image: DecorationImage(
                      image:
                          FileImage(widget.image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const Text(
                "Detected Disease",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(15),
                  child: Text(
                    diseaseRaw,
                    style:
                        const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              if (detectedCrop.isNotEmpty) ...[
                const SizedBox(height: 15),
                const Text(
                  "Detected Crop",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text(
                      detectedCrop,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              const Text(
                "Confidence",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(15),
                  child: Text(
                    "${confidence.toStringAsFixed(2)}%",
                    style:
                        const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (cropStage != null) ...[
                const Text(
                  "Crop Stage",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(15),
                    child: Text(
                      cropStage.toString(),
                      style: const TextStyle(
                          fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (!isHealthy) ...[
                const Text(
                  "Recommended Treatment",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: buildList(treatmentList),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Recommended Prevention",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: buildList(preventionList),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Observed Symptoms",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: buildList(symptomsList),
                  ),
                ),
              ] else ...[
                const Text(
                  "No action required",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: const Text(
                      "The detected leaf looks healthy. No preventive steps are needed right now.",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .popUntil(
                            (route) => route.isFirst);
                  },
                  child:
                      const Text("Back to Home"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
