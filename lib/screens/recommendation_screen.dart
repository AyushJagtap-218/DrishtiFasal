import 'package:flutter/material.dart';
import '../services/recommendation_service.dart';

class RecommendationScreen extends StatefulWidget {
  @override
  _RecommendationScreenState createState() =>
      _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final RecommendationService service = RecommendationService();

  Map<String, dynamic>? result;

  @override
  void initState() {
    super.initState();
    service.loadData(); // load CSV once
  }

  void getData() {
    var res = service.getRecommendation(
      crop: "Apple",
      stage: "Vegetative",
      symptomCategory: "Leaf spot",
      temp: 25,
      humidity: 70,
      rainfall: 110,
    );

    setState(() {
      result = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Crop Recommendation")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: getData,
              child: Text("Get Recommendation"),
            ),

            SizedBox(height: 20),

            if (result != null) ...[
              Text("Disease: ${result!["Disease"]}"),
              SizedBox(height: 10),
              Text("Symptoms:\n${result!["Symptoms"]}"),
              SizedBox(height: 10),
              Text("Prevention:\n${result!["Prevention"]}"),
              SizedBox(height: 10),
              Text("Treatment:\n${result!["Treatment"]}"),
            ]
          ],
        ),
      ),
    );
  }
}