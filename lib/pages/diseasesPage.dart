import 'package:SnapHealth/pages/explainPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/bulletList.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import "dart:io";
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/utils.dart';
import 'dart:convert';
import "dart:developer";

class DiseasesPage extends StatefulWidget {
  DiseasesPage({super.key, this.id = -1, this.PageTitle = "Error"});

  final int id;
  final String PageTitle;

  @override
  State<DiseasesPage> createState() => _DiseasesPageState();
}

class _DiseasesPageState extends State<DiseasesPage> {
  late File selectedImage;
  String prediction = "";
  bool _isLoading = false;
  List<List<String>> details = [[], [], []];
  List<GlobalKey> keys = [for (var idx = 0; idx < 3; idx++) GlobalKey()];
  List<String> acc = [];

  int _index = 0;
  final List<String> _models = [
    "DenseNet201",
    "InceptionV3",
    "VGG-19",
    "Xception",
  ];

  Widget listTile(
      {required String title,
      required List<String> subtitle,
      required int id}) {
    Icon? trailingWidget = (() {
      switch (id) {
        case 0:
          return const Icon(Icons.info_rounded);
        case 1:
          return const Icon(Icons.add_alert);
        case 2:
          return const Icon(Icons.medical_services);
        default:
          return null;
      }
    })();

    return Column(children: [
      ListTile(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          tileColor: Colors.blue[200],
          title: Text(title, style: GoogleFonts.lora(fontSize: 28)),
          trailing: trailingWidget),
      SizedBox(
          height: MediaQuery.of(context).size.height * 0.25,
          child: ListView(
            physics: BouncingScrollPhysics(),
            children: [
              ListTile(
                title: BulletList(subtitle),
              )
            ],
          ))
    ]);
  }

  // Widget choiceDialog(int disease_id) {
  //   List<String> t = acc[disease_id].split(" ");
  //   return SimpleDialog(
  //     title: Text("Choose all for ensemble model",
  //         style: GoogleFonts.lora(fontSize: 24)),
  //     children: [
  //       Column(
  //         children: [
  //           for (var idx = 0; idx < _selectedModels.length; idx++)
  //             StatefulBuilder(
  //                 builder: (BuildContext context, StateSetter setState) {
  //               return CheckboxListTile(
  //                   title: Text("${_models[idx]}-${t[idx]}",
  //                       style: GoogleFonts.lora(fontSize: 20)),
  //                   value: _selectedModels[idx],
  //                   onChanged: (value) {
  //                     setState(() {
  //                       _selectedModels[idx] = value!;
  //                     });
  //                   });
  //             })
  //         ],
  //       )
  //     ],
  //   );
  // }

  // Set the url to "http://10.0.2.2:port in Flask app/" if debug with emulator
  Future uploadImage(
      {String URL = "http://10.0.2.2:9000/", String method = ""}) async {
    // If debug with physical device set the url = "Wi-Fi ip address of the local host:port"
    // and also the host of the host and the port of the Flask app same as the url
    // Make sure the local host allow the device to connect thrpugh that port
    // Reference : https://stackoverflow.com/questions/51889837/cannot-connect-to-localhost-api-from-android-app?noredirect=1&lq=1
    // URL = "http://192.168.1.19:9000/";
    var image = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _isLoading = true;
        selectedImage = File(image.path);
      });
      // Test whether the server is running
      try {
        // ignore: unused_local_variable
        var testRequest = await http.get(Uri.parse("${URL}/test"), ).timeout(const Duration(seconds: 3));
      } catch (e) {
        setState(() {
          _isLoading = !_isLoading;
        });
        return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          )),
          content: Text("The server is not running, please try again later...", style:GoogleFonts.lora(fontSize: 20, color: Colors.black)),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.amber[300]!.withOpacity(0.9),
          ));
      }

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$URL/predict/${widget.id}"),
      );

      Map<String, String> headers = {"Content-type": "multipart/form-data", "Connection": "Keep-Alive",
      "Keep-Alive": "timeout=20, max=5"};
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
      request.fields["user"] = FirebaseAuth.instance.currentUser!.displayName!;
      request.headers.addAll(headers);
      print("Request: $request");

      try {
      //   // Wait for prediction which takes 15 - 25 seconds usually
      //   // The speed of prediction depends on hardware of the server
        var streamedResponse =
            await request.send().timeout(const Duration(seconds: 60));
        var response = await http.Response.fromStream(streamedResponse);
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print('Response: $jsonResponse');
      setState(() {
        _isLoading = false;
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        //     duration: const Duration(seconds: 5),
        //     shape: const RoundedRectangleBorder(
        //         borderRadius: BorderRadius.only(
        //             topLeft: Radius.circular(20),
        //             topRight: Radius.circular(20))),
        //     backgroundColor: Colors.pink[50]!.withOpacity(0.9),
        //     content: Column(children: [
        //       Row(
        //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //         children: [
        //           Column(
        //               crossAxisAlignment: CrossAxisAlignment.start,
        //               children: [
        //                 Text(
        //                   "Class",
        //                   style: GoogleFonts.lora(
        //                       fontSize: 22, color: Colors.black),
        //                 ),
        //                 for (var entry in jsonResponse.entries)
        //                   Text(
        //                     entry.key,
        //                     style: GoogleFonts.lora(
        //                         fontSize: 18, color: Colors.black),
        //                   )
        //               ]),
        //           Column(children: [
        //             Text(
        //               "Probability",
        //               style:
        //                   GoogleFonts.lora(fontSize: 22, color: Colors.black),
        //             ),
        //             Column(children: [
        //               for (var entry in jsonResponse.entries)
        //                 Text(
        //                   entry.value,
        //                   style: GoogleFonts.lora(
        //                       fontSize: 18, color: Colors.black),
        //                 )
        //             ])
        //           ]),
        //         ],
        //       ),
        //     ])));
      });
      // Navigator.pop(context);

      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExplainPage(arguments: jsonResponse),
          ));

        try {
          var uid = FirebaseAuth.instance.currentUser!.uid;
          var collection = FirebaseFirestore.instance.collection("user");
          if (method == "availability") {
            collection
                .doc(uid)
                .update({"available": FieldValue.increment(-1)}).then(
                    (value) => {print("Updated successfully")});
          } else {
            collection
                .doc(uid)
                .update({"credits": FieldValue.increment(-1)}).then(
                    (value) => {print("Updated successfully")});
          }
        } catch (e) {
          print("Error : $e");
        }
      } catch (e) {
        print(e);
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

  Widget diseaseCards(String disease_name, int type) {
    String title = "";

    switch (type) {
      case 0:
        {
          rootBundle
              .loadString(
                  "assets/description/${disease_name.toLowerCase()}_d.txt")
              .then((value) {
            setState(() {
              details[type] = value.split("\n");
            });
          });
          title = "Description";
          break;
        }
      case 1:
        {
          rootBundle
              .loadString(
                  "assets/description/${disease_name.toLowerCase()}_s.txt")
              .then((value) {
            setState(() {
              details[type] = value.split("\n");
            });
          });
          title = "Symptoms";
          break;
        }
      case 2:
        {
          rootBundle
              .loadString(
                  "assets/description/${disease_name.toLowerCase()}_t.txt")
              .then((value) {
            setState(() {
              details[type] = value.split("\n");
            });
          });
          title = "Treatments";
          break;
        }
    }

    return Card(
      color: Colors.pink[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: listTile(
        title: title,
        subtitle: details[type],
        id: type,
      ),
    );
  }

  Widget diseaseExImage(String disease_name) {
    List<String> special = [
      "alzheimer",
      "cervix cancer",
      "acute lymphocytic leukemia",
      "pneumonia"
    ];
    int idx = special.indexOf(disease_name.toLowerCase());
    if (idx != -1) {
      List<String> labels = [];
      switch (idx) {
        case 0:
          {
            labels = [
              "Non Demented",
              "Very Mild Demented",
              "Mild Demented",
              "Moderate Demented"
            ];
          }
        case 1:
          {
            labels = [
              "Dyskeratotic",
              "Koilocytotic",
              "Metaplastic",
              "Parabasal",
              "Superficial-intermediate"
            ];
          }
        case 2:
          {
            labels = [
              "Benign",
              "Early Pre-B",
              "Pre-B",
              "Pro-B",
            ];
          }
        case 3:
          {
            labels = ["Bacterial", "Viral"];
          }
        default:
      }
      return Card(
          color: Colors.pink[50],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(children: <Widget>[
            ListTile(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20))),
              tileColor: Colors.blue[200],
              title: Text('Example Images of $disease_name',
                  style: GoogleFonts.lora(fontSize: 22)),
              trailing: const Icon(Icons.sick),
            ),
            Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: labels.length,
                      itemBuilder: (context, index) {
                        var l = labels[index];
                        return Row(children: [
                          Column(children: [
                            Text(l,
                                style: GoogleFonts.lora(
                                    fontSize: 18, fontStyle: FontStyle.italic)),
                            Row(children: [
                              for (var idx = 1; idx < 4; idx++)
                                GestureDetector(
                                  onTap: () {
                                    showImageViewer(
                                        context,
                                        Image.asset(
                                                "assets/${disease_name.toLowerCase()}/${l.toLowerCase()}/${l.toLowerCase()} ($idx).jpg")
                                            .image,
                                        doubleTapZoomable: true,
                                        swipeDismissible: true);
                                  },
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.3,
                                    height: MediaQuery.of(context).size.width *
                                        0.35,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        image: DecorationImage(
                                            image: AssetImage(
                                                'assets/${disease_name.toLowerCase()}/${l.toLowerCase()}/${l.toLowerCase()} ($idx).jpg'),
                                            fit: BoxFit.fill)),
                                  ),
                                ),
                            ]),
                            const SizedBox(
                              height: 10,
                            )
                          ])
                        ]);
                        // ]
                        // )
                      }),
                ))
          ]));
    } else {
      return Card(
          color: Colors.pink[50],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: <Widget>[
              ListTile(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20))),
                tileColor: Colors.blue[200],
                title: Text('Example Images of $disease_name',
                    style: GoogleFonts.lora(fontSize: 22)),
                trailing: const Icon(Icons.sick),
              ),
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    for (var idx = 1; idx < 4; idx++)
                      GestureDetector(
                          onTap: () {
                            showImageViewer(
                                context,
                                Image.asset(
                                        'assets/${disease_name.toLowerCase()}/${disease_name.toLowerCase()} ($idx).jpg')
                                    .image,
                                swipeDismissible: false);
                          },
                          child: Container(
                              width: MediaQuery.of(context).size.width * 0.3,
                              height: MediaQuery.of(context).size.width * 0.35,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  image: DecorationImage(
                                      image: AssetImage(
                                          'assets/${disease_name.toLowerCase()}/${disease_name.toLowerCase()} ($idx).jpg'),
                                      fit: BoxFit.fill)),
                              child: Column(children: [])))
                  ],
                ),
              )
            ],
          ));
    }
  }

  Widget disease(String disease_name, int disease_id) {
    List<Widget> children = [
      diseaseCards(disease_name, 0),
      diseaseCards(disease_name, 1),
      diseaseCards(disease_name, 2),
    ];

    return Scaffold(
      appBar: AppBar(
          titleSpacing: -10,
          title: Text(widget.PageTitle, style: GoogleFonts.lora(fontSize: 20)),
          backgroundColor: Colors.blue[300],
          actions: <Widget>[
            if (_isLoading)
              SizedBox(
                height: AppBar().preferredSize.height,
                width: AppBar().preferredSize.height,
                child: Center(
                    child: CircularProgressIndicator(color: Colors.pink[50])),
              ),
          ]),
      body: Stack(children: [
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage(
                    'assets/profile-background.webp'), // Replace with your image path
                fit: BoxFit.fill),
          ),
        ),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20,
                ),
                buildIndicator(_index, 0),
                const SizedBox(width: 5),
                buildIndicator(_index, 1),
                const SizedBox(width: 5),
                buildIndicator(_index, 2),
              ],
            ),
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                width: double.infinity,
                child: PageView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: children.length,
                    physics: const PageScrollPhysics(),
                    controller: PageController(viewportFraction: 1.0),
                    onPageChanged: (int index) =>
                        setState(() => _index = index),
                    itemBuilder: (_, i) {
                      return Transform.scale(
                          scale: i == _index ? 1 : 0.85, child: children[i]);
                    })),
            diseaseExImage(disease_name),
          ],
        ),
      ]),
      // ]),

      backgroundColor: Colors.blue[100],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          var uid = FirebaseAuth.instance.currentUser!.uid;
          var collection = FirebaseFirestore.instance.collection("user");
          collection.doc(uid).get().then((DocumentSnapshot documentSnapshot) {
            if (documentSnapshot.exists) {
              var data = documentSnapshot.data() as Map<String, dynamic>;
              var availability = data['available'];
              var credits = data["credits"];
              print('Available: $availability');
              print("Credits : $credits");
              if (availability != 0) {
                uploadImage(method: "availability");
              } else {
                if (credits != 0) {
                  uploadImage();
                } else {
                  showMessage(context,
                      "You have reached the weekly limit and out of credits, please earn some credits by watching Ads");
                }
              }
            } else {
              print('Document does not exist');
            }
          }).catchError((error) {
            print('Error getting document: $error');
          });
        },
        tooltip: 'Upload a photo',
        backgroundColor: Colors.pink[50],
        child: Icon(
          Icons.add_a_photo,
          color: Colors.blue[300],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    rootBundle.loadString("assets/accuracy.txt").then((value) {
      setState(() {
        acc = value.split("\n");
      });
    });
    return disease(diseaseNames[widget.id], widget.id);
  }
}
