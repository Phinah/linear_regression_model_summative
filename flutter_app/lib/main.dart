import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MeaslesPredictorApp());
}

class MeaslesPredictorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Measles Outbreak Predictor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      home: WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(title: Text("Welcome")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("🧬 Measles Outbreak Predictor",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Text(
                "Estimate the likelihood of measles outbreaks using vaccination and population data from African districts including Rwanda, Senegal and Congo, Rep.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                icon: Icon(Icons.arrow_forward),
                label: Text("Start Prediction"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PredictionForm()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PredictionForm extends StatefulWidget {
  @override
  _PredictionFormState createState() => _PredictionFormState();
}

class _PredictionFormState extends State<PredictionForm> {
  final _controllers = List.generate(8, (_) => TextEditingController());
  String _result = '';
  bool _loading = false;

  Future<void> _predict() async {
    final url = Uri.parse(
        'https://measels-model-prediction.onrender.com/predict'); // Replace with public URL when deployed

    final body = {
      "T_TL": double.tryParse(_controllers[0].text) ?? 0.0,
      "T_00_004": double.tryParse(_controllers[1].text) ?? 0.0,
      "Total_Measles_GE1": double.tryParse(_controllers[2].text) ?? 0.0,
      "Total_Measles_L1": double.tryParse(_controllers[3].text) ?? 0.0,
      "Total_Measles2_GE1": double.tryParse(_controllers[4].text) ?? 0.0,
      "Total_Measles2_L1": double.tryParse(_controllers[5].text) ?? 0.0,
      "Total_YF_L1": double.tryParse(_controllers[6].text) ?? 0.0,
      "Total_YF_GE1": double.tryParse(_controllers[7].text) ?? 0.0,
    };

    setState(() {
      _loading = true;
    });

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _result =
              "📈 Estimated Outbreak Cases: ${data['predicted_measles_outbreak'].toStringAsFixed(2)}";
        });
      } else {
        setState(() {
          _result = "❌ Server Error: ${res.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _result = "⚠️ Connection failed: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      "Total Population (T_TL)",
      "Under-5 Population (T_00_004)",
      "Measles Dose 1 ≥1 yr",
      "Measles Dose 1 <1 yr",
      "Measles Dose 2 ≥1 yr",
      "Measles Dose 2 <1 yr",
      "Yellow Fever <1 yr",
      "Yellow Fever ≥1 yr"
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Prediction Form")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "🧾 Input district-level data to predict expected measles outbreak cases.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ...List.generate(8, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: _controllers[i],
                  decoration: InputDecoration(
                    labelText: labels[i],
                    border: OutlineInputBorder(),
                    hintText: 'Enter a number',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              );
            }),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loading ? null : _predict,
              icon: Icon(Icons.calculate),
              label: Text(_loading ? "Predicting..." : "Predict"),
            ),
            SizedBox(height: 20),
            Text(
              _result,
              style: TextStyle(fontSize: 18, color: Colors.deepPurple),
            ),
          ],
        ),
      ),
    );
  }
}
