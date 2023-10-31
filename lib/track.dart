import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TrackScreen extends StatefulWidget {
  @override
  _TrackState createState() => _TrackState();
}

class _TrackState extends State<TrackScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _date;
  int? _totalCalories;
  int? _totalProtein;
  List<Map<String, dynamic>> _meals = [];
  bool _isPreset = false;
  int? calorieGoal;
  int? proteinGoal;

  @override
  void initState() {
    super.initState();
    _date = DateFormat('MM-dd-yy').format(DateTime.now());
    _getData();
  }

  TextEditingController _foodNameController = TextEditingController();
  TextEditingController _caloriesController = TextEditingController();
  TextEditingController _proteinController = TextEditingController();

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
                      controller: _foodNameController,
                      decoration: InputDecoration(hintText: 'Food Name'),
                    ),
                    TextField(
                      controller: _caloriesController,
                      decoration: InputDecoration(hintText: 'Calories'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _proteinController,
                      decoration: InputDecoration(hintText: 'Protein (g)'),
                      keyboardType: TextInputType.number,
                    ),
                    CheckboxListTile(
                      title: Text("Preset"),
                      value: _isPreset,
                      onChanged: (value) {
                        setState(() {
                          _isPreset = value!;
                        });
                      },
                    ),
                    // Add from presets option
                    ExpansionTile(
                      title: Text('Add from Presets'),
                      children: [
                        FutureBuilder<DocumentSnapshot>(
                          future: _firestore
                              .collection('userDetails')
                              .doc('pYh2aKK8NKXPOeWKBm2W')
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              if (snapshot.hasData && snapshot.data!.exists) {
                                Map<String, dynamic> presets = snapshot.data!
                                    .get('presets') as Map<String, dynamic>;
                                return Column(
                                  children: presets.entries.map((entry) {
                                    return Dismissible(
                                      key: Key(entry.key),
                                      onDismissed: (direction) {
                                        // Remove the preset here
                                      },
                                      child: ListTile(
                                        title: Text(entry.key),
                                        onTap: () {
                                          // Set values using the preset and close the bottom sheet
                                          _foodNameController.text = entry.key;
                                          _caloriesController.text = entry
                                              .value['calories']
                                              .toString();
                                          _proteinController.text =
                                              entry.value['protein'].toString();
                                          // Navigator.of(context).pop();
                                        },
                                      ),
                                    );
                                  }).toList(),
                                );
                              }
                            }
                            return CircularProgressIndicator(); // Show loading while fetching presets
                          },
                        ),
                      ],
                    ),
                    ElevatedButton(
                      child: Text('Add'),
                      onPressed: () async {
                        var mealName = _foodNameController.text;
                        var calories =
                            int.tryParse(_caloriesController.text) ?? 0;
                        var protein =
                            int.tryParse(_proteinController.text) ?? 0;

                        if (_isPreset) {
                          await _firestore
                              .collection('userDetails')
                              .doc('pYh2aKK8NKXPOeWKBm2W')
                              .set({
                            'presets': {
                              mealName: {
                                'calories': calories,
                                'protein': protein
                              }
                            }
                          }, SetOptions(merge: true));
                          await _firestore
                              .collection('userDetails')
                              .doc('pYh2aKK8NKXPOeWKBm2W')
                              .set({
                            'entries': {
                              _date: {
                                mealName: {
                                  'calories': calories,
                                  'protein': protein,
                                  'preset': _isPreset
                                }
                              }
                            }
                          }, SetOptions(merge: true));
                        } else {
                          await _firestore
                              .collection('userDetails')
                              .doc('pYh2aKK8NKXPOeWKBm2W')
                              .set({
                            'entries': {
                              _date: {
                                mealName: {
                                  'calories': calories,
                                  'protein': protein,
                                  'preset': _isPreset
                                }
                              }
                            }
                          }, SetOptions(merge: true));
                        }

                        _getData();
                        Navigator.of(context).pop();
                        _foodNameController.clear();
                        _caloriesController.clear();
                        _proteinController.clear();
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
      var entries = doc['entries'];
      calorieGoal = doc['calorieGoal'] as int;
      proteinGoal = doc['proteinGoal'] as int;
      if (entries.containsKey(_date)) {
        var mealsData = entries[_date];
        _totalCalories = 0;
        _totalProtein = 0;
        _meals.clear();
        mealsData.forEach((mealName, mealData) {
          _totalCalories =
              (_totalCalories ?? 0) + ((mealData['calories'] as int?) ?? 0);
          _totalProtein =
              (_totalProtein ?? 0) + ((mealData['protein'] as int?) ?? 0);

          _meals.add({
            'name': mealName,
            'calories': mealData['calories'],
            'protein': mealData['protein']
          });
        });
      } else {
        _totalCalories = 0;
        _totalProtein = 0;
        _meals.clear();
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
            Text(
              _date,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.only(top: 8, bottom: 8, left: 4, right: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _buildStatCard(
                    'Calories', _totalCalories ?? 0, calorieGoal ?? 0),
                _buildStatCard('Protein', _totalProtein ?? 0, proteinGoal ?? 0),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Meals',
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold)),
          ),
          Expanded(
              child: ListView.builder(
            itemCount: _meals.length,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 0.5, color: Colors.grey),
                    bottom: BorderSide(width: 0.5, color: Colors.grey),
                  ),
                ),
                child: ListTile(
                  title: Text(_meals[index]['name']),
                  subtitle: Text(
                      '${_meals[index]['calories']} kcal, ${_meals[index]['protein']} g protein'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      String path = 'entries.$_date.${_meals[index]['name']}';
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
