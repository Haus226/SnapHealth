import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BulletList extends StatelessWidget {
  BulletList(this.texts, {this.fontsize = 20.0});
  double fontsize;
  final List<String> texts;

  @override
  Widget build(BuildContext context) {
    var widgetList = <Widget>[];
    for (var text in texts) {
      widgetList.add(BulletListItem(text, fontSize: fontsize,));
      widgetList.add(const SizedBox(height: 1));
    }
    return Column(children: widgetList);
  }
}

class BulletListItem extends StatelessWidget {
  BulletListItem(this.text, {this.fontSize = 20.0});
  final double fontSize;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text("• ", style: GoogleFonts.lora(fontSize: fontSize)),
        Expanded(
          child: Text(text, style: GoogleFonts.lora(fontSize: fontSize)),
        ),
      ],
    );
  }
}