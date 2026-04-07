import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class RecommendationService {
  List<Map<String, dynamic>> _data = [];

  // ✅ Normalize function (CRITICAL FIX)
    String normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s]'), ''); // remove weird chars
    }

  // Load CSV
  Future<void> loadData() async {
    final rawData =
        await rootBundle.loadString('assets/data/crop_stage_disease_mapping.csv');

    List<List<dynamic>> csvTable =
        const CsvToListConverter(eol: '\n').convert(rawData);

    List<String> headers =
        csvTable.first.map((e) => e.toString()).toList();

    for (int i = 1; i < csvTable.length; i++) {
      Map<String, dynamic> row = {};

      for (int j = 0; j < headers.length; j++) {
        row[headers[j]] = csvTable[i][j];
      }

      // ✅ STRONG NORMALIZATION (FIX)
      row["Crop"] = normalize(row["Crop"].toString());
      row["Disease"] = normalize(row["Disease"].toString());
      row["Crop_Stage"] = normalize(row["Crop_Stage"].toString());
      row["Symptoms Category"] =
          normalize(row["Symptoms Category"].toString());

      _data.add(row);
    }

    print("✅ CSV Loaded: ${_data.length}");
  }

  // Helper: split "|" into numbered list
  String formatMultiLine(String text) {
    List<String> parts =
        text.split('|').map((e) => e.trim()).toList();

    return parts
        .asMap()
        .entries
        .map((e) => "${e.key + 1}. ${e.value}")
        .join("\n");
  }

  Map<String, dynamic>? getRecommendation({
    required String crop,
    required String disease, // ✅ ADD THIS
    String? stage,
    String? symptomCategory,
    double? temp,
    double? humidity,
    double? rainfall,
  }) {
    // ✅ Normalize inputs
    crop = normalize(crop);
    disease = normalize(disease);
    stage = stage != null ? normalize(stage) : null;
    symptomCategory =
        symptomCategory != null ? normalize(symptomCategory) : null;

    print("========== DEBUG ==========");
    print("Crop: $crop");
    print("Disease: $disease");
    print("Stage: $stage");
    print("===========================");

    // ✅ STEP 1: FILTER BY DISEASE (PRIMARY FIX)
    var filtered =
        _data.where((e) => e["Disease"].toString().contains(disease)).toList();

    // ✅ OPTIONAL: Further refine by crop
    filtered = filtered.where((e) => e["Crop"] == crop).toList();

    // ✅ Stage filter
    if (stage != null) {
      filtered =
          filtered.where((e) => e["Crop_Stage"] == stage).toList();
    }

    // ✅ Symptoms category filter
    if (symptomCategory != null) {
      filtered = filtered
          .where((e) => e["Symptoms Category"] == symptomCategory)
          .toList();
    }

    // ❌ If nothing found → fallback
    if (filtered.isEmpty) {
      print("❌ NO MATCH FOUND → fallback");

      filtered = _data
          .where((e) => e["Disease"].toString().contains(disease))
          .toList();

      if (filtered.isEmpty) return null;
    }

    // ✅ SCORING SYSTEM
    for (var item in filtered) {
      int score = 0;

      double tempMin =
          double.tryParse(item["Temp_min (Deg. Celcius)"].toString()) ?? 0;
      double tempMax =
          double.tryParse(item["Temp_max (Deg. Celcius)"].toString()) ?? 0;
      double hum =
          double.tryParse(item["Humidity (in %)"].toString()) ?? 0;
      double rain =
          double.tryParse(item["Rainfall(in mm)"].toString()) ?? 0;

      if (temp != null && temp >= tempMin && temp <= tempMax) score++;
      if (humidity != null && (hum - humidity).abs() <= 10) score++;
      if (rainfall != null && (rain - rainfall).abs() <= 20) score++;

      if (item["Is_Dominant"].toString().toLowerCase() == "true") score++;

      item["score"] = score;
    }

    // ✅ SORT BEST MATCH
    filtered.sort((a, b) {
      int scoreCompare = (b["score"] ?? 0).compareTo(a["score"] ?? 0);
      if (scoreCompare != 0) return scoreCompare;

      int occA = int.tryParse(a["Occurrences"].toString()) ?? 0;
      int occB = int.tryParse(b["Occurrences"].toString()) ?? 0;

      return occB.compareTo(occA);
    });

    var best = filtered.first;

    print("✅ MATCH FOUND: ${best["Disease"]}");

    return {
      "Disease": best["Disease"],
      "Symptoms": formatMultiLine(best["Symptoms"]),
      "Prevention": formatMultiLine(best["Prevention"]),
      "Treatment": formatMultiLine(best["Treatment"]),
    };
  }
}