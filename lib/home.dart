import 'package:flutter/material.dart';

import 'package:simpletracker/track.dart';
// Import your additional screens

import 'package:simpletracker/profile.dart';

import 'package:simpletracker/workout.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _children = [
    // TrackScreen(),
    WorkoutScreen(),
    // ProfileScreen(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Daily Meal Tracker'),
      //   actions: <Widget>[
      //     IconButton(
      //       icon: Icon(Icons.exit_to_app),
      //       onPressed: () async {
      //         await FirebaseAuth.instance.signOut();
      //         Navigator.of(context).pushAndRemoveUntil(
      //           MaterialPageRoute(builder: (context) => AuthScreen()),
      //           (Route<dynamic> route) =>
      //               false, // Replace with your login screen
      //         );
      //       },
      //     ),
      //   ],
      // ),

      body: _children[
          _currentIndex], // Display the screen corresponding to the current index
      // bottomNavigationBar: BottomNavigationBar(
      //   onTap: onTabTapped,
      //   currentIndex: _currentIndex,
      //   items: [
      //     // BottomNavigationBarItem(
      //     //   icon: Icon(Icons.track_changes),
      //     //   label: 'Track',
      //     // ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.fitness_center),
      //       label: 'Workout',
      //     ),
      //     // BottomNavigationBarItem(
      //     //   icon: Icon(Icons.person),
      //     //   label: 'Profile',
      //     // ),
      //   ],
      // ),
    );
  }
}
