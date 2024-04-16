import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

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
    Text('Graph'), // Placeholder for graph screen
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
                // Save settings or use them as needed
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

  @override
  void initState() {
    super.initState();
    feeds = [];
    startMQTT();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: feeds.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: feeds[index],
        );
      },
    );
  }

  updateList(String s){
    setState(() {
      feeds.add(Text(s));
    });
  }

  Future<void> startMQTT() async{
    final client = MqttServerClient('mqtt.cetools.org', 'student');
    client.port=1884;

    // Set the correct MQTT protocol for mosquito
    client.setProtocolV311();

    // If you intend to use a keep alive you must set it here otherwise keep alive will be disabled.
    client.keepAlivePeriod = 30;

    final String username = 'student';
    final String password = 'ce2021-mqtt-forget-whale';

    // Connect the client, any errors here are communicated by raising of the appropriate exception.
    try {
      await client.connect(username, password);
    } catch (e) {
      print('client exception - $e');
      client.disconnect();
    }

    // Check we are connected
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Mosquitto client connected');
    } else {
      print(
          'ERROR Mosquitto client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
      client.disconnect();
    }

    // Ok, lets try a subscription or two, note these may change/cease to exist on the broker
    const topic = 'student/CASA0015/sensor/ucfnxxu/outTopic';
    client.subscribe(topic, MqttQos.atMostOnce);


    // The client has a change notifier object(see the Observable class) which we then listen to to get
    // notifications of published updates to each subscribed topic.
    client.updates!.listen( (List<MqttReceivedMessage<MqttMessage?>>? c) {
      final receivedMessage = c![0].payload as MqttPublishMessage;
      final messageString = MqttPublishPayload.bytesToStringAsString(receivedMessage.payload.message);

      /// The payload is a byte buffer, this will be specific to the topic
      print('Change notification:: topic is <${c[0].topic}>, payload is <-- $messageString -->');
      print('');

      updateList(messageString);
    } );

  }

}
