import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'components/utils.dart';
import 'components/bulletList.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;
  var collection = FirebaseFirestore.instance.collection("user");
  int availability = 0;
  int credits = 0;
  String _plan = "";
  int _index = 0;

  Widget Plan({required String title,  required List<String> subtitle, required double price}) {
    return Card(
      color: Colors.pink[50],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), 
            topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20))),
      child: listTile(
        title: title,
        subtitle: subtitle,
        price: price
      ));
  }



  Widget listTile({required String title, required List<String> subtitle, double? price}) {
    bool priceFlag = false;
    if (price != null) priceFlag = true;
    return Column(
      children:[
        
        ListTile(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), 
            topRight: Radius.circular(20),
          )),
          tileColor: Colors.blue[200],
          trailing: priceFlag ? Text("\$$price", style: GoogleFonts.lora(fontSize: 20),) : null,
          title: Text(
            title,
              style: GoogleFonts.lora(fontSize: 28)
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.15,
          child:
          ListView(
            physics: BouncingScrollPhysics(),
            children: [
              ListTile(title: BulletList(subtitle))
            ],  
        ))
    ]);
  }

  @override
  Widget build(BuildContext context) {

      collection.doc(user!.uid).get().then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        // print("Hi");
        var data = documentSnapshot.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            int p = data["plan"];
            availability = data["available"];
            credits = data["credits"];
            switch (p) {
              case 0:
                _plan = "Free";
                break;
              case 1:
                _plan = "Basic";
                break;
              case 2:
                _plan = "Caduceus";
                break;
              case 3:
                _plan = "Asclepius";
                break;
              default:
            }
          });
        }
      } else {
        print('Document does not exist');
      }
      }).catchError((error) {
        print('Error getting document: $error');
      });
    
    List<Widget> plan = [
      Plan(title: "Free", subtitle: ["Limited to 10 images per week", "Watch Ads to increase your credits if reach the limit"], price: 0),
      Plan(title: "Basic", subtitle: ["Monthly plan", "Limited to 100 images per week", "No Ads", "Watch Ads to increase your credits if reach the limit"], price: 1.99),
      Plan(title: "Caduceus", subtitle: ["Monthly plan", "1000 images per week", "No Ads", "Watch Ads to increase your credits if reach the limit"], price: 9.99),
      Plan(title: "Asclepius", subtitle: ["Annual plan", "25000 images per year", "No Ads", "Watch Ads to increase your credits if reach the limit"], price: 109.99)
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(user!.displayName!, style: GoogleFonts.lora(fontSize: 20),),
        backgroundColor: Colors.blue[300],  
      ),
      body: 
      Stack(

      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/profile-background.webp'), // Replace with your image path
            fit: BoxFit.fill
            ),
        ),),
        Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [

          
          Card(
            color:Colors.pink[50],
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), 
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20)
            )),
            child: 
              listTile(
                title: "Current Plan : $_plan",
                subtitle: ["Available : $availability", "Credits : $credits", "1 credit will be deducted for each prediction if out of availability"]
                )
          ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3, width: double.infinity,
              child: 
            PageView.builder(
              scrollDirection: Axis.horizontal,
                        itemCount: plan.length,
                        physics: const PageScrollPhysics(),
                        controller: PageController(viewportFraction: 1.0),
                        onPageChanged: (int index) => setState(() => _index = index),
                        itemBuilder: (_, i) {
                          return Transform.scale(
                            scale: i == _index ? 1 : 0.85,
                            child: plan[i]
                          );})
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                          const SizedBox(height: 20,),
                          buildIndicator(_index, 0),
                          const SizedBox(width: 5),
                          buildIndicator(_index, 1),
                          const SizedBox(width: 5),
                          buildIndicator(_index, 2),
                          const SizedBox(width: 5),
                          buildIndicator(_index, 3),

                        ],
              ),

          
      ]
          )
      ],
        
      
    ));
  }
}