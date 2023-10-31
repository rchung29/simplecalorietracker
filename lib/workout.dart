import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WorkoutScreen extends StatefulWidget {
  @override
  _WorkoutState createState() => _WorkoutState();
}

class _WorkoutState extends State<WorkoutScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _date;

  List<Map<String, dynamic>> _exercises = [];

  int? calorieGoal;
  int? proteinGoal;

  @override
  void initState() {
    super.initState();
    _date = DateFormat('MM-dd-yy').format(DateTime.now());
    _getData();
  }

  TextEditingController _exerciseNameController = TextEditingController();
  TextEditingController _weightController = TextEditingController();
  TextEditingController _repsController = TextEditingController();
  TextEditingController _setsController = TextEditingController();

  List<Map<String, dynamic>> _allLoggedDays = [];

  void _showAllLoggedDays() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('userDetails')
        .doc('pYh2aKK8NKXPOeWKBm2W')
        .get();
    Map<String, dynamic> workoutEntries =
        snapshot.data()?['workoutEntries'] ?? {};

    _allLoggedDays.clear();

    workoutEntries.forEach((date, exercises) {
      _allLoggedDays.add({'date': date, 'exercises': exercises});
    });

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height:
              MediaQuery.of(context).size.height * 0.8, // 80% of screen height
          child: ListView.builder(
            itemCount: _allLoggedDays.length,
            itemBuilder: (BuildContext context, int index) {
              String date = _allLoggedDays[index]['date'];
              Map<String, dynamic> exercises =
                  _allLoggedDays[index]['exercises'];
              return ListTile(
                title: Text(DateFormat('EEEE - MM-dd-yy')
                    .format(DateFormat('MM-dd-yy').parse(date))),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: exercises.keys.map((exercise) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        '$exercise (Weight: ${exercises[exercise]['weight']}, Reps: ${exercises[exercise]['reps']}, Sets: ${exercises[exercise]['sets']})',
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showAddBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller:
                          _exerciseNameController, // Rename this to _exerciseNameController
                      textCapitalization:
                          TextCapitalization.words, // Add this line
                      decoration: InputDecoration(hintText: 'Exercise Name'),
                    ),
                    TextField(
                      controller:
                          _weightController, // Rename this to _weightController
                      decoration: InputDecoration(hintText: 'Weight'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller:
                          _repsController, // Rename this to _repsController
                      decoration: InputDecoration(hintText: 'Reps'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      // New TextField for sets
                      controller: _setsController,
                      decoration: InputDecoration(hintText: 'Sets'),
                      keyboardType: TextInputType.number,
                    ),
                    ElevatedButton(
                      child: Text('Add'),
                      onPressed: () async {
                        var exerciseName = _exerciseNameController
                            .text; // Rename to _exerciseNameController
                        var weight = int.tryParse(_weightController.text) ??
                            0; // Rename to _weightController
                        var reps = int.tryParse(_repsController.text) ??
                            0; // Rename to _repsController
                        // Capture sets value too
                        var sets = int.tryParse(_setsController.text) ??
                            0; // Add this line

                        // Adjust Firestore saving logic to save these details instead of meal details
                        await _firestore
                            .collection('userDetails')
                            .doc('pYh2aKK8NKXPOeWKBm2W')
                            .set({
                          'workoutEntries': {
                            _date: {
                              exerciseName: {
                                'weight': weight,
                                'reps': reps,
                                'sets': sets,
                              }
                            }
                          }
                        }, SetOptions(merge: true));

                        _getData();
                        Navigator.of(context).pop();
                        // Clear all the controllers
                        _exerciseNameController.clear();
                        _weightController.clear();
                        _repsController.clear();
                        _setsController.clear();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  _getData() async {
    if (_auth.currentUser != null) {
      var doc = await _firestore
          .collection('userDetails')
          .doc('pYh2aKK8NKXPOeWKBm2W')
          .get();
      var workoutEntries = doc['workoutEntries'];

      if (workoutEntries.containsKey(_date)) {
        var exercisesData = workoutEntries[_date];
        _exercises
            .clear(); // Rename this to _workouts or something more suitable
        exercisesData.forEach((exerciseName, exerciseData) {
          _exercises.add({
            'name': exerciseName,
            'weight': exerciseData['weight'],
            'reps': exerciseData['reps'],
            'sets': exerciseData['sets']
          });
        });
      } else {
        _exercises
            .clear(); // Rename this to _workouts or something more suitable
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 80.0,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              // <-- Wrap IconButton with GestureDetector
              onTap: () {
                setState(() {
                  DateTime currentDate = DateFormat('MM-dd-yy').parse(_date);
                  _date = DateFormat('MM-dd-yy')
                      .format(currentDate.subtract(Duration(days: 1)));
                  _getData();
                });
              },
              child: Icon(
                Icons.arrow_left,
                color: Colors.black,
              ), // <-- Replace IconButton with Icon
            ), // <-- Optional, for some spacing between the icon and the date text
            GestureDetector(
              onTap: () async {
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateFormat('MM-dd-yy').parse(_date),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );

                if (selectedDate != null &&
                    selectedDate != DateFormat('MM-dd-yy').parse(_date)) {
                  setState(() {
                    _date = DateFormat('MM-dd-yy').format(selectedDate);
                    _getData();
                  });
                }
              },
              child: Text(
                _date,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
            GestureDetector(
              // <-- Wrap IconButton with GestureDetector
              onTap: () {
                setState(() {
                  DateTime currentDate = DateFormat('MM-dd-yy').parse(_date);
                  _date = DateFormat('MM-dd-yy')
                      .format(currentDate.add(Duration(days: 1)));
                  _getData();
                });
              },
              child: Icon(
                Icons.arrow_right,
                color: Colors.black,
              ), // <-- Replace IconButton with Icon
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _showAllLoggedDays,
            child: Icon(
              Icons.list, // Any suitable icon
              color: Colors.black,
            ),
          ),
          SizedBox(width: 20), // spacing to the right edge
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Workout',
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold)),
          ),
          Expanded(
              child: ListView.builder(
            itemCount: _exercises.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 0.5, color: Colors.grey),
                    bottom: BorderSide(width: 0.5, color: Colors.grey),
                  ),
                ),
                child: ListTile(
                  title: Text(_exercises[index][
                      'name']), // Rename _exercises to _workouts or a similar name
                  subtitle: Text(
                      'Weight: ${_exercises[index]['weight']} lbs, Reps: ${_exercises[index]['reps']}, Sets: ${_exercises[index]['sets']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      String path =
                          'workoutEntries.$_date.${_exercises[index]['name']}'; // Updated the path
                      await _firestore
                          .collection('userDetails')
                          .doc('pYh2aKK8NKXPOeWKBm2W')
                          .update({path: FieldValue.delete()});
                      _getData();
                    },
                  ),
                ),
              );
            },
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBottomSheet,
        child: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildStatCard(String title, int current, int goal) {
    double progress = goal == 0 ? 0.0 : (current / goal);
    progress = progress.isNaN || progress.isInfinite ? 0.0 : progress;
    progress = progress.clamp(0.0, 1.0); // Ensure it's within the valid range

    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey, width: 1.0),
          borderRadius: BorderRadius.circular(4.0),
        ),
        elevation: 0.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title,
                  style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              SizedBox(height: 4.0),
              Text(
                '$current/$goal',
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12.0),
              SizedBox(
                height: 20,
                width: double.infinity, // takes up the full width of the card
                child: LinearProgressIndicator(
                  value: progress,
                  valueColor: AlwaysStoppedAnimation(Colors.blueAccent),
                  backgroundColor: Colors.grey[300],
                ),
              ),
              SizedBox(height: 4.0),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
