import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'loading_screen.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class ImageWeatherInputScreen extends StatefulWidget {
  const ImageWeatherInputScreen({super.key});

  @override
  State<ImageWeatherInputScreen> createState() => _ImageWeatherInputScreenState();
}

class _ImageWeatherInputScreenState extends State<ImageWeatherInputScreen> {

  File? selectedImage;
  final ImagePicker picker = ImagePicker();

  final TextEditingController temperature = TextEditingController();
  final TextEditingController humidity = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    try {
      final locationService = LocationService();
      final weatherService = WeatherService();

      final position = await locationService.getLocation();

      final data = await weatherService.fetchWeather(
        position.latitude,
        position.longitude,
      );

      temperature.text = data['main']['temp'].toString();
      humidity.text = data['main']['humidity'].toString();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching weather: $e")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  // 📁 Gallery
  Future pickFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  // 📷 Camera
  Future pickFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  // 🔥 Bottom Sheet
  void showImageSourceSelector() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  pickFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void predictDisease() {
    if (selectedImage == null ||
        temperature.text.isEmpty ||
        humidity.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all inputs")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoadingScreen(image: selectedImage!),
      ),
    );
  }

  Widget weatherField(IconData icon, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.green),
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Smart Prediction")),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  GestureDetector(
                    onTap: showImageSourceSelector, // 🔥 UPDATED
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: selectedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_a_photo, size: 50, color: Colors.green),
                                SizedBox(height: 10),
                                Text("Upload Crop Image"),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(selectedImage!, fit: BoxFit.cover),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  weatherField(Icons.thermostat, "Temperature (°C)", temperature),
                  weatherField(Icons.water_drop, "Humidity (%)", humidity),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: predictDisease,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Predict Disease"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}