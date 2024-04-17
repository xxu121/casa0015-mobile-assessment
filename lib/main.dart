import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:pretty_gauge/pretty_gauge.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math' show Random;


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: false),
      home: HomeScreen(), // Redirecting to a new HomeScreen widget that includes a bottom navigation bar
    );
  }
}

class HeartRateGauge extends StatefulWidget {
  final double currentHeartRate;
  final double averageBPM;

  HeartRateGauge({required this.currentHeartRate, required this.averageBPM});

  @override
  _HeartRateGaugeState createState() => _HeartRateGaugeState();
}

class _HeartRateGaugeState extends State<HeartRateGauge> {
  bool isExerciseMode = false;

  @override
  Widget build(BuildContext context) {
    List<GaugeSegment> segments = isExerciseMode
      ? [
          GaugeSegment('Super Low', 60, Colors.grey),   // 0-60
          GaugeSegment('Low', 60, Colors.green),       //60-120
          GaugeSegment('Medium', 70, Colors.orange),   //120-190
          GaugeSegment('High', 30, Colors.red),        //190-220
        ]
      : [
          GaugeSegment('Super Low', 30, Colors.grey),  //0-30
          GaugeSegment('Low', 60, Colors.green),       //30-90
          GaugeSegment('Medium', 70, Colors.orange),   //90-160
          GaugeSegment('High', 60, Colors.red),        //160-220
        ];
      String getRangeDescription() {
    if (isExerciseMode) {
      return 'Ranges: Super Low (0-60), Low (60-120), Medium (120-190), High (190-220)';
    } else {
      return 'Ranges: Super Low (0-30), Low (30-90), Medium (90-160), High (160-220)';
    }
  }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PrettyGauge(
          gaugeSize: 220,
          minValue: 0,
          maxValue: 220,
          currentValue: widget.currentHeartRate,
          segments: segments,
          needleColor: Colors.black,
          displayWidget: Text(
            '${widget.currentHeartRate.toStringAsFixed(2)} bpm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Average BPM: ${widget.averageBPM.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 16),
        ),

        
        SizedBox(height: 20),
        Text(
          getRangeDescription(),
          style: TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            setState(() {
              isExerciseMode = !isExerciseMode;
            });
          },
          child: Text(isExerciseMode ? 'Switch to Normal Mode' : 'Switch to Exercise Mode'),
        ),
      ],
    );
  }
}



// New HomeScreen widget
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // New state variable for bottom nav

  // Screens for each bottom navigation item
  final List<Widget> _widgetOptions = <Widget>[
    MyListView(),
    GraphScreen(), // Placeholder for graph screen
    SettingsScreen(), // Settings screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the index on tap
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Follow Your Heart')),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Heart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Graph',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
List<double> generateHourlyHeartRateData() {
  final random = Random();
  // Generates a list of 24 random heart rate values, one for each hour, as doubles.
  return List.generate(24, (index) => 60.0 + random.nextInt(40).toDouble());
}

class GraphScreen extends StatefulWidget {
  @override
  _GraphScreenState createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  List<double> heartRates = List.generate(24, (index) => 50 + index.toDouble());

  @override
  void initState() {
    super.initState();
    // Example: Update data over time
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          heartRates = List.generate(24, (index) => 50 + (index * (timer.tick % 50)).toDouble());
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: LineChart(
          mainData(),
        ),
      ),
    );
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(show: true),
      borderData: FlBorderData(show: true, border: Border.all(color: Colors.blue, width: 1)),
      minX: 0,
      maxX: heartRates.length.toDouble(),
      minY: 0,
      maxY: 220,
      lineBarsData: [
        LineChartBarData(
          spots: heartRates.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
          isCurved: true,
          color: Colors.red,
          barWidth: 5,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.3)),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _gender;
  int? _age;
  double? _weight;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: <Widget>[
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(),
            ),
            value: _gender,
            isExpanded: true,
            items: _genders.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _gender = newValue;
              });
            },
            validator: (value) => value == null ? 'Field required' : null,
          ),
          SizedBox(height: 20),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Age',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onSaved: (value) {
              _age = int.tryParse(value ?? '');
            },
            validator: (value) {
              if (value == null || int.tryParse(value) == null) return 'Enter a valid age';
              return null;
            },
          ),
          SizedBox(height: 20),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Weight (kg)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onSaved: (value) {
              _weight = double.tryParse(value ?? '');
            },
            validator: (value) {
              if (value == null || double.tryParse(value) == null) return 'Enter a valid weight';
              return null;
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
               
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Settings Saved'),
                    content: Text(
                        'Gender: $_gender\nAge: $_age\nWeight: $_weight'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              }
            },
            child: Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}

class MyListView extends StatefulWidget {
  @override
  ListViewState createState() => ListViewState();
}

class ListViewState extends State<MyListView>{
  late List<Widget> feeds;
  double currentHeartRate = 0.0;
  double averageBPM = 0.0;

  @override
  void initState() {
    super.initState();
    feeds = [];
    startMQTT();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        HeartRateGauge(currentHeartRate: currentHeartRate, averageBPM: averageBPM),
        ...feeds.map((feed) => ListTile(title: Text(feed.toString()))).toList(),
      ],
    );
  }
  void updateList(String message) {
  final heartRatePattern = RegExp(r"Heart Rate: (\d+\.\d+)");
  final averageBPMPattern = RegExp(r"Average BPM: (\d+)");

  final heartRateMatch = heartRatePattern.firstMatch(message);
  final averageBPMMatch = averageBPMPattern.firstMatch(message);

  setState(() {
    if (heartRateMatch != null) {
      currentHeartRate = double.parse(heartRateMatch.group(1)!);
      print("Updated Heart Rate: $currentHeartRate");  // Debugging output
    }
    if (averageBPMMatch != null) {
      averageBPM = double.parse(averageBPMMatch.group(1)!);
      print("Updated Average BPM: $averageBPM");  // Debugging output
    }
  });
}



  Future<void> startMQTT() async{
    final client = MqttServerClient('mqtt.cetools.org', 'student');
    client.port=1884;

    // Set the correct MQTT protocol for mosquito
    client.setProtocolV311();

    
    client.keepAlivePeriod = 30;

    final String username = 'student';
    final String password = 'ce2021-mqtt-forget-whale';

    // Connect the client, any errors here are communicated by raising of the appropriate exception.
    try {
    await client.connect(username, password);
  } catch (e) {
    print('Client exception - $e');
    client.disconnect();
    return;
  }

  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('Mosquitto client connected');
    client.subscribe('student/CASA0015/sensor/ucfnxxu/outTopic', MqttQos.atMostOnce);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      if (c != null) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final String messageString = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        updateList(messageString);
      }
    });
  } else {
    print('ERROR: Mosquitto client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
    client.disconnect();
  }
  }
}
