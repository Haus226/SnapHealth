import 'package:flutter/material.dart';
import 'loginPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'components/diseases.dart';
import 'diseasesPage.dart';
import 'package:google_fonts/google_fonts.dart';


// Done
List<Disease> brain = [
  Disease(name: "Alzheimer", id: 0, category: "Brain"),
  Disease(name: "Glioma", id: 1, category: "Brain"),
  Disease(name: "Meningioma", id: 2, category: "Brain"),
  Disease(name: "Pituitary", id: 3, category: "Brain")
];
// Done
List<Disease> lung = [
  Disease(name: "Lung Adenocarcinoma", id: 4, category: "Lung"),
  Disease(name: "Covid-19", id: 5, category: "Lung"),
  Disease(name: "Lung Benign Tissue", id: 6, category: "Lung"),
  Disease(name: "Lung Squamous Cell Carcinoma", id: 7, category: "Lung"),
  Disease(name: "Pneumonia", id: 8, category: "Lung"),
  Disease(name: "Tuberculosis", id: 9, category: "Lung"),
];
// Done
List<Disease> eye = [
  Disease(name: "Cataract", id: 10, category: "Eye"),
  Disease(name: "Choroidal Neovascularization", id: 11, category: "Eye"),
  Disease(name: "Glaucoma", id: 12, category: "Eye"),
  Disease(name: "Diabetic Macular Edema ", id: 13, category: "Eye"),
  Disease(name: "Diabetic Retinopathy", id: 14, category: "Eye"),
  Disease(name: "Drusen", id: 15, category: "Eye"),
];
// Done
List<Disease> oral = [
  Disease(name: "Oral Squamous Cell Carcinoma", id: 16, category: "Oral")
];
// Done
List<Disease> lymphoma = [
  Disease(name: "Chronic Lymphocytic Leukemia", id: 17, category: "Lymphoma"),
  Disease(name: "Follicular Lymphoma", id: 18, category: "Lymphoma"),
  Disease(name: "Mantle Cell Lymphoma", id: 19, category: "Lymphoma"),
];
// Done
List<Disease> colon = [
    Disease(name: "Colon Adenocarcinoma", id: 20, category: "Lymphoma"),
    Disease(name: "Colon Benign Tissue", id: 21, category: "Lymphoma"),
];
// Done
List<Disease> kidney = [
  Disease(name: "Kidney Cyst", id: 22, category: "Kidney"),
  Disease(name: "Kidney Stone", id: 23, category: "Kidney"),
  Disease(name: "Kidney Tumor", id: 24, category: "Kidney"),
];
// Done
List<Disease> cervix = [
  Disease(name: "Cervix Cancer", id: 25, category: "Cervix")
];
// Done
List<Disease> breast = [
  Disease(name: "Breast Benign", id: 26, category: "Breast"),
  Disease(name: "Breast Malignant", id: 27, category: "Breast"),
];
// Done
List<Disease> leukemia = [
  Disease(name: "Acute Lymphocytic Leukemia (ALL)", id: 28, category: "Leukemia")
];


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
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DiseasesPage(
                                id: d.id,
                                PageTitle: d.name,
                              )));
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
            child: Text(
              'Welcome to SnapHealth, \n${FirebaseAuth.instance.currentUser!.displayName}',
              style: TextStyle(color: Colors.black54, fontSize: 25),
            ),
            decoration: BoxDecoration(
                color: Colors.blue[300],
                image: DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage('assets/cover.jfif'))),
          ),
          ListTile(
            leading: Icon(Icons.verified_user),
            title: Text('Profile'),
            onTap: () {
              Navigator.pushNamed(context, "/profile");
            },
          ),

          // ListTile(
          //   leading: Icon(Icons.border_color),
          //   title: Text('Feedback'),
          //   onTap: () => {Navigator.of(context).pop()},
          // ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Logout'),
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
          // leading: GestureDetector(
          //   onTap: () { /* Write listener code here */ },
          //     child: const Icon(
          //       Icons.menu,  // add custom icons also
          //     ),
          // ),
        ),
        body: AnimatedContainer(
          duration: Duration(seconds: 2),

          curve: Curves.easeInOut,
          child:
        SingleChildScrollView(
          child:
          Column(
            children:[
                for (var idx = 0; idx < category.length; idx++)
                  categoryCard(category[idx], disease[idx], idx)
            ]
          ),),),
        backgroundColor: Colors.blue[100],
                

    );

  }
}



  









