import "package:google_generative_ai/google_generative_ai.dart";
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import "package:flutter_markdown/flutter_markdown.dart";
import 'package:http/http.dart' as http;
import 'dart:developer' as dev;

class AnalysisPage extends StatefulWidget {
  late final List _nutritionSum;
  late final List _nutritionMean;
  late final List _fileType;
  final _nutritionType = [
    "Energy",
    "Protein",
    "Carboh",
    "Sugar",
    "Fibre",
    "Fat",
    "Cholesterol",
    "Minerals",
    "Vitamins"
  ];
  late final List _imageData;

  AnalysisPage(
      {super.key,
      required List<dynamic> nutritionSum,
      required List<dynamic> nutritionMean,
      required List<String> fileType,
      required List<Uint8List> imageData}) {
    _nutritionSum = nutritionSum;
    _nutritionMean = nutritionMean;
    _fileType = fileType;
    _imageData = imageData;
  }

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  late Future _getAnalysis;
  final _model = GenerativeModel(
      model: "gemini-1.5-flash",
      apiKey: 'AIzaSyAYQ8RgguGiAgRRjTWguR8OLzhNuV7vM7A');

  Future<String> getAnalysis() async {
      try {
        var prompt =
            """
            You are an expert in nutritionist who helps the customer to analyze their sum of nutrition values of the recent ${widget._fileType.length} of meals.
            The nutrition provided as below:
            """;
        for (int i = 0; i < widget._nutritionType.length; i++) {
          if (i > 0) {
            prompt += "${widget._nutritionType[i]}:${widget._nutritionSum[i]} gram\n";
          } else{
            prompt += "${widget._nutritionType[i]}:${widget._nutritionSum[i]} kcal\n";
          }
        }
        prompt +=
            """
            The images are also included please recognize the type of meals in each images and
            please return a short analysis from the aspect of 
            possible consequences like NCD, obesity, high blood glucose, high blood pressure, high cholesterol 
            by compared to the normal intake per meal of an adult which provided as below:
            Energy (Calories): 600-800 calories
            Protein: 20-30 grams
            Carbohydrates: 45-75 grams
            Sugar: Up to 25 grams
            Fibre: 5-10 grams
            Fat: 10-20 grams
            Cholesterol: Less than 300 milligrams
            The user intake per meal for each nutrition is provided as below:\n
            """;
          for (int i = 0; i < widget._nutritionType.length; i++) {
            if (i > 0) {
              prompt += "${widget._nutritionType[i]}:${widget._nutritionMean[i]} gram\n";
            } else{
              prompt += "${widget._nutritionType[i]}:${widget._nutritionMean[i]} kcal\n";
            }
          }
        prompt +=
            """
            Also considering enough nutrtion or not etc in 200 words based on these consumptions,
            remember mention the values provided. You may use markdown syntax to emphasize the important parts.
            """;
        var imageParts = [];
        final p = TextPart(prompt);
        for (int i = 0; i < widget._imageData.length; i++) {
          imageParts.add(DataPart("image/${widget._fileType[i]}", widget._imageData[i]));
        }

        final response = await _model.generateContent([
          Content.multi([p, ...imageParts])
        ]);
        dev.log(response.text!);
        return response.text!;
      } catch (e) {
        dev.log("Error : ${e.toString()}");
        return "Error";
      }
    }
  
  // Default page
  // Future<String> getAnalysis() async {
  //   var duration = Duration(seconds: 1, milliseconds: 500);
  //   await Future.delayed(duration);

  //   // Load explanation from a local asset file (replace with your logic)
  //   var response = await rootBundle.loadString("assets/analysis.txt");
  //   // log(response.text!);
  //   return response;
  // }

  @override
  void initState() {
    _getAnalysis = getAnalysis();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Analysis'),
      ),
      body: FutureBuilder(
        future: _getAnalysis,
        builder: (context, snapshot) {
          dev.log(snapshot.connectionState.toString());
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const Center(child: CircularProgressIndicator());
            default:
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(
                        bottom: 5.0, left: 8.0, right: 8.0),
                    child: SafeArea(
                      child: SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            const Center(
                              child: Text(
                                'Nutrition Details (kcal or g)',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 5),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3,
                              childAspectRatio: 1.2,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 5,
                              children: <Widget>[
                                NutritionInfoCard(
                                  icon: Icons.local_fire_department,
                                  label: widget._nutritionType[0],
                                  value: widget._nutritionSum[0],
                                ),
                                NutritionInfoCard(
                                  icon: Icons.fitness_center,
                                  label: widget._nutritionType[1],
                                  value: widget._nutritionSum[1],
                                ),
                                NutritionInfoCard(
                                  icon: Icons.fastfood,
                                  label: widget._nutritionType[2],
                                  value: widget._nutritionSum[2],
                                ),
                                NutritionInfoCard(
                                  icon: Icons.cake,
                                  label: widget._nutritionType[3],
                                  value: widget._nutritionSum[3],
                                ),
                                NutritionInfoCard(
                                  icon: Icons.grain,
                                  label: widget._nutritionType[4],
                                  value: widget._nutritionSum[4],
                                ),
                                NutritionInfoCard(
                                  icon: Icons.local_pizza,
                                  label: widget._nutritionType[5],
                                  value: widget._nutritionSum[5],
                                ),
                                NutritionInfoCard(
                                  icon: Icons.egg,
                                  label: widget._nutritionType[6],
                                  value: widget._nutritionSum[6],
                                ),
                                NutritionInfoCard(
                                  icon: Icons.scatter_plot,
                                  label: widget._nutritionType[7],
                                  value: widget._nutritionSum[7],
                                ),
                                NutritionInfoCard(
                                  icon: Icons.local_florist,
                                  label: widget._nutritionType[8],
                                  value: widget._nutritionSum[8],
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            const Center(
                              child: Text(
                                'Analysis',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: snapshot.data != "Error"
                                      ? MarkdownBody(
                                          data: snapshot.data,
                                          selectable: true,
                                          styleSheet: MarkdownStyleSheet(
                                            h1: const TextStyle(fontSize: 20),
                                            p: const TextStyle(fontSize: 16),
                                          ),
                                        )
                                      : ElevatedButton(
                                          child: null,
                                          onPressed: () {},
                                        )),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  return const Center(child: Text('Something went wrong'));
                }
              }
          }
        },
      ),
    );
  }
}

class NutritionInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;

  NutritionInfoCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 24),
            SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 3),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
