import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simpletracker/login.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController? calorieController;
  TextEditingController? proteinController;

  @override
  void initState() {
    super.initState();
    calorieController = TextEditingController();
    proteinController = TextEditingController();
  }

  @override
  void dispose() {
    calorieController?.dispose();
    proteinController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    DocumentReference userRef =
        _firestore.collection('userDetails').doc('pYh2aKK8NKXPOeWKBm2W');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
              color: Colors.black, fontSize: 36, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 80.0, // Adjusted height to add padding at the bottom
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

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${data['email']}'),
                    SizedBox(height: 20),
                    Text('Height: ${data['height']} inches'),
                    SizedBox(height: 20),
                    Text('Weight: ${data['weight']} lbs'),
                    SizedBox(height: 20),
                    TextField(
                      controller: calorieController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Calorie Goal',
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: proteinController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Protein Goal',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await userRef.update({
                          'calorieGoal':
                              int.tryParse(calorieController?.text ?? '0'),
                          'proteinGoal':
                              int.tryParse(proteinController?.text ?? '0'),
                        });
                      },
                      child: Text("Update Goals"),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blueAccent,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _auth.signOut();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => AuthScreen()),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: Text("Sign out"),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blueAccent,
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
}
