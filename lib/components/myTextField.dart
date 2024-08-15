import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:google_fonts/google_fonts.dart';


Widget MyTextField({
  required TextEditingController controller, 
  required bool obscureText,
  required String hintText,
  Icon? prefixIcon,
  Widget? suffixIcon,
  }) {
    return TextField(
              controller: controller,
              obscureText: obscureText,
              cursorColor: HexColor("#4f4f4f"),
              decoration: InputDecoration(
                hintText: hintText,
                fillColor: HexColor("#f0f3f1"),
                hintStyle: GoogleFonts.poppins(
                  fontSize: 15,
                  color: HexColor("#8d8d8d"),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: prefixIcon,
                prefixIconColor: HexColor("#4f4f4f"),
                suffixIcon: suffixIcon,
                suffixIconColor: HexColor("#4f4f4f"),
                filled: true,
              ),
            );
  }
