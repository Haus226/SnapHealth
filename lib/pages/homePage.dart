import 'package:SnapHealth/pages/profilePage.dart';
import 'package:flutter/material.dart';
import 'loginPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/utils.dart';
import 'diseasesPage.dart';
import 'package:google_fonts/google_fonts.dart';



class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final List<List<Disease>> disease = [brain, lung, eye, oral, breast, kidney, cervix, colon, lymphoma, leukemia];
  final List<String> category = ["Brain", "Lung", "Eye", "Oral", "Breast", "Kidney", "Cervix", "Colon", "Lymphoma", "Leukemia"];
  final List<bool> _isExpanded = [false, false, false, false, false, false, false, false, false, false];
  final List<ExpansionTileController> _controllers = [for (var idx = 0; idx < 10; idx++) ExpansionTileController()];
  final List<GlobalKey> _keys = [for (var idx = 0; idx < 10; idx++) GlobalKey()];
  int curSelect = -1;


  void _scrollToSelectedContent({required GlobalKey expansionTileKey}) {
    final keyContext = expansionTileKey.currentContext;
    if (keyContext != null) {
      Future.delayed(const Duration(milliseconds: 200)).then((value) {
        Scrollable.ensureVisible(keyContext,
            duration: const Duration(milliseconds: 500),
        );
      });
    }
  }

  Widget expansionTile({required String category, required List<Disease> diseases, required ExpansionTileController controller, required int id}) {
    return ExpansionTile(
          controller: controller,
          title: Text(category, style: GoogleFonts.lora(fontSize: 28, color: Colors.white),),
          onExpansionChanged: (bool expanded) {
            if (expanded) {
              if (curSelect == id) {
                _scrollToSelectedContent(expansionTileKey: _keys[id]);
              } else if (curSelect == -1) {
                curSelect = id;
                _scrollToSelectedContent(expansionTileKey: _keys[id]);
              } else if (curSelect != -1) {
                _controllers[curSelect].collapse();
                curSelect = id;
                _scrollToSelectedContent(expansionTileKey: _keys[id]);
              }
            }
            setState(() {
              _isExpanded[id] = expanded;
            });
          },
          trailing: _isExpanded[id] ? const Icon(Icons.arrow_drop_up, color: Colors.white,) : const Icon(Icons.arrow_drop_down, color: Colors.white,),
          children: [
            for (var d in diseases) 
              ListTile(
                title: Text(d.name, style: GoogleFonts.lora(fontSize: 20, color: Colors.white),),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white,),
                onTap: () {
                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => DiseasesPage(
                  //               id: d.id,
                  //               PageTitle: d.name,
                  //             )));
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
                        return DiseasesPage(id: d.id, PageTitle: d.name,);
                      },
                      transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  );
                },
              )
            
          ],
        
      
    );
  }

  Widget categoryCard(String category, List<Disease> diseases, int id) {
    return Card(
        key: _keys[id],
        color: Colors.pink[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
        
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
                  colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.srcOver,
          ),
                  image: AssetImage('assets/${category.toLowerCase()}_bg.jpg'), // Replace with your image path
                  fit: BoxFit.cover,
                ),
        ),
        child: Column(
            children: [
              InkWell(
                onTap: () {
                    // Needs to be a bit troublesome since when collapsing the _isExpanded will
                    // be changed by the setState in onExpansion of expansionTile
                    if (_isExpanded[id]) {
                      _controllers[id].collapse();
                      _isExpanded[id] = false;
                    }
                    else {
                      _controllers[id].expand();
                      _isExpanded[id] = true;
                      _scrollToSelectedContent(expansionTileKey: _keys[id]);

                    }

                },
                child: Container(height: 50,)
              ),
              Theme(
                data: ThemeData().copyWith(dividerColor: Colors.transparent),
                child: expansionTile(
                        id: id,
                        category: category,
                        diseases: diseases,
                        controller: _controllers[id],
                )
              ),
              InkWell(
                onTap: () {
                  if (_isExpanded[id]) {
                    _controllers[id].collapse();
                    _isExpanded[id] = false;
                  }
                  else {
                  _controllers[id].expand();
                  _isExpanded[id] = true;
                  _scrollToSelectedContent(expansionTileKey: _keys[id]);

                  }

                },
                child: Container(height: 50,) 
              )
            ]),

    )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(child: ListView(
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
                color: Colors.blue[300],
                image: DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage('assets/cover.jfif'))),
            child: Text(
              'Welcome to SnapHealth, \n${FirebaseAuth.instance.currentUser!.displayName}',
              style: const TextStyle(color: Colors.black54, fontSize: 25),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('Profile', style:TextStyle(fontSize: 20)),
            onTap: () {
              Navigator.pushNamed(context, "/profile");

              //  Animation
              // Navigator.push(
              //       context,
              //       PageRouteBuilder(
              //         pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
              //           return const ProfilePage();
              //         },
              //         transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {

              //           const begin = 0.0;
              //           const end = 1.0;
              //           const curve = Curves.easeInOut;
              //           var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

              //           return ScaleTransition(
              //           scale: animation.drive(tween),
              //           child: child,
              //           );
                        
              //         },
              //       ),
              //     );
            },
          ),

          // ListTile(
          //   leading: Icon(Icons.border_color),
          //   title: Text('Feedback'),
          //   onTap: () => {Navigator.of(context).pop()},
          // ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Log out', style:TextStyle(fontSize: 20)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You have been successfully logged out.', style: TextStyle(fontSize: 18),),
                  duration: Duration(seconds: 2), // Adjust the duration as needed
                ),
              );
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) =>
                        LoginPage()),
                  (route) => false);
            }
          ),
        ],
      ),),
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("", style: GoogleFonts.lora(fontSize: 28, color:Colors.white)), SizedBox(height:AppBar().preferredSize.height - 10, child: Image.asset('assets/snake.png', fit: BoxFit.contain)),]),
          backgroundColor: Colors.blue[300],
        ),
        body: 
        SingleChildScrollView(
          child:
          Column(
            children:[
                for (var idx = 0; idx < category.length; idx++)
                  categoryCard(category[idx], disease[idx], idx)
            ]
          ),),
        backgroundColor: Colors.blue[100],
                

    );

  }
}



  









