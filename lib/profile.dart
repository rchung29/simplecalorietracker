import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simpletracker/login.dart';
import 'package:simpletracker/colorScheme.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController? calorieController;
  TextEditingController? proteinController;
  TextEditingController? heightController;
  TextEditingController? weightController;

  @override
  void initState() {
    super.initState();
    calorieController = TextEditingController();
    proteinController = TextEditingController();
    heightController = TextEditingController();
    weightController = TextEditingController();
  }

  @override
  void dispose() {
    calorieController?.dispose();
    proteinController?.dispose();
    heightController?.dispose();
    weightController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    DocumentReference userRef =
        _firestore.collection('userDetails').doc(_auth.currentUser!.uid);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 1),
            Text(
              'Profile',
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 40,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 120.0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0), // here the desired height
          child: Divider(
            height: 1.0,
            color: Color(0xFFDFE2E6),
            thickness: 1, // color of the border
          ),
        ), // Adjusted height to add padding at the bottom
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: userRef.get(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            Map<String, dynamic>? data =
                snapshot.data?.data() as Map<String, dynamic>?;
            if (data != null) {
              calorieController?.text = data['calorieGoal'].toString();
              proteinController?.text = data['proteinGoal'].toString();
              heightController?.text = data['height'].toString();
              weightController?.text = data['weight'].toString();

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    profileItem(Icons.email, 'Email', data['email']),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: heightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Height',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Weight',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: calorieController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Calorie Goal',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: proteinController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Protein Goal',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          await userRef.update({
                            'calorieGoal':
                                int.tryParse(calorieController?.text ?? '0'),
                            'proteinGoal':
                                int.tryParse(proteinController?.text ?? '0'),
                            'height':
                                int.tryParse(heightController?.text ?? '0'),
                            'weight':
                                int.tryParse(weightController?.text ?? '0'),
                          });
                        },
                        child: Text(
                          'Update Profile',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: AppColors.highlight,
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 16),
                          elevation: 0,
                          minimumSize: Size(double.infinity,
                              50), // this will make it take full width
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          await _auth.signOut();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AuthScreen()),
                            (Route<dynamic> route) => false,
                          );
                        },
                        child: Text(
                          'Signout',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0058E4)),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: Color(0xFFCDE2FF),
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 16),
                          elevation: 0,
                          minimumSize: Size(double.infinity,
                              50), // this will make it take full width
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Center(child: Text("No data found!"));
            }
          } else if (snapshot.connectionState == ConnectionState.none) {
            return Text("Error fetching data.");
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget profileItem(IconData icon, String title, String value) {
    return Container(
      height: 80,
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFFDFE2E6), width: 1.0),
          borderRadius: BorderRadius.circular(5.0),
        ),
        elevation: 0.0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 50.0,
                    height: 50.0,
                    decoration: BoxDecoration(
                      color: AppColors.buttonBG,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(
                    icon,
                    color: AppColors.buttonText,
                  ),
                ],
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
