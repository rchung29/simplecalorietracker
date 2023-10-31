import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:simpletracker/colorScheme.dart';

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
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

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
                              .doc(_auth.currentUser!.uid)
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
                              .doc(_auth.currentUser!.uid)
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
                              .doc(_auth.currentUser!.uid)
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
                              .doc(_auth.currentUser!.uid)
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

  void _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate, // Show the currently selected date
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors
                .highlight, // The color for highlighted elements  // The color of the toggleable item when it's toggled on
            colorScheme: ThemeData.light().colorScheme.copyWith(
                  primary: AppColors
                      .highlight, // The color of the app's primary Material widgets
                ),
            buttonTheme: ButtonThemeData(
                textTheme:
                    ButtonTextTheme.primary), // Ensure contrast on buttons
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _date = DateFormat('MM-dd-yy').format(_selectedDate);
        _getData(); // Refresh data based on the new date
      });
    }
  }

  _getData() async {
    setState(() {
      _isLoading = true;
    });
    if (_auth.currentUser != null) {
      var doc = await _firestore
          .collection('userDetails')
          .doc(_auth.currentUser!.uid)
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
        setState(() {
          _isLoading = false;
        });
      } else {
        _totalCalories = 0;
        _totalProtein = 0;
        _meals.clear();
        setState(() {
          _isLoading = false;
        });
      }
      setState(() {});
    }
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
              _date.toString(),
              style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 1),
            Text(
              'Your Diary',
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                      top: 8, bottom: 8, left: 4, right: 4),
                  child: Column(
                    children: <Widget>[
                      _buildCalorieCard(
                          'Calories', _totalCalories ?? 0, calorieGoal ?? 0),
                      _buildProteinCard(
                          'Protein', _totalProtein ?? 0, proteinGoal ?? 0),
                    ],
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.all(8.0),
                //   child: Text('Meals',
                //       style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold)),
                // ),
                Expanded(
                    child: ListView.builder(
                  itemCount: _meals.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        // add some margin for spacing
                        decoration: BoxDecoration(
                            color: Colors.white, // grey background color
                            borderRadius:
                                BorderRadius.circular(5.0), // rounded corners
                            // border: Border(
                            //   top: BorderSide(width: 0.5, color: Colors.grey),
                            //   bottom: BorderSide(width: 0.5, color: Colors.grey),
                            // ),
                            border:
                                Border.all(color: Color(0xFFDFE2E6), width: 1)),
                        child: ListTile(
                          title: Text(_meals[index]['name']),
                          subtitle: Text(
                              '${_meals[index]['calories']} kcal, ${_meals[index]['protein']} g protein'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              String path =
                                  'entries.$_date.${_meals[index]['name']}';
                              await _firestore
                                  .collection('userDetails')
                                  .doc('pYh2aKK8NKXPOeWKBm2W')
                                  .update({path: FieldValue.delete()});
                              _getData();
                            },
                          ),
                        ),
                      ),
                    );
                  },
                )),
                GestureDetector(
                  onTap: () => _pickDate(
                      context), // Use the _pickDate function to open the date picker
                  child: Container(
                    width: double.infinity, // Make it a full-width button
                    color: AppColors
                        .buttonBG, // Added a light background color to make it visually distinct
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppColors.buttonText,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          DateFormat('MM-dd-yy').format(
                              _selectedDate), // Display the currently selected date
                          style: TextStyle(
                              fontSize: 16, color: AppColors.buttonText),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        // Enclose the FAB in a column
        mainAxisSize: MainAxisSize.min, // Make it as small as possible
        children: [
          FloatingActionButton(
            onPressed: _showAddBottomSheet,
            child: Icon(Icons.add),
            backgroundColor: AppColors.highlight,
          ),
          SizedBox(
              height:
                  60.0), // Give some space between the FAB and the date picking button
        ],
      ),
    );
  }

  Widget _buildCalorieCard(String title, int current, int goal) {
    double progress = goal == 0 ? 0.0 : (current / goal);
    progress = progress.isNaN || progress.isInfinite ? 0.0 : progress;
    progress = progress.clamp(0.0, 1.0); // Ensure it's within the valid range

    return Container(
      height: 130,
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFFDFE2E6), width: 1.0),
          borderRadius: BorderRadius.circular(5.0),
        ),
        elevation: 0.0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8.0,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.highlight),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ), // Add an arrow icon to indicate the direction
                    ],
                  ),
                  SizedBox(
                    width: 24,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.secondary),
                      ),
                      SizedBox(
                        height: 2,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$current/$goal',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 28,
                                color: AppColors.primary),
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          Text(
                            'kcal',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: AppColors.secondary),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
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
                    Icons.lunch_dining_rounded,
                    color: AppColors.buttonText,
                  ),
                ],
              )
              // Added an icon to the right
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProteinCard(String title, int current, int goal) {
    double progress = goal == 0 ? 0.0 : (current / goal);
    progress = progress.isNaN || progress.isInfinite ? 0.0 : progress;
    progress = progress.clamp(0.0, 1.0); // Ensure it's within the valid range

    return Container(
      height: 130,
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFFDFE2E6), width: 1.0),
          borderRadius: BorderRadius.circular(5.0),
        ),
        elevation: 0.0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8.0,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.highlight),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ), // Add an arrow icon to indicate the direction
                    ],
                  ),
                  SizedBox(
                    width: 24,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.secondary),
                      ),
                      SizedBox(
                        height: 2,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$current/$goal',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 28,
                                color: AppColors.primary),
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          Text(
                            'grams',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: AppColors.secondary),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
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
                    Icons.egg_rounded,
                    color: AppColors.buttonText,
                  ),
                ],
              )
              // Added an icon to the right
            ],
          ),
        ),
      ),
    );
  }
}
