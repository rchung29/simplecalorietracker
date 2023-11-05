import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WorkoutScreen extends StatefulWidget {
  @override
  _WorkoutState createState() => _WorkoutState();
}

final _formKey = GlobalKey<FormState>();
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class _WorkoutState extends State<WorkoutScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _date;

  List<Map<String, dynamic>> _exercises = [];

  @override
  void initState() async {
    super.initState();
    _date = DateFormat('MM-dd-yy').format(DateTime.now());
    setState(() {
      _isLoading = true; // Start loading
    });
    await _getData();
    setState(() {
      _isLoading = false; // Start loading
    });
  }

  TextEditingController _exerciseNameController = TextEditingController();

  List<Map<String, dynamic>> _allLoggedDays = [];

  void _showAllLoggedDays() async {
    setState(() {
      _isLoading2 = true; // Start loading
    });
    // Reference to the workoutEntries for the user
    CollectionReference workoutEntriesRef = _firestore
        .collection('userDetails')
        .doc(_auth.currentUser?.uid)
        .collection('workoutEntries');

    // Fetch all dates (documents) under workoutEntries
    QuerySnapshot workoutEntriesSnapshot =
        await workoutEntriesRef.orderBy('date', descending: true).get();

    _allLoggedDays.clear();

    for (QueryDocumentSnapshot dateDoc in workoutEntriesSnapshot.docs) {
      String date = dateDoc.id;

      // Fetch exercises for the specific date
      QuerySnapshot exercisesSnapshot = await workoutEntriesRef
          .doc(date)
          .collection('exercises')
          .orderBy('timestamp')
          .get();
      Map<String, dynamic> exercises = {};
      if (exercisesSnapshot.docs.isNotEmpty) {
        Map<String, dynamic> exercises = {};
        for (QueryDocumentSnapshot exerciseDoc in exercisesSnapshot.docs) {
          exercises[exerciseDoc.id] = exerciseDoc.data();
        }

        _allLoggedDays.add({'date': date, 'exercises': exercises});
      }
    }
    setState(() {
      _isLoading2 = false; // Start loading
    });

    showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      context: context,
      isScrollControlled:
          true, // This allows the bottom sheet to be full height
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          child: DraggableScrollableSheet(
            expand: false,
            builder: (_, controller) {
              return Container(
                padding: EdgeInsets.only(
                    top: 16), // Give some space from the top edge
                child: ListView.builder(
                  controller: controller, // Use the provided ScrollController
                  itemCount: _allLoggedDays.length,
                  itemBuilder: (BuildContext context, int index) {
                    String date = _allLoggedDays[index]['date'];
                    Map<String, dynamic> exercises =
                        _allLoggedDays[index]['exercises'];

                    List<Widget> exerciseWidgets = [];
                    exercises.forEach((exerciseId, exerciseData) {
                      exerciseWidgets.add(
                        Text(exerciseData['name'],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      );

                      Map<String, dynamic> sets = exerciseData['sets'];
                      sets.forEach((setId, setData) {
                        exerciseWidgets.add(
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 2.0, horizontal: 8.0),
                            child: Text(
                                'Set $setId: ${setData['weight']} lbs x ${setData['reps']}'),
                          ),
                        );
                      });
                    });

                    return ListTile(
                      title: Text(DateFormat('EEEE - MM-dd-yy')
                          .format(DateFormat('MM-dd-yy').parse(date))),
                      subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: exerciseWidgets),
                    );
                  },
                ),
              );
            },
            initialChildSize: 0.9, // This is half the height of the screen
            minChildSize: 0.5, // You can adjust this as needed
            maxChildSize: 0.9, // You can adjust this as needed
          ),
        );
      },
    );
  }

  void _showEditBottomSheet(Map<String, dynamic> exerciseList, String docId) {
    var exercise = Map<String, dynamic>.from(exerciseList);
    List<TextEditingController> repsTECs = [TextEditingController()];
    List<TextEditingController> weightTECs = [TextEditingController()];

    // Create a new list of controllers for each set
    List<Map<String, dynamic>> sets = List.from(exercise['sets'].values);
    sets.forEach((set) {
      weightTECs.add(TextEditingController());
      repsTECs.add(TextEditingController());
    });

    _exerciseNameController.text = exercise['name'];
    showModalBottomSheet(
      shape: RoundedRectangleBorder(
        // Add this line
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20.0)), // Add this line
      ),
      context: _scaffoldKey.currentContext!,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return ClipRRect(
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20.0)), // Add this line

              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Padding(
                  padding: MediaQuery.of(context).viewInsets,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: _exerciseNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration:
                                InputDecoration(hintText: 'Exercise Name'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an exercise name';
                              }

                              return null; // Return null if the input is valid
                            },
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: sets.length,
                          itemBuilder: (context, index) {
                            var repsController = repsTECs[index];
                            var weightController = weightTECs[index];
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 5.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 5.0),
                                      child: TextField(
                                        controller: sets[index]['weight'] != 0
                                            ? (weightController
                                              ..text = sets[index]['weight']
                                                  .toString())
                                            : weightController,
                                        onChanged: (value) => sets[index]
                                                ['weight'] =
                                            int.tryParse(value) ?? 0,
                                        decoration:
                                            InputDecoration(hintText: 'Weight'),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 5.0),
                                      child: TextField(
                                        controller: sets[index]['reps'] != 0
                                            ? (repsController
                                              ..text = sets[index]['reps']
                                                  .toString())
                                            : repsController,
                                        onChanged: (value) => sets[index]
                                            ['reps'] = int.tryParse(value) ?? 0,
                                        decoration:
                                            InputDecoration(hintText: 'Reps'),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.remove_circle_outline),
                                    onPressed: () {
                                      setState(() {
                                        repsTECs[index].clear();
                                        repsTECs[index].dispose();
                                        weightTECs[index].clear();
                                        weightTECs[index].dispose();
                                        repsTECs.removeAt(index);
                                        weightTECs.removeAt(index);
                                        sets.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10.0),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              repsTECs.add(TextEditingController());
                              weightTECs.add(TextEditingController());
                              sets.add({
                                'weight': 0,
                                'reps': 0,
                              });
                            });
                          },
                          child: Text("Add Set +"),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10.0),
                        child: ElevatedButton(
                          child: Text('Save'),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              // Save logic...
                              await _firestore
                                  .collection('userDetails')
                                  .doc(_auth.currentUser?.uid)
                                  .collection('workoutEntries')
                                  .doc(_date)
                                  .collection('exercises')
                                  .doc(docId)
                                  .update({
                                'name': _exerciseNameController.text,
                                'sets': sets.asMap().map((index, set) =>
                                    MapEntry('${index + 1}', set)),
                              });

                              _getData();
                              Navigator.of(context).pop();
                              setState(() {
                                _exerciseNameController.clear();
                                for (var tec in repsTECs) {
                                  tec.clear();
                                  tec.dispose();
                                }
                                for (var tec in weightTECs) {
                                  tec.clear();
                                  tec.dispose();
                                }
                                repsTECs.clear();
                                weightTECs.clear();
                                sets.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddBottomSheet() {
    _exerciseNameController.clear();
    List<Map<String, dynamic>> sets = [
      {
        'weight': 0,
        'reps': 0,
      }
    ];
    List<TextEditingController> repsTECs = [TextEditingController()];
    List<TextEditingController> weightTECs = [TextEditingController()];

    showModalBottomSheet(
      shape: RoundedRectangleBorder(
        // Add this line
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20.0)), // Add this line
      ), // Add this line
      context: _scaffoldKey.currentContext!,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(20.0)), // Add this line

          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Padding(
                      padding: MediaQuery.of(context).viewInsets,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Form(
                              key: _formKey,
                              child: TextFormField(
                                controller: _exerciseNameController,
                                textCapitalization: TextCapitalization.words,
                                decoration:
                                    InputDecoration(hintText: 'Exercise Name'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an exercise name';
                                  }

                                  return null; // Return null if the input is valid
                                },
                              ),
                            ),
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 300.0),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: sets.length,
                              itemBuilder: (context, index) {
                                var repsController = repsTECs[index];
                                var weightController = weightTECs[index];
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.0, vertical: 5.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 5.0),
                                          child: TextField(
                                            controller: weightController,
                                            onChanged: (value) => sets[index]
                                                    ['weight'] =
                                                int.tryParse(value) ?? 0,
                                            decoration: InputDecoration(
                                                hintText: 'Weight'),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 5.0),
                                          child: TextField(
                                            controller: repsController,
                                            onChanged: (value) => sets[index]
                                                    ['reps'] =
                                                int.tryParse(value) ?? 0,
                                            decoration: InputDecoration(
                                                hintText: 'Reps'),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.remove_circle_outline),
                                        onPressed: () {
                                          setState(() {
                                            repsTECs[index].clear();
                                            repsTECs[index].dispose();
                                            weightTECs[index].clear();
                                            weightTECs[index].dispose();
                                            repsTECs.removeAt(index);
                                            weightTECs.removeAt(index);
                                            sets.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(10.0),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  repsTECs.add(TextEditingController());
                                  weightTECs.add(TextEditingController());
                                  sets.add({
                                    'weight': 0,
                                    'reps': 0,
                                  });
                                });
                              },
                              child: Text("Add Set +"),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(10.0),
                            child: ElevatedButton(
                              child: Text('Save'),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  String exerciseName =
                                      _exerciseNameController.text;

                                  // Save logic...
                                  DocumentReference exerciseRef = _firestore
                                      .collection('userDetails')
                                      .doc(_auth.currentUser?.uid)
                                      .collection('workoutEntries')
                                      .doc(_date)
                                      .collection('exercises')
                                      .doc();

                                  await _firestore
                                      .collection('userDetails')
                                      .doc(_auth.currentUser?.uid)
                                      .collection('workoutEntries')
                                      .doc(_date)
                                      .set({'date': _date});

                                  await exerciseRef.set({
                                    'name': exerciseName,
                                    'sets': sets.asMap().map((index, set) =>
                                        MapEntry('${index + 1}', set)),
                                    'timestamp': FieldValue.serverTimestamp()
                                  });

                                  _getData();
                                  Navigator.of(context).pop();
                                  setState(() {
                                    _exerciseNameController.clear();
                                    for (var tec in repsTECs) {
                                      tec.clear();
                                      tec.dispose();
                                    }
                                    for (var tec in weightTECs) {
                                      tec.clear();
                                      tec.dispose();
                                    }
                                    repsTECs.clear();
                                    weightTECs.clear();
                                    sets.clear();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  _getData() async {
    if (_auth.currentUser != null) {
      // Reference to the specific date under workoutEntries for the user
      CollectionReference exercisesRef = _firestore
          .collection('userDetails')
          .doc(_auth.currentUser?.uid)
          .collection('workoutEntries')
          .doc(_date)
          .collection('exercises');

      // Fetch all exercises for that date
      QuerySnapshot exercisesSnapshot =
          await exercisesRef.orderBy('timestamp').get();

      _exercises.clear(); // Rename this to _workouts or something more suitable

      // Iterate over each exercise document and add to _exercises
      for (QueryDocumentSnapshot exerciseDoc in exercisesSnapshot.docs) {
        Map<String, dynamic> exerciseData =
            exerciseDoc.data() as Map<String, dynamic>;
        _exercises.add({
          'id': exerciseDoc.id,
          'name': exerciseData['name'],
          'sets': exerciseData['sets'],
        });
      }

      setState(() {});
    }
  }

  Future<void> _loadAndSavePreviousWorkout(String selectedDate) async {
    setState(() {
      _isLoading = true; // Start loading
    });
    // Assuming selectedDate is in 'MM-dd-yy' format
    // Fetch the workout for the selected date
    DocumentSnapshot workoutSnapshot = await _firestore
        .collection('userDetails')
        .doc(_auth.currentUser?.uid)
        .collection('workoutEntries')
        .doc(selectedDate)
        .get();

    if (workoutSnapshot.exists) {
      // Fetch exercises for the specific date
      QuerySnapshot exercisesSnapshot = await _firestore
          .collection('userDetails')
          .doc(_auth.currentUser?.uid)
          .collection('workoutEntries')
          .doc(selectedDate)
          .collection('exercises')
          .orderBy('timestamp')
          .get();

      List<Map<String, dynamic>> loadedExercises = [];
      for (var exerciseDoc in exercisesSnapshot.docs) {
        loadedExercises.add(exerciseDoc.data() as Map<String, dynamic>);
      }

      setState(() {
        _exercises = loadedExercises;
        _isLoading = false;
      });

      ;
      DocumentReference newDateEntry = _firestore
          .collection('userDetails')
          .doc(_auth.currentUser?.uid)
          .collection('workoutEntries')
          .doc(_date);

      await newDateEntry.set({
        'date': _date,
      });

      for (var exercise in loadedExercises) {
        // For each exercise, create a new document in the exercises sub-collection
        await newDateEntry.collection('exercises').add({
          'name': exercise['name'],
          'sets': exercise['sets'],
          'timestamp':
              FieldValue.serverTimestamp() // Optionally add a timestamp
        });
      }

      print("Workout for $selectedDate loaded and saved under $_date");
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Center(child: Text("No workout exists for the selected date")),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating, // This makes it floating
        ),
      );
    }
  }

  bool _isLoading = false;
  bool _isLoading2 = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
          _isLoading2
              ? Center(child: CircularProgressIndicator())
              : GestureDetector(
                  onTap: _showAllLoggedDays,
                  child: Icon(
                    size: 30,
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
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : _exercises.isEmpty
                      ? Container(
                          height: MediaQuery.of(context).size.height,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Center(
                                child: ElevatedButton(
                                    onPressed: () async {
                                      DateTime? pickedDate =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime.now(),
                                      );

                                      if (pickedDate != null) {
                                        String formattedDate =
                                            DateFormat('MM-dd-yy')
                                                .format(pickedDate);
                                        await _loadAndSavePreviousWorkout(
                                            formattedDate);
                                        // If you just want to load and not save, you can call the _loadPreviousWorkout method instead
                                      }
                                    },
                                    child: Text("Load Previous Workout +")),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _exercises.length + 1,
                          itemBuilder: (BuildContext context, int index) {
                            if (index == _exercises.length) {
                              // Return an empty container for extra space
                              return SizedBox(
                                  height: 100); // Adjust the height as needed
                            }
                            return Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                      width: 0.5, color: Colors.grey),
                                  bottom: BorderSide(
                                      width: 0.5, color: Colors.grey),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: ListTile(
                                  onTap: () => _showEditBottomSheet(
                                      _exercises[index],
                                      _exercises[index]['id']),

                                  title: Text(_exercises[index]['name'] ??
                                      ""), // Rename _exercises to _workouts or a similar name
                                  subtitle: Text(_exercises[index]['sets']
                                          .entries
                                          .map((set) =>
                                              'Set ${set.key}: ${set.value['weight']} lbs x ${set.value['reps']}')
                                          .join('\n') +
                                      '\n'),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () async {
                                      await _firestore
                                          .collection('userDetails')
                                          .doc(_auth.currentUser?.uid)
                                          .collection('workoutEntries')
                                          .doc(
                                              _date) // Assuming _date is the date document ID
                                          .collection('exercises')
                                          .doc(_exercises[index][
                                              'id']) // Assuming this is the document ID
                                          .delete();
                                      _getData();
                                    },
                                  ),
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
}
