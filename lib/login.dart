import 'package:flutter/material.dart';
import 'package:simpletracker/home.dart';
import 'auth_service.dart';
import 'package:simpletracker/register.dart';
import 'package:simpletracker/colorScheme.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello!',
              style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 1),
            Text(
              'Login',
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
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: TextStyle(
                  color:
                      AppColors.formField, // Default color for non-active state
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: AppColors
                          .formField), // Default border color for non-active state
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: AppColors
                          .formField), // Default border color for non-active state
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: AppColors.highlight,
                      width: 1.0), // Border color for active state
                ),
              ),
            ),
            SizedBox(height: 20.0),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(
                  color:
                      Color(0xFFAEB5BC), // Default color for non-active state
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color(
                          0xFFAEB5BC)), // Default border color for non-active state
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color(
                          0xFFAEB5BC)), // Default border color for non-active state
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color(0xFF0969FF),
                      width: 1.0), // Border color for active state
                ),
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () async {
                var user = await _authService.signInWithEmailAndPassword(
                  _emailController.text,
                  _passwordController.text,
                );
                if (user != null) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              child: Text(
                'Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                primary: Color(0xFF0969FF),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                elevation: 0,
              ),
            ),
            SizedBox(
              height: 16,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: Text(
                'Register',
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
}
