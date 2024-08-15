import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import "package:google_generative_ai/google_generative_ai.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "dart:developer";

class ExplainPage extends StatefulWidget {
  late Map<String, dynamic> arguments;
  ExplainPage({super.key, required this.arguments});

  @override
  State<ExplainPage> createState() => _ExplainPageState();
}

class _ExplainPageState extends State<ExplainPage> {
  List prob = [];
  List classes = [];
  String url = "";
  late Future _getAnalysis;

  @override
  void initState() {
    url = widget.arguments["url"];
    for (var key in widget.arguments.keys) {
      if (key == "url") continue;
      classes.add(key);
      prob.add(double.parse(widget.arguments[key]));
    }

    _getAnalysis = getAnalysis();
    super.initState();
  }

  Future<String> getAnalysis() async {
    var _model = GenerativeModel(
          model: "gemini-1.5-flash",
          apiKey: 'AIzaSyAYQ8RgguGiAgRRjTWguR8OLzhNuV7vM7A');
    var prompt =
          """You are a medical expert who help to analyze the medical image of the patient. Please try to analyze the image attached which overlay with the heatmap
          produced by pretrained CNN model to help you make guidance and explanation. The probabilities in percentage of the disease of this medical image having are provided aas following:
                """;
          for (int i = 0; i < prob.length; i++) {
        prompt += "${classes[i]}:${prob[i]}\n";
      }
      prompt += """Please give a easy explanation, assuming the patient is without any medical background, explain in an easy and professional way. You may also mention about the symptoms, treatments, and any related things to the disease.
        Also take a look at the location of the heatmap which may help you to distinguish the abnormal part in the medical image.
      """;
      var imageParts = [];
      final p =TextPart(prompt);
      var img = await http.get(Uri.parse(url));
      var imageData = img.bodyBytes;
      imageParts.add(DataPart('image/jpeg', imageData));

      final response = await _model.generateContent([
        Content.multi([p, ...imageParts])
      ]);
      log(response.text!);
      return response.text!;
  }

  // Default Page
  // Future<String> getAnalysis() async {
  //   var duration = Duration(seconds: 1, milliseconds: 500);
  //   await Future.delayed(duration);

  //   // Load explanation from a local asset file (replace with your logic)
  //   var response = await rootBundle.loadString("assets/template.txt");
  //   // log(response.text!);
  //   return response;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Result and Explanation'),
        ),
        body: Column(children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 2.5, bottom: 2.5, left: 8, right: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.pink[50],
              ),
              height: 150,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: NetworkImage(url), fit: BoxFit.cover),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Prediction result',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: prob.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Text(
                                      "${classes[index]}\t:${prob[index]}",
                                      style: const TextStyle(fontSize: 14)),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<dynamic>(
              future: _getAnalysis,
              builder: (context, snapshot) {
                // print('Snapshot data: ${snapshot.data}');
                // print('Snapshot connection state: ${snapshot.connectionState}');
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.pink[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );

                  default:
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.pink[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: SingleChildScrollView(
                                child: ListTile(
                                    title: const Text(
                                      "Explanation",
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline),
                                    ),
                                    subtitle: MarkdownBody(
                                      data: snapshot.data,
                                      selectable: true,
                                      onTapText: () => {},
                                      styleSheet: MarkdownStyleSheet(
                                        h1: const TextStyle(fontSize: 20),
                                        p: const TextStyle(
                                            fontSize: 16), // new end
                                      ),
                                    )),
                              ),
                            ),
                          ),
                        );
                      } else {
                        return const Expanded(
                          child: Center(
                              child: Text('Something wrong with server')),
                        );
                      }
                    }
                }
              })

          
        ]));
  }
}
