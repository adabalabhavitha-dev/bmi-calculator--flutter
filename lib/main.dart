import 'package:flutter/material.dart';

void main() {
  runApp(const BMIApp());
}

class BMIApp extends StatelessWidget {
  const BMIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BMI Calculator',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const BMIHomePage(),
    );
  }
}

class BMIHomePage extends StatefulWidget {
  const BMIHomePage({super.key});

  @override
  State<BMIHomePage> createState() => _BMIHomePageState();
}

class _BMIHomePageState extends State<BMIHomePage> {
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  double? bmi;
  String result = "";

  void calculateBMI() {
    double? height = double.tryParse(heightController.text);
    double? weight = double.tryParse(weightController.text);

    if (height == null || weight == null || height <= 0 || weight <= 0) {
      setState(() {
        result = "Please enter valid values";
        bmi = null;
      });
      return;
    }

    // Convert height from centimeters to meters
    double heightInMeters = height / 100;

    double calculatedBMI = weight / (heightInMeters * heightInMeters);

    setState(() {
      bmi = calculatedBMI;

      if (calculatedBMI < 18.5) {
        result = "Underweight";
      } else if (calculatedBMI < 25) {
        result = "Normal Weight";
      } else if (calculatedBMI < 30) {
        result = "Overweight";
      } else {
        result = "Obesity";
      }
    });
  }

  void resetBMI() {
    heightController.clear();
    weightController.clear();

    setState(() {
      bmi = null;
      result = "";
    });
  }

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      appBar: AppBar(
        title: const Text(
          "BMI Check",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A6CF7),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            // Header
            const SizedBox(height: 10),

            const Text(
              "Know Your Body",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Enter your details to calculate your BMI",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            // Height input
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Height",
                hintText: "Enter height in cm",
                prefixIcon: const Icon(Icons.height),
                suffixText: "cm",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Weight input
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Weight",
                hintText: "Enter weight in kg",
                prefixIcon: const Icon(Icons.monitor_weight),
                suffixText: "kg",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Calculate button
            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: calculateBMI,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6CF7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),

                child: const Text(
                  "Calculate BMI",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Result
            if (bmi != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),

                child: Column(
                  children: [

                    const Text(
                      "YOUR BMI",
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 2,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      bmi!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A6CF7),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      result,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: getResultColor(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      getMessage(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Reset button
            if (bmi != null)
              TextButton.icon(
                onPressed: resetBMI,
                icon: const Icon(Icons.refresh),
                label: const Text("Calculate Again"),
              ),

            const SizedBox(height: 15),

            const Text(
              "BMI is a general health indicator.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getResultColor() {
    if (bmi == null) {
      return Colors.grey;
    }

    if (bmi! < 18.5) {
      return Colors.orange;
    } else if (bmi! < 25) {
      return Colors.green;
    } else if (bmi! < 30) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }

  String getMessage() {
    if (bmi == null) {
      return "";
    }

    if (bmi! < 18.5) {
      return "Your BMI is below the usual adult reference range.";
    } else if (bmi! < 25) {
      return "Your BMI is within the usual adult reference range.";
    } else if (bmi! < 30) {
      return "Your BMI is above the usual adult reference range.";
    } else {
      return "Your BMI is in the obesity range.";
    }
  }
}