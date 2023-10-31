import 'package:flutter/material.dart';
import 'package:simpletracker/home.dart'; // Your HomeScreen import
import 'auth_service.dart'; // Your AuthService import
import 'package:simpletracker/colorScheme.dart';
import 'package:simpletracker/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _calorieGoalController = TextEditingController();
  final _proteinGoalController = TextEditingController();
  final _nameController = TextEditingController();

  Future<void> saveUserDetails(String? userId, String? email, int? calorieGoal,
      int? proteinGoal, String? name) async {
    await FirebaseFirestore.instance.collection('userDetails').doc(userId).set({
      'email': email,
      'calorieGoal': calorieGoal,
      'proteinGoal': proteinGoal,
      'id': userId,
      'name': name,
      'entries': {},
      'presets': {},
      'workoutEntries': {},
      'height': 0,
      'weight': 0,
      'dateCreated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _register() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      var userCredential = await _authService.registerWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
      int calorieGoal = int.parse(_calorieGoalController.text);
      int proteinGoal = int.parse(_proteinGoalController.text);
      if (userCredential != null) {
        await saveUserDetails(userCredential.user!.uid, _emailController.text,
            calorieGoal, proteinGoal, _nameController.text);
        Navigator.pop(context); // Close the loading dialog
        await _showCheckDialog(); // Show check dialog
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (Route<dynamic> route) =>
              false, // This ensures all previous routes are removed
        );
      } else {
        Navigator.pop(context); // Close the loading dialog
      }
    } catch (e) {
      Navigator.pop(context); // Close the loading dialog
    }
  }

  Future<void> _showCheckDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 50, color: Colors.green),
              SizedBox(height: 20),
              Text('Registration Successful!'),
            ],
          ),
        ),
      ),
    );

    // Wait for 2 seconds
    await Future.delayed(Duration(seconds: 2));
    Navigator.pop(context); // Close the check dialog
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome',
              style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 1),
            Text(
              'Register',
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
        ),
        automaticallyImplyLeading:
            false, // Adjusted height to add padding at the bottom
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20.0),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20.0),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            TextFormField(
              controller: _calorieGoalController,
              decoration: InputDecoration(
                labelText: 'Calorie Goal',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20.0),
            TextFormField(
              controller: _proteinGoalController,
              decoration: InputDecoration(
                labelText: 'Protein Goal',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () async {
                _register();
              },
              child: Text(
                'Register',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFF0969FF),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                elevation: 0,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text(
                'Have an Account? Login',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0058E4)),
              ),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFFCDE2FF),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
