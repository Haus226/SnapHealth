import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import '../components/myButton.dart';
import '../components/myTextField.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homePage.dart';
import '../components/utils.dart';
import 'package:email_validator/email_validator.dart';


class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  List<bool> _isObscure = [true, true];
  bool _isVisible = false;

  signUp(BuildContext context) async {
      int counter = 12;
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: emailController.text, password: passwordController.text);
        
        await userCredential.user!.sendEmailVerification().catchError((e) {print("An error occured while trying to send email verification : $e");});
        showMessage(context, "The verification email will be sent to your email after you close this dialog, this email is valid for 60 seconds");
        Timer.periodic(Duration(seconds: 5), (timer) async {
          counter--;
          print(counter);
          if (userCredential.user != null) {
            await userCredential.user!.reload();
            var user = FirebaseAuth.instance.currentUser;
              if (user!.emailVerified) {
                await user.updateDisplayName(nameController.text);
                await user.reload();
                CollectionReference userCollection = FirebaseFirestore.instance.collection("user");
                userCollection.doc(userCredential.user!.uid.toString()).set({
                "plan":0,
                "available":10,
                "credits":0
              });
                timer.cancel();
                showMessage(context, "Register and verify successfully !");
                Navigator.pushNamed(context, "/home");
              }
          }
          if (counter == 0) {
            timer.cancel();
            showMessage(context, "Verification failed, please register again.");
            userCredential.user!.delete();
            return;
          }
          }
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          showMessage(context, 'The password provided is too weak.');
          return;
        } else if (e.code == 'email-already-in-use') {
          showMessage(context, 'The account already exists for that email.');
          return;
        }
      } catch (e) {
        debugPrint(e.toString());
        return;
      }
    }


  void signUserIn() async {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: emailController.text, password: passwordController.text);

        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) => Home(), 
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
          ),(route) => false);
          
      } on FirebaseAuthException catch (e) {
        showMessage(context, e.code);
      }

    }
  

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // minimum: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: 
          ListView(
                      // shrinkWrap: true,
          reverse: true,
            children: [
              Stack(
                children:[
                  Container(width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height),
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.45,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/SnapHealth.png'),
                    fit: BoxFit.fill,
                    )
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                top: _isVisible ? 220 : 280,
                right: -10,
                left: -10,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  color: Colors.pink[50],
                  child: SizedBox(height: MediaQuery.of(context).size.height * 0.8, width: MediaQuery.of(context).size.width,),

                ),
              ),
              AnimatedPositioned(
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                top: _isVisible ? 250 : 350,
                right: -20,
                left: -20,
                child:
              Column(
              children:[
                _isVisible ? SizedBox(
                width:300,
                child: MyTextField(
                        controller: nameController,
                        obscureText: false,
                        hintText: "Haus226",
                        prefixIcon: const Icon(Icons.person),
                        )
                ) : const SizedBox.shrink(),
                _isVisible ? const SizedBox(height:20) : const SizedBox.shrink(),
                SizedBox(
                  width:300,
                  child: MyTextField(
                          controller: emailController,
                          obscureText: false,
                          hintText: "snaphealth@email.com",
                          prefixIcon: const Icon(Icons.email),
                          ),
                  ),
                const SizedBox(height:20),
                SizedBox(
                width:300,
                child: MyTextField(
                        controller: passwordController,
                        obscureText: _isObscure[0],
                        hintText: "**********",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 15),
                            child: IconButton(
                              icon: _isObscure[0] ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  _isObscure[0] = !_isObscure[0];
                                });
                              },
                            )
                        ),
                      ),
                ),
                const SizedBox(height:20),  
                !_isVisible ? MyButton(onPressed: signUserIn, buttonText: "Submit") : 
                SizedBox(
                  width:300,
                  child: MyTextField(
                          controller: confirmPasswordController,
                          obscureText: _isObscure[1],
                          hintText: "Confirm Your Password",
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 15),
                              child: IconButton(
                                icon: _isObscure[1] ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _isObscure[1] = !_isObscure[1];
                                  });
                                },
                              )
                          ),
                        ),
                        
                  ),
                const SizedBox(height:20),
                _isVisible ? MyButton(
                  onPressed: () {
                    if (emailController.text.isEmpty || passwordController.text.isEmpty || confirmPasswordController.text.isEmpty || nameController.text.isEmpty) {
                      showMessage(context, "Please fill in all the fields.");
                      return;
                    }
                    if (!EmailValidator.validate(emailController.text)) {
                      showMessage(context, "Please key in a valid email address");
                      return;
                    }
                    if (passwordController.text != confirmPasswordController.text) {
                      showMessage(context, "The passwords are different.");
                      return;
                    }
                    signUp(context);

                  },
                  buttonText: "Register") : const SizedBox.shrink(),
              
                !_isVisible ? Row(  
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: HexColor("#8d8d8d"),
                        )),
                    TextButton(
                      child: Text(
                        "Register",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: HexColor("#44564a"),
                          decoration: TextDecoration.underline
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isVisible = !_isVisible;
                          _isObscure[0] = true;
                          _isObscure[1] = true;
                          nameController.clear();
                          emailController.clear();
                          passwordController.clear();
                          confirmPasswordController.clear();
                        });
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //       builder: (context) => const RegisterPage()
                        //       )
                        //     );
                      }
                    ),
                  ]
                ) : Row(  
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: HexColor("#8d8d8d"),
                        )),
                    TextButton(
                      child: Text(
                        "Login",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: HexColor("#44564a"),
                          decoration: TextDecoration.underline
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isVisible = !_isVisible;
                          _isObscure[0] = true;
                          _isObscure[1] = true;
                          emailController.clear();
                          passwordController.clear();
                        });
                      }
                    ),
                  ]
                )

            ],
            ))
              
            ],
        ),]
             

    )));
  }
}
