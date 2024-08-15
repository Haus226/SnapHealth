import 'dart:developer';
import 'package:SnapHealth/pages/analysisPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:dotted_border/dotted_border.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:flutter/services.dart';
import "dart:io";
import 'package:http_parser/http_parser.dart';
import "package:firebase_storage/firebase_storage.dart";
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import "package:easy_image_viewer/easy_image_viewer.dart";
import "package:path_provider/path_provider.dart";
import "dart:collection";

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  AssetEntity? _selectedImage;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  var uid = FirebaseAuth.instance.currentUser!.uid;
  var collection = FirebaseFirestore.instance.collection("user");
  late List<Uint8List> _imageData = [];
  List<String> _history = [];
  int _curNumOfImg = 0;
  List<String> history = [];
  var _isLoading = false;
  late File selectedImage;
  late Future _getHistory;
  final _nutritionType = [
    "Energy/Calori",
    "Protein",
    "Carbohydrates",
    "Sugar",
    "Fibre",
    "Fat",
    "Cholesterol",
    "Minerals",
    "Vitamins"
  ];
  var _nutritionSum = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  late var _nutritionValue = {};
  late var _nutritionMean = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  
  Future<void> downloadAndSaveImage(String url, String fileName) async {
    try {
      // Fetch the image from the network
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Get the directory to save the image
        Directory directory = await getApplicationDocumentsDirectory();
        String path = directory.path;
        await Directory('$path/$uid/').create(recursive: true);
        File file = File('$path/$uid/$fileName');
        // Write the image data to the file
        await file.writeAsBytes(response.bodyBytes);
        log('Image saved to: ${file.path}');
        setState(() {
            _history.insert(0, '$path/$uid/$fileName');
            if (history.length == 22) {
              _history.removeLast();
            }
        });


      } else {
        log('Error downloading image: ${response.statusCode}');
      }
    } catch (e) {
      log('Error downloading image: $e');
    }
  }

  // Set the url to "http://10.0.2.2:port in Flask app/" if debug with emulator
  Future fromGallery({String URL = "http://10.0.2.2:8000/"}) async {
    Directory directory = await getApplicationDocumentsDirectory();
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(
        requestType: RequestType.image,
        maxAssets: 1,
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedImage = result.first;
        _isLoading = true;
      });
      selectedImage = (await _selectedImage!.file)!;

      try {
        await http
            .get(Uri.parse("$URL/test"))
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          )),
          content: Text("The server is not running, please try again later...",
              style: GoogleFonts.lora(fontSize: 20, color: Colors.black)),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.amber[300]!.withOpacity(0.9),
        ));
      }

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$URL/predict"),
      );

      Map<String, String> headers = {"Content-type": "multipart/form-data"};
      request.files.add(
        http.MultipartFile(
          "image",
          selectedImage.readAsBytes().asStream(),
          selectedImage.lengthSync(),
          filename: selectedImage.path.split("/").last,
          contentType: MediaType(
              'image', selectedImage.path.split("/").last.split(".").last),
        ),
      );

      request.headers.addAll(headers);
      // log("request: $request");

      try {
        var streamedResponse =
            await request.send().timeout(const Duration(seconds: 60));
        var response = await http.Response.fromStream(streamedResponse);
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        // log('Response: $jsonResponse');

        String type = selectedImage.path.split("/").last.split(".").last;
        DateTime now = DateTime.now();
        String p =
            "${now.minute}_${now.hour}_${now.day}_${now.month}_${now.year}";
        String nutrition =
            "${jsonResponse["energy"]}_${jsonResponse["protein"]}_${jsonResponse["carbohydrates"]}_${jsonResponse["sugars"]}_${jsonResponse["fiber"]}_${jsonResponse["fat"]}_${jsonResponse["cholesterol"]}_${jsonResponse["minerals"]}_${jsonResponse["vitamins"]}";



        final storageRef = _storage.ref();
        final imagesRef = storageRef.child(
            "${FirebaseAuth.instance.currentUser!.displayName!}/${_curNumOfImg}_${p}_$nutrition.$type");
        await imagesRef.putFile(selectedImage);
        String url = await imagesRef.getDownloadURL();
        await downloadAndSaveImage(url, '${_curNumOfImg}_${p}_$nutrition.$type');
        await imagesRef.delete();
        setState(() {
          _curNumOfImg += 1;
          _isLoading = false;
        });

        // Get the current user
        final user = FirebaseAuth.instance.currentUser;

        // if (user != null) {
        //   // Update the nutrition field in Firestore
        //   FirebaseFirestore.instance.collection('user').doc(user.uid).update({
        //     'nutrition': history,
        //   }).then((value) {
        //     log("User's nutrition updated successfully");
        //   }).catchError((error) {
        //     log("Failed to update user's nutrition: $error");
        //   });
        // }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Something wrong with the server, please try again...",
              style: GoogleFonts.lora(fontSize: 20, color: Colors.black)),
          duration: const Duration(seconds: 5),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          backgroundColor: Colors.red[300]!.withOpacity(0.9),
        ));
      }
    }
  }

  List<String> computeNutrition() {
      _nutritionSum = _nutritionSum.map((e) => 0.0).toList();
      _nutritionMean = _nutritionMean.map((e) => 0.0).toList();
      log(_history.length.toString());
      List<String> fileType = [];
      for (var filepath in _history) {
        var data = filepath.split("/").last;
        // data = extractString(data);
        var data_ = data.split("_");
        log(data_.toString());
        var date = "${data_[5]}/${data_[4]}/${data_[3]}";
        var idx = data_[14].lastIndexOf(".");
        fileType.add(data_[14].substring(idx));
        data_[14] = data_[14].substring(0, idx);
        if (!_nutritionValue.containsKey(filepath)) {
          _nutritionValue[filepath] = [
              'Date: $date',
              "Energy: ${data_[6]} kcal",
              "Carbohydrates: ${data_[8]} g",
              "Protein: ${data_[7]} g",
              "Sugar: ${data_[9]} g",
              "Fibre: ${data_[10]} g",
              "Fat: ${data_[11]} g",
              "Cholesterol: ${data_[12]} g",
              "Minerals: ${data_[13]} g",
              "Vitamins: ${data_[14]} g"

          ];
        }
        for (int i = 0; i < _nutritionType.length; i++) {
          _nutritionSum[i] += double.parse(data_[6 + i]);
        }
        for (int i = 0; i < _nutritionType.length; i++) {
          _nutritionMean[i] = _nutritionSum[i] / _history.length;
        }
      }
      return fileType;
  }

  String extractString(String url) {
    final regex = RegExp(r'%2F(.*?)\?');
    final match = regex.firstMatch(url);
    if (match != null) {
      return match.group(1) ?? '';
    }
    return '';
  }

  // Future<void> loadImage() async {
  //   for (var url in history) {
  //   final networkAssetBundle = NetworkAssetBundle(Uri.parse(url));
  //   final ByteData? byteData = await networkAssetBundle.load('');
  //   imageData.add(byteData?.buffer.asUint8List());
  //   }
  // }

  Widget foodCard(String url, int index) {
    return Padding(
        padding:
            const EdgeInsets.only(top: 2.5, bottom: 2.5, left: 8, right: 8),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            height: 120,
            child: Row(
              children: [
                Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () {
                        showImageViewer(context, Image(
            image: FileImage(File(_history[index]))).image,
                            doubleTapZoomable: true, swipeDismissible: true);
                      },
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              image: Image(image: FileImage(File(_history[index])))
                                      .image, fit: BoxFit.cover),
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                        ),
                      ),
                    )),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nutritionValue[url][0],
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Nutritional Values',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _nutritionValue[url].length - 1,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(_nutritionValue[url][index + 1],
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
        ));
  }

  // Incompleted yet refer to fromGallery
  Future fromCamera({String URL = "http://10.0.2.2:8000/"}) async {
    final AssetEntity? entity = await CameraPicker.pickFromCamera(context);

    if (entity != null) {
      setState(() {
        _selectedImage = entity;
        _isLoading = !_isLoading;
      });
      selectedImage = (await _selectedImage!.file)!;
      final storageRef = _storage.ref();
      final imagesRef =
          storageRef.child(FirebaseAuth.instance.currentUser!.displayName!);
      imagesRef.putFile(selectedImage);
      try {
        await http
            .get(Uri.parse("$URL/test"))
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        setState(() {
          _isLoading = !_isLoading;
        });
        return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          )),
          content: Text("The server is not running, please try again later...",
              style: GoogleFonts.lora(fontSize: 20, color: Colors.black)),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.amber[300]!.withOpacity(0.9),
        ));
      }

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$URL/predict"),
      );

      Map<String, String> headers = {"Content-type": "multipart/form-data"};
      request.files.add(
        http.MultipartFile(
          "image",
          selectedImage.readAsBytes().asStream(),
          selectedImage.lengthSync(),
          filename: selectedImage.path.split("/").last,
          contentType: MediaType(
              'image', selectedImage.path.split("/").last.split(".").last),
        ),
      );

      request.headers.addAll(headers);
      log("request: $request");

      try {
        var streamedResponse =
            await request.send().timeout(const Duration(seconds: 60));
        var response = await http.Response.fromStream(streamedResponse);
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        log('Response: $jsonResponse');

        setState(() {
          _isLoading = !_isLoading;
        });
      } catch (e) {
        setState(() {
          _isLoading = !_isLoading;
        });
        return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Something wrong with the server, please try again...",
              style: GoogleFonts.lora(fontSize: 20, color: Colors.black)),
          duration: const Duration(seconds: 5),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          backgroundColor: Colors.red[300]!.withOpacity(0.9),
        ));
      }
    }
  }

  @override
  void initState() {
    _getHistory = getHistory();
    super.initState();
  }

  Future<List<String>> getHistory() async {
    
    // Get the directory path where you saved the images
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path + '/$uid';
    // final dir = Directory(path);
    // dir.deleteSync(recursive: true);
    log("Path:$path");
    try {
      // List all files in the directory
      final files = await Directory(path).list().toList();

      // Convert files to a list of filenames and sort by extracted number (descending)
      final filenames = files.map((file) => file.path).toList()
      ..sort((a, b) {
          log("a:$a");
          log("b:$b");
          // Extract filename without extension
          final filenameWithoutExtA = a.substring(0, a.lastIndexOf('.'));
          final filenameWithoutExtB = b.substring(0, b.lastIndexOf('.'));

          // Extract number (assuming first part)
          final fileNameA = int.parse(filenameWithoutExtA.split('/').last.split("_").first);
          log("filenameA:$fileNameA");
          final fileNameB = int.parse(filenameWithoutExtB.split('/').last.split("_").first);
          return fileNameB.compareTo(fileNameA); // Descending order
        });
      _curNumOfImg = filenames.length;
      if (filenames.length > 21) {
        _history = filenames.sublist(0, 21);
      } else {
        _history = filenames;
      }
      for (var filepath in _history) {
        _imageData.add(await File(filepath).readAsBytes());
      }
      return _history;
    } catch (e) {
      log(e.toString());
      return _history;
    }
  }


  // Store image on cloud
  // Future<List> getHistory() async {

  //   // DocumentSnapshot documentSnapshot = await collection.doc(uid).get();
  //   // if (documentSnapshot.exists) {
  //   //   var data = documentSnapshot.data() as Map<String, dynamic>;
  //   //   history = (data["nutrition"] as List<dynamic>).map((e) => e.toString()).toList() ?? [];
  //   // }
  //   // await loadImage();
  //   return history;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Nutrition Detector"),
          backgroundColor: Colors.white), // <-- App bar
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 8, right: 8, bottom: 2.5, top: 2.5),
            child: GestureDetector(
              onTap: fromGallery,
              child: DottedBorder(
                color: Colors.blue,
                strokeWidth: 2,
                dashPattern: const [6, 3],
                borderType: BorderType.RRect,
                radius: const Radius.circular(20),
                child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                        // decoration: BoxDecoration(color: Colors.white),
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: !_isLoading
                            ? const Text(
                                "Select from Gallery",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              )
                            : const CircularProgressIndicator())),
              ),
            ),
          ),
          FutureBuilder<dynamic>(
              future: _getHistory,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(),
                              ),
                            ),
                          ),
                          const Expanded(
                              child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              CircularProgressIndicator(),
                            ],
                          ))
                        ],
                      ),
                    );
                  default:
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {  
                        var fileType = computeNutrition();
                        log(_nutritionMean.toString());
                        log(_nutritionSum.toString());
                        return Expanded(
                          child: Column(
                            children: [
                                  Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0,
                                          right: 8.0,
                                          top: 2.5,
                                          bottom: 2.5),
                                      child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AnalysisPage(
                                                          nutritionSum:_nutritionSum,
                                                          nutritionMean:_nutritionMean,
                                                          fileType:fileType, 
                                                          imageData: _imageData),
                                                ));
                                          },
                                          child: Card(
                                              elevation: 4,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  height: 60,
                                                  child: const Padding(
                                                      padding:
                                                          EdgeInsets.only(
                                                              left: 8.0,
                                                              right: 8.0,
                                                              top: 2.5,
                                                              bottom: 2.5),
                                                      child: Center(
                                                        child: Text(
                                                              'Analysis from Our AI',
                                                          style: TextStyle(
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline),
                                                        ),
                                                      )))))),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _history.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                       
                                    return foodCard(_history[index], index);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Expanded(
                          child: Column(
                            children: [
                              Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0,
                                          right: 8.0,
                                          top: 2.5,
                                          bottom: 2.5),
                                      child:  Card(
                                              elevation: 4,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  height: 60,
                                                  child: const Padding(
                                                      padding:
                                                          EdgeInsets.only(
                                                              left: 8.0,
                                                              right: 8.0,
                                                              top: 2.5,
                                                              bottom: 2.5),
                                                      child: Center(
                                                        child: Text(
                                                              "You haven't upload any images, take one!",
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              
                                                    ),
                                                        ),
                                                      ))))),
                              const Expanded(
                                child:
                                    Center(child: Text('No history available')),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                }
              })
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          fromCamera();
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
