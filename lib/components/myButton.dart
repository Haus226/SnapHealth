import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';

class MyButton extends StatelessWidget {
  final Function()? onPressed;
  final String buttonText;
  const MyButton(
      {super.key, required this.onPressed, required this.buttonText});

  @override
  Widget build(BuildContext context) {
    
    return 
    SizedBox(height:55, width:275, child:
    ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color?>(
          HexColor("#44564a")
        ),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0), // Adjust the radius as needed
          ),
        )
      ),
      onPressed: onPressed,
  
      child: Text(
        buttonText,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
  ),
    );
  }
}