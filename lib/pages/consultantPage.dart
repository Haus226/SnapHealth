import 'dart:developer';

import 'package:flutter/material.dart';
import "package:flutter_markdown/flutter_markdown.dart";
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const apiKey = 'AIzaSyAYQ8RgguGiAgRRjTWguR8OLzhNuV7vM7A';

Future<http.Response> RAG(String query) {
  return http.post(
    Uri.parse('http://10.0.2.2:7000/query'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'query': query,
    }),
  );
}

class ConsultantPage extends StatefulWidget {
  const ConsultantPage({
    super.key,
  });

  @override
  State<ConsultantPage> createState() => _ConsultantPageState();
}

class _ConsultantPageState extends State<ConsultantPage> {

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        initialIndex: 0,
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              title: const Text("Your AI Consultant"),
              centerTitle: true,
              bottom: const TabBar(
                tabs: [
                  Tab(text: "Text Only"),
                  Tab(text: "Text with Image"),
                ],
              ),
            ),
            body: const TabBarView(
              children: [TextOnly(), TextWithImage()],
            )));
  }
}

// ------------------------------ Text Only ------------------------------

class TextOnly extends StatefulWidget {
  const TextOnly({
    super.key,
  });

  @override
  State<TextOnly> createState() => _TextOnlyState();
}

class _TextOnlyState extends State<TextOnly> {
  bool loading = false;
  List textChat = [];
  List textWithImageChat = [];
  late final ChatSession _chat;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _controller = ScrollController();

  // Create Gemini Instance
  final _model= GenerativeModel(model: "gemini-1.5-flash",
    apiKey: apiKey,
  );

  @override
  void initState() {
    _chat = _model.startChat();
    super.initState();
  }
  // Text only input
  void fromText({required String query}) async {
    setState(() {
      loading = true;
      textChat.add({
        "role": "User",
        "text": query,
      });
      _textController.clear();
    });
    scrollToTheEnd();
    var reference = await RAG(query);
    log(reference.body);
    final response = await _chat.sendMessage(Content.text("""
      You are a medical expert which answer the question regarding medical from user
      Here is the query from the user ${query.toString()} and below is the reference content for you
      to reply more precisely, take a look:
      ${reference.body}
      Response in Markdown Syntax and remember to cite the source and page in the response."""
      ));
    setState(() {
        loading = false;
        textChat.add({
          "role": "Consultant",
          "text": response.text,
        });
      });
      scrollToTheEnd();
    
  }

  void scrollToTheEnd() {
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: 
        SafeArea(child: 
        Column(
      children: [
        Expanded(
          child: ListView.separated(
            separatorBuilder: (_, __) => const SizedBox(
                  height: 10,
                ),
            controller: _controller,
            itemCount: textChat.length,
            padding: const EdgeInsets.only(bottom: 20),
            itemBuilder: (context, index) {
              return ListTile(
                isThreeLine: true,
                leading: CircleAvatar(
                  child: Text(textChat[index]["role"].substring(0, 1)),
                ),
                title: MarkdownBody(data:textChat[index]["role"]),
                subtitle: MarkdownBody(data:textChat[index]["text"]),
              );
            },
          ),
        ),
        Container(
          alignment: Alignment.bottomRight,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: Colors.grey),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: "Type a message",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none),
                    fillColor: Colors.transparent,
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ),
              IconButton(
                icon: loading
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.send),
                onPressed: () {
                  fromText(query: _textController.text);
                },
              ),
            ],
          ),
        )
      ],
    )));
  }
}

// ------------------------------ Text with Image ------------------------------

class TextWithImage extends StatefulWidget {
  const TextWithImage({
    super.key,
  });

  @override
  State<TextWithImage> createState() => _TextWithImageState();
}

class _TextWithImageState extends State<TextWithImage> {

    var _model = GenerativeModel(
      model: "gemini-1.5-flash",
      apiKey: 'AIzaSyAYQ8RgguGiAgRRjTWguR8OLzhNuV7vM7A');
  late final ChatSession _chat;
  bool loading = false;
  late bool showThumbImages = false;
  late List<AssetEntityImageProvider> thumbImage = [];
  late List<AssetEntity> image = [];
  List textAndImageChat = [];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    _chat = _model.startChat();
    super.initState();
 }

  void aiResponse(String prompt) async {
    setState(() {
      loading = true;
      textAndImageChat.add({
        "role": "User",
        "text": prompt,
        "image": [...image],
      });
      _textController.clear();
      thumbImage.clear();
    });
    scrollToTheEnd();

    late final response;
    var reference = await RAG(prompt);
    log(reference.body);
    final p = TextPart(
      """
      Here is the query from the user ${prompt.toString()} and below is the reference content for you
      to reply more precisely, take a look:
      ${reference.body}
      Response in Markdown Syntax.""");
    if (image.isNotEmpty) {
      var imageParts = [];

      for (final img in image) {
        var imageData = await img.originBytes;
        imageParts.add(DataPart(img.mimeType!, imageData!));
      }
      response = await _model.generateContent([
        Content.multi([p, ...imageParts])
      ]);
    } else {
      var content = Content.text(prompt.toString());
      response = await _chat.sendMessage(content);
    }
    setState(() {
        loading = false;
        textAndImageChat.add({"role": "Consultant", "text": response.text, "image": []});
        image.clear();
      });
    
  }

  // Text only input


  void scrollToTheEnd() {
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }

  void fromGallery() async {
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
        context, pickerConfig: const AssetPickerConfig(
        requestType: RequestType.image));

    if (result != null) {
      setState(() {
        thumbImage.clear();
        image.clear();
        for (final i in result) {
          thumbImage.add(AssetEntityImageProvider(i, isOriginal: false));
          image.add(i);
          showThumbImages = true;
        }
      });
    }
  }

  void fromCamera() async {
    final AssetEntity? entity = await CameraPicker.pickFromCamera(context);
    if (entity != null) {
      setState(() {
        thumbImage.clear();
        image.clear();
        thumbImage.add(AssetEntityImageProvider(entity, isOriginal: false));
        image.add(entity);
        showThumbImages = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              separatorBuilder: (_, __) => const SizedBox(
                  height: 10,
                ),
              controller: _controller,
              itemCount: textAndImageChat.length,
              padding: const EdgeInsets.only(bottom: 20),
              
              itemBuilder: (context, index) {
                return ListTile(
                  isThreeLine: true,
                  leading: CircleAvatar(
                    child:
                        Text(textAndImageChat[index]["role"].substring(0, 1)),
                  ),
                  title: MarkdownBody(data:textAndImageChat[index]["role"], selectable: true,),
                  subtitle: MarkdownBody(data:textAndImageChat[index]["text"], selectable: true,),
trailing: !textAndImageChat[index]["image"].isEmpty
                      ? SizedBox(
                          width: 100,
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: textAndImageChat[index]["image"].length,
                            itemBuilder: (context, imageIndex) {
                              return 
                              GestureDetector(
                                onTap: () {
                                  showImageViewer(context, AssetEntityImageProvider(
                                  textAndImageChat[index]["image"][imageIndex]), doubleTapZoomable: true, swipeDismissible: true);
                                },
                               
                                  child: Image(image:AssetEntityImageProvider(
                                textAndImageChat[index]["image"][imageIndex]),
                              ),
                                
                                
                              );

                              
                            },
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
          SizedBox(
              height: thumbImage.isNotEmpty ? 60 : 0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: thumbImage.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(5),
                        height: 55,
                        width: 55,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: thumbImage[index],
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              thumbImage.removeAt(index);
                            });
                          },
                          child: const Icon(
                            Icons.cancel,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          Container(
            alignment: Alignment.bottomCenter,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: "Write a message",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none),
                      fillColor: Colors.transparent,
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () async {
                    fromCamera();
                  },
                ),
                IconButton(onPressed: () async {fromGallery();}, icon: const Icon(Icons.image)),
                IconButton(
                  icon: loading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send),
                  onPressed: () {
                    if (image.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Please select an image")));
                      return;
                    }
                    aiResponse(_textController.text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      )
    );
  }
}