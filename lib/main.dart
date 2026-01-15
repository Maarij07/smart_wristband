import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application for the Smart Wristband.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Wristband',
      theme: ThemeData(
        // This is the theme of your application.
        //
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF000000), // Black
          secondary: Color(0xFF2d2d2d), // Smokey Grey
          surface: Color(0xFF1a1a1a), // Smoke Black
          inverseSurface: Color(0xFF000000), // Black - replacing deprecated background
          onPrimary: Color(0xFFFFFFFF), // White text on primary
          onSecondary: Color(0xFFFFFFFF), // White text on secondary
          onSurface: Color(0xFFFFFFFF), // White text on surface
          onSurfaceVariant: Color(0xFFB3B3B3), // Light text for secondary content
          brightness: Brightness.dark,
        ),
      ),
      home: const MyHomePage(title: 'Smart Wristband Dashboard'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the dashboard page for the Smart Wristband app. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title; // Title for the Smart Wristband dashboard

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // Increment counter for Smart Wristband data point
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Smart Wristband Data Points:'),
            Text(
              '\$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            const Text('Health Metrics Dashboard', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Add Data Point', // Tooltip for Smart Wristband functionality
        child: const Icon(Icons.add),
      ),
    );
  }
}
