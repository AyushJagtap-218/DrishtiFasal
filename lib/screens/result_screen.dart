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
  final Map<String, List<Map<String, String>>> _diseaseIndex = {};
  bool _csvLoaded = false;
  bool _csvLoadFailed = false;

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
    try {
      final rawData = await rootBundle
          .loadString('assets/data/crop_stage_disease_mapping.csv');

      final rows = const CsvToListConverter(eol: '\n').convert(rawData);

      final headers = rows.first
          .map((e) => e
              .toString()
              .replaceAll('\uFEFF', '')
              .trim())
          .toList();

      csvRows.clear();
      _diseaseIndex.clear();
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
        map['_rawDisease'] = map['Disease']?.toString().trim() ?? "";

        final normalizedDisease = map['_normalizedDisease'] ?? "";
        if (normalizedDisease.isNotEmpty) {
          _diseaseIndex
              .putIfAbsent(normalizedDisease, () => [])
              .add(map);
        }

        csvRows.add(map);
      }

      print(
          "✅ CSV Loaded: ${csvRows.length} rows, ${_diseaseIndex.length} disease keys");
      _csvLoaded = true;
      _csvLoadFailed = false;
    } catch (e) {
      print("❌ CSV load failed: $e");
      _csvLoadFailed = true;
      _csvLoaded = false;
    } finally {
      if (mounted) setState(() {});
    }
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

  List<Map<String, String>> _findRowsForDisease(String normalizedDisease) {
    if (normalizedDisease.isEmpty) return [];

    final direct = _diseaseIndex[normalizedDisease];
    if (direct != null && direct.isNotEmpty) return direct;

    final inputWords = normalizedDisease
        .split(' ')
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toList();
    final threshold = inputWords.length <= 1 ? 1 : inputWords.length - 1;

    String? bestKey;
    int bestScore = -1;

    for (var entry in _diseaseIndex.entries) {
      final key = entry.key;

      if (key.contains(normalizedDisease) ||
          normalizedDisease.contains(key)) {
        return entry.value;
      }

      if (inputWords.isEmpty || key.isEmpty) continue;

      final keyWords = key
          .split(' ')
          .map((word) => word.trim())
          .where((word) => word.isNotEmpty)
          .toSet();

      final matchCount = inputWords
          .where((word) => keyWords.contains(word))
          .length;

      if (matchCount > bestScore) {
        bestScore = matchCount;
        bestKey = entry.key;
      }
    }

    if (bestKey != null && bestScore >= threshold) {
      return _diseaseIndex[bestKey] ?? [];
    }

    return [];
  }

  Map<String, String> _selectRowForStage(
      List<Map<String, String>> matches, String normalizedStage) {
    if (matches.isEmpty) return {};
    if (normalizedStage.isEmpty) return matches.first;

    for (var candidate in matches) {
      final csvStage = candidate['_normalizedStage'] ?? "";
      if (csvStage.isNotEmpty &&
          (csvStage.contains(normalizedStage) ||
              normalizedStage.contains(csvStage))) {
        return candidate;
      }
    }

    return matches.first;
  }

  /// ✅ FINAL MATCHING LOGIC (FIXED)
  Map<String, String> getSuggestion() {
    if (!_csvLoaded && !_csvLoadFailed) {
      return {
        'Treatment': "Loading...",
        'Prevention': "Loading...",
        'Symptoms': "Loading...",
        'Crop': "",
        'isHealthy': "false",
        'loading': "true",
      };
    }

    if (_csvLoadFailed) {
      return {
        'Treatment': "Consult agricultural expert for treatment.",
        'Prevention': "Consult agricultural expert for prevention.",
        'Symptoms': "Symptoms not found in database.",
        'Crop': "",
        'isHealthy': "false",
      };
    }

    return _buildSuggestion();
  }

  Map<String, String> _buildSuggestion() {
    if (csvRows.isEmpty) {
      return {
        'Treatment': "Consult agricultural expert for treatment.",
        'Prevention': "Consult agricultural expert for prevention.",
        'Symptoms': "Symptoms not found in database.",
        'Crop': "",
        'isHealthy': "false",
      };
    }

    final rawDiseaseLabel =
        widget.result["label"]?.toString().trim() ?? "";
    final normalizedDisease = normalize(rawDiseaseLabel);

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

    final matchesRaw = _findRowsForDisease(normalizedDisease);
    final rawLabelKey = rawDiseaseLabel.toLowerCase();

    final matches = matchesRaw.isNotEmpty
        ? matchesRaw
        : csvRows.where((row) {
            final raw = row['_rawDisease']?.toLowerCase() ?? "";
            return raw == rawLabelKey && rawLabelKey.isNotEmpty;
          }).toList();

    if (matches.isEmpty) {
      print("Normalized lookup failed for: $normalizedDisease");
      print("Available disease keys: ${_diseaseIndex.keys.join(', ')}");
      print(
          "❌ NO MATCH FOUND → fallback (raw label: $rawDiseaseLabel, stage: $normalizedStage)");
      return {
        'Treatment': "Consult agricultural expert for treatment.",
        'Prevention': "Consult agricultural expert for prevention.",
        'Symptoms': "Symptoms not found in database.",
        'Crop': "",
        'isHealthy': "false",
      };
    }

    final selectedRow = _selectRowForStage(matches, normalizedStage);

    if (selectedRow.isEmpty) {
      return {
        'Treatment': "Consult agricultural expert for treatment.",
        'Prevention': "Consult agricultural expert for prevention.",
        'Symptoms': "Symptoms not found in database.",
        'Crop': "",
        'isHealthy': "false",
      };
    }

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
    final showLoadingSuggestions = !_csvLoaded && !_csvLoadFailed;
    final suggestionError = _csvLoadFailed;

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

              if (showLoadingSuggestions) ...[
                const Text(
                  "Loading Crop Suggestions...",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: const Text(
                      "Fetching crop information from the offline database...",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ] else if (suggestionError) ...[
                const Text(
                  "Suggestions unavailable",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: const Text(
                      "Could not load the CSV data. Please restart the app.",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ] else if (!isHealthy) ...[
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
